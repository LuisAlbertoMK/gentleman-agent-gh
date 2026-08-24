#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    Background monitor for async post-delegation checks.

.DESCRIPTION
    Launched fire-and-forget by post-delegation-check.ps1 -Async. Polls the
    repo every PollIntervalSec running check-subagent-output.ps1 +
    validate-write-scope.ps1, then writes the final result to
    {BaseRef}.async-result.json in RepoRoot when git status is stable
    (no new changes for 2 consecutive polls) or MaxWaitSec is reached.

    Progress is written to stderr so an orchestrator can capture it while
    stdout stays clean for the caller.

.PARAMETER BaseRef
    Git reference to diff against (default: HEAD). Also names the result file:
    {BaseRef}.async-result.json (path-hostile chars are sanitized).

.PARAMETER AllowedPaths
    Regex pattern(s) that modified files must match. Passed to validate-write-scope.
    If omitted, the write_scope check FAILS (fail-closed, v3 Perm-4).

.PARAMETER ExpectedFiles
    Filenames that SHOULD appear in the diff (passed to check-subagent-output).

.PARAMETER SubagentOutputFile
    Path to a file containing the subagent's text output. When provided (and the
    file exists), enables C4d 4-field contract validation via check-subagent-output;
    contract_valid/contract_detail are added to the result JSON.

.PARAMETER RepoRoot
    Repository root (default: parent of script dir). Result JSON is written here.

.PARAMETER PollIntervalSec
    Seconds between polls (default: 15).

.PARAMETER MaxWaitSec
    Hard deadline; result is written when reached even if not yet stable (default: 300).

.PARAMETER CompletionCallback
    Optional push callback script invoked after the final result is produced:
    & $CompletionCallback -ResultJson <json> -TaskId <TaskId>.
    When provided, the callback owns the result-file write for {TaskId}.async-result.json
    (invoke-callback.ps1) and the monitor skips its own file write unless -WriteResultFile
    is passed. Backward compatible: when omitted, file-based behavior is unchanged.

.PARAMETER TaskId
    Optional delegation task id. When provided, the monitor writes its PID to
    .learnings\async-monitor-{TaskId}.pid (for registry cancel) and removes it on exit.

.PARAMETER WriteResultFile
    Force the monitor to write the result file even when a -CompletionCallback is set
    (the callback would otherwise own the write). Default behavior without callback
    (file-based) always writes the result file.

.EXAMPLE
    scripts\monitor-subagent.ps1 -BaseRef HEAD -AllowedPaths "src/*" -RepoRoot "D:\repo"
    scripts\monitor-subagent.ps1 -BaseRef HEAD -AllowedPaths "scripts/*" -PollIntervalSec 1 -MaxWaitSec 10
#>
param(
    [string]$BaseRef        = "HEAD",
    [string[]]$AllowedPaths = @(),
    [string[]]$ExpectedFiles = @(),
    [string]$SubagentOutputFile = "",
    [string]$RepoRoot       = $(Split-Path -Parent $PSScriptRoot),
    [int]$PollIntervalSec   = 15,
    [int]$MaxWaitSec        = 300,
    [string]$CompletionCallback = "",
    [string]$TaskId             = "",
    [switch]$WriteResultFile,
    [switch]$DryRun,
    [switch]$Force
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- C9/JD fix: escape single quotes to prevent command injection ---
function ConvertTo-SqlLiteral {
    param([string]$Value)
    $Value.Replace("'", "''")
}

# --- C9/JD fix: wrap pwsh subprocess with timeout to prevent indefinite hang ---
function Invoke-SubprocessWithTimeout {
    param([string]$CommandLine, [int]$TimeoutSec)
    try {
        $psi = [System.Diagnostics.ProcessStartInfo]::new("pwsh", "-NoProfile -NoLogo -Command `"$CommandLine`"")
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute = $false
        $process = [System.Diagnostics.Process]::Start($psi)
        $completed = $process.WaitForExit($TimeoutSec * 1000)
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        if (-not $completed) {
            $process.Kill()
            return [PSCustomObject]@{ output = @(); exitCode = -1; timedOut = $true; stderr = @($stderr) }
        }
        $lines = @()
        if ($stdout) { $lines += $stdout -split [char]10 }
        if ($stderr) { $lines += $stderr -split [char]10 }
        return [PSCustomObject]@{ output = $lines; exitCode = $process.ExitCode; timedOut = $false; stderr = @() }
    } catch {
        return [PSCustomObject]@{ output = @(); exitCode = -1; timedOut = $false; stderr = @($_ | Out-String) }
    }
}

# --- Result file: {BaseRef}.async-result.json (sanitize path-hostile chars) ---
$fileSafeBase = $BaseRef -replace '[/\\:*?"<>|]', '_'
$resultFile = Join-Path $RepoRoot ($fileSafeBase + '.async-result.json')

# --- One poll: run both dependency checks, return snapshot for stability compare ---
function Get-CheckSnapshot {
    $checks = @()
    $passed = $true

    $contractRan = $false; $contractValid = $true; $contractDetail = ""

    # 1. Empty-output detection (mirrors post-delegation-check.ps1 sync path)
    $csoScript = Join-Path $RepoRoot 'scripts\check-subagent-output.ps1'
    if (-not (Test-Path $csoScript)) { $csoScript = Join-Path $PSScriptRoot 'check-subagent-output.ps1' }
    if (Test-Path $csoScript) {
        $escapedBase = ConvertTo-SqlLiteral $BaseRef
        $escapedRoot = ConvertTo-SqlLiteral $RepoRoot
        $csoCmd = "& '$csoScript' -BaseRef '$escapedBase' -RepoRoot '$escapedRoot' -Quiet"
        if ($ExpectedFiles) {
            # Build an array subexpression @('a','b') in the -Command string.
            # Naive space-joined '-ExpectedFiles a b' does NOT bind [string[]]
            # when the command runs through `pwsh -Command` (only the first
            # value binds; the rest hit positional/binding errors). Verified:
            # @() subexpression binds correctly and reports missing files.
            $quoted = ($ExpectedFiles | ForEach-Object { "'" + (ConvertTo-SqlLiteral $_) + "'" }) -join ','
            $csoCmd += " -ExpectedFiles @($quoted)"
        }
        if ($SubagentOutputFile -and (Test-Path -LiteralPath $SubagentOutputFile)) {
            $csoCmd += " -AgentOutputFile '" + (ConvertTo-SqlLiteral $SubagentOutputFile) + "'"
        } elseif ($SubagentOutputFile) {
            Write-Warning "SubagentOutputFile not found: $SubagentOutputFile — contract validation skipped"
        }
        $csoSubproc = Invoke-SubprocessWithTimeout -CommandLine $csoCmd -TimeoutSec 30
        $csoResult = $csoSubproc.output | Where-Object { $_ -match '^\{' } | Select-Object -First 1 | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($csoSubproc.timedOut) {
            $csoOk = $false
        } else {
            $csoOk = $csoResult -and $csoResult.status -ne 'FAIL'
        }
        if ($SubagentOutputFile -and (Test-Path -LiteralPath $SubagentOutputFile) -and -not $csoSubproc.timedOut -and $csoResult) {
            $contractRan = $true
            if ($null -ne $csoResult.PSObject.Properties['contract_valid']) { $contractValid = [bool]$csoResult.contract_valid }
            if ($null -ne $csoResult.PSObject.Properties['contract_detail']) { $contractDetail = $csoResult.contract_detail }
        }
        $checks += [PSCustomObject]@{
            name   = "empty_output"
            passed = $csoOk
            detail = if ($csoSubproc.timedOut) { "TIMEOUT after 30 s" }
                     elseif ($csoResult) { $csoResult.status } else { "no JSON returned" }
        }
        if (-not $csoOk) { $passed = $false }
    } else {
        Write-Warning "check-subagent-output.ps1 not found at $csoScript — empty-output check skipped"
    }

    # 2. Write-scope validation (mirrors post-delegation-check.ps1 sync path)
    if ($AllowedPaths) {
        $wsScript = Join-Path $RepoRoot 'scripts\validate-write-scope.ps1'
        if (-not (Test-Path $wsScript)) { $wsScript = Join-Path $PSScriptRoot 'validate-write-scope.ps1' }
        if (Test-Path $wsScript) {
            $escapedPaths = "'" + ((ConvertTo-SqlLiteral ($AllowedPaths -join ','))) + "'"
            $escapedBase  = ConvertTo-SqlLiteral $BaseRef
            $wsCmd = "& '$wsScript' -AllowedPaths $escapedPaths -BaseRef '$escapedBase'"
            $wsSubproc = Invoke-SubprocessWithTimeout -CommandLine $wsCmd -TimeoutSec 30
            if ($wsSubproc.timedOut) {
                $wsOk = $false
            } else {
                $wsOutput = ($wsSubproc.output | Where-Object { $_ -match '\[CLEAN\]|\[VIOLATION\]' } | Select-Object -First 1)
                $wsOk = $wsOutput -match '\[CLEAN\]'
            }
            $checks += [PSCustomObject]@{
                name   = "write_scope"
                passed = $wsOk
                detail = if ($wsSubproc.timedOut) { "TIMEOUT after 30 s" }
                         elseif ($wsOk) { "in scope" } else { "VIOLATION: files outside allowed paths" }
            }
            if (-not $wsOk) { $passed = $false }
        } else {
            Write-Warning "validate-write-scope.ps1 not found at $wsScript — write-scope check skipped"
        }
    } else {
        $checks += [PSCustomObject]@{ name = "write_scope"; passed = $false; detail = "FAIL-CLOSED: AllowedPaths not provided — write-scope mandatory for all subagent delegations (v3 Perm-4)" }
        $passed = $false
    }

    # 2b. C4d contract validation result (only when -SubagentOutputFile provided)
    if ($contractRan) {
        $checks += [PSCustomObject]@{
            name   = "contract_validation"
            passed = $contractValid
            detail = if ($contractValid) { "pass" } else { $contractDetail }
        }
        if (-not $contractValid) { $passed = $false }
    }

    # 3. Changed-files snapshot (committed + working tree, unique) — stability signal
    $committed = @()
    try {
        $committed = git -C $RepoRoot diff --name-only "$BaseRef..HEAD" 2>&1 |
            Where-Object { $_ -and $_ -notmatch "^warning:" -and $_ -notmatch "^\s*$" }
    } catch { $committed = @() }
    $statusRaw = @()
    try {
        $statusRaw = git -C $RepoRoot status --porcelain 2>&1
    } catch { $statusRaw = @() }
    $wcFiles = @($statusRaw | Where-Object { $_ -and $_ -notmatch "^warning:" } |
        ForEach-Object {
            $path = ($_ -replace '^\?\?\s+', '' -replace '^[MADRCU?!]+\s+', '').Trim()
            if ($path) { $path }
        })
    $changedFiles = @($committed + $wcFiles | Sort-Object -Unique)

    # 3b. Scope-filter the stability signal (2026-08-19 rec #5): when -AllowedPaths
    # is provided, changes OUTSIDE the delegation scope are ignored so external
    # commits (other agents, user edits) cannot reset convergence detection.
    # Patterns are -like wildcards relative to repo root (e.g. "src/*").
    if ($AllowedPaths) {
        $changedFiles = @($changedFiles | Where-Object {
            $file = $_
            @($AllowedPaths | Where-Object { $file -like $_ }).Count -gt 0
        })
    }

    return [PSCustomObject]@{
        checks       = $checks
        passed       = $passed
        changedFiles = $changedFiles
        contractRan    = $contractRan
        contractValid  = $contractValid
        contractDetail = $contractDetail
    }
}

# --- Main poll loop ---
if ($DryRun) {
    [Console]::Error.WriteLine("[monitor][DryRun] would monitor: BaseRef=$BaseRef result=$resultFile poll=${PollIntervalSec}s max=${MaxWaitSec}s")
    Write-Output "dry-run: no polling performed (BaseRef=$BaseRef)"
    exit 0
}
[Console]::Error.WriteLine("[monitor] started: BaseRef=$BaseRef result=$resultFile poll=${PollIntervalSec}s max=${MaxWaitSec}s")
Write-Progress -Activity "async monitor ($BaseRef)" -Status "started" -PercentComplete 0

# --- PID file (registry cancel support): write before polling, remove on exit ---
$pidFile = $null
if ($TaskId) {
    $learningsDir = Join-Path $RepoRoot '.learnings'
    if (-not (Test-Path $learningsDir)) {
        New-Item -ItemType Directory -Path $learningsDir -Force -ErrorAction SilentlyContinue | Out-Null
    }
    $pidFile = Join-Path $learningsDir "async-monitor-$TaskId.pid"
    if ((Test-Path -LiteralPath $pidFile -ErrorAction SilentlyContinue) -and -not $Force) {
        [Console]::Error.WriteLine("[monitor] WARNING: stale PID file exists ($pidFile) — pass -Force to suppress this warning")
    }
    try {
        Set-Content -Path $pidFile -Value $PID -Encoding UTF8 -ErrorAction Stop
        [Console]::Error.WriteLine("[monitor] pid=$PID -> $pidFile")
    } catch {
        [Console]::Error.WriteLine("[monitor] WARNING: could not write PID file: $($_.Exception.Message)")
    }
}

$started      = Get-Date
$deadline     = $started.AddSeconds([Math]::Max(1, $MaxWaitSec))
$pollCount    = 0
$stablePolls  = 0
$prevSnapshot = $null
$lastSnapshot = $null
$reason       = "timeout"

while ($true) {
    $pollCount++
    Write-Progress -Activity "async monitor ($BaseRef)" -Status "poll $pollCount (stable=$stablePolls/2)" -PercentComplete ([Math]::Min(95, [int]($pollCount * 10)))
    $snap = Get-CheckSnapshot
    $sig = ($snap.changedFiles -join "`n")

    if ($null -ne $prevSnapshot -and $sig -eq $prevSnapshot) {
        $stablePolls++
        [Console]::Error.WriteLine("[monitor] poll $pollCount stable ($stablePolls/2 consecutive) — $($snap.changedFiles.Count) file(s)")
    } else {
        if ($null -ne $prevSnapshot) { $stablePolls = 0 }
        [Console]::Error.WriteLine("[monitor] poll $pollCount changes seen — $($snap.changedFiles.Count) file(s)")
    }
    $prevSnapshot = $sig
    $lastSnapshot = $snap

    if ($stablePolls -ge 2) { $reason = "stable"; break }
    if ((Get-Date) -ge $deadline) { $reason = "timeout"; break }
    Start-Sleep -Seconds $PollIntervalSec
}

# --- Write final result ---
$waitedSec = [Math]::Round(((Get-Date) - $started).TotalSeconds, 1)
$result = @{
    schema_version = 1
    base_ref       = $BaseRef
    status         = if ($lastSnapshot.passed) { "OK" } else { "FAIL" }
    passed         = $lastSnapshot.passed
    checks         = $lastSnapshot.checks
    changed_files  = $lastSnapshot.changedFiles
    file_count     = $lastSnapshot.changedFiles.Count
    contract_ran    = $lastSnapshot.contractRan
    contract_valid  = if ($lastSnapshot.contractRan) { $lastSnapshot.contractValid } else { $true }  # sync-path convention: not evaluated = no violation detected
    contract_detail = if ($lastSnapshot.contractRan) { $lastSnapshot.contractDetail } else { "not evaluated" }
    reason         = $reason
    poll_count     = $pollCount
    waited_sec     = $waitedSec
    result_file    = $resultFile
}
$resultJson = $result | ConvertTo-Json -Depth 5

# Atomic result write (temp file + Move-Item). Backward compat: without a
# -CompletionCallback the monitor always writes the result file; with a callback
# the callback owns the {TaskId}.async-result.json write unless -WriteResultFile forces it.
if ($WriteResultFile -or -not $CompletionCallback) {
    $tmpResult = $resultFile + '.tmp'
    $resultJson | Set-Content -Path $tmpResult -Encoding UTF8
    Move-Item -LiteralPath $tmpResult -Destination $resultFile -Force
    [Console]::Error.WriteLine("[monitor] done: status=$($result.status) reason=$reason -> $resultFile")
}

# --- Push completion callback (replaces consumer-side polling for completion) ---
if ($CompletionCallback) {
    try {
        & $CompletionCallback -ResultJson $resultJson -TaskId $TaskId
    } catch {
        [Console]::Error.WriteLine("[monitor] callback FAILED for TaskId=${TaskId}: $($_.Exception.Message)")
    }
}

# --- Cleanup: remove PID file if created ---
if ($pidFile -and (Test-Path -LiteralPath $pidFile)) {
    try {
        Remove-Item -LiteralPath $pidFile -Force -ErrorAction Stop
    } catch {
        [Console]::Error.WriteLine("[monitor] WARNING: could not remove PID file ${pidFile}: $($_.Exception.Message)")
    }
}

Write-Progress -Activity "async monitor ($BaseRef)" -Status "done: $($result.status)" -PercentComplete 100
exit $(if ($lastSnapshot.passed) { 0 } else { 1 })
