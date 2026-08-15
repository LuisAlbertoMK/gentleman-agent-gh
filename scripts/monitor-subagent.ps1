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

.PARAMETER RepoRoot
    Repository root (default: parent of script dir). Result JSON is written here.

.PARAMETER PollIntervalSec
    Seconds between polls (default: 15).

.PARAMETER MaxWaitSec
    Hard deadline; result is written when reached even if not yet stable (default: 300).

.EXAMPLE
    scripts\monitor-subagent.ps1 -BaseRef HEAD -AllowedPaths "src/*" -RepoRoot "D:\repo"
    scripts\monitor-subagent.ps1 -BaseRef HEAD -AllowedPaths "scripts/*" -PollIntervalSec 1 -MaxWaitSec 10
#>
param(
    [string]$BaseRef        = "HEAD",
    [string[]]$AllowedPaths = @(),
    [string[]]$ExpectedFiles = @(),
    [string]$RepoRoot       = $(Split-Path -Parent $PSScriptRoot),
    [int]$PollIntervalSec   = 15,
    [int]$MaxWaitSec        = 300
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

    # 1. Empty-output detection (mirrors post-delegation-check.ps1 sync path)
    $csoScript = Join-Path $RepoRoot 'scripts\check-subagent-output.ps1'
    if (-not (Test-Path $csoScript)) { $csoScript = Join-Path $PSScriptRoot 'check-subagent-output.ps1' }
    if (Test-Path $csoScript) {
        $escapedBase = ConvertTo-SqlLiteral $BaseRef
        $escapedRoot = ConvertTo-SqlLiteral $RepoRoot
        $csoCmd = "& '$csoScript' -BaseRef '$escapedBase' -RepoRoot '$escapedRoot' -Quiet"
        if ($ExpectedFiles) {
            $escapedFiles = ($ExpectedFiles | ForEach-Object { "'" + (ConvertTo-SqlLiteral $_) + "'" }) -join ' '
            $csoCmd += " -ExpectedFiles " + $escapedFiles
        }
        $csoSubproc = Invoke-SubprocessWithTimeout -CommandLine $csoCmd -TimeoutSec 30
        $csoResult = $csoSubproc.output | Where-Object { $_ -match '^\{' } | Select-Object -First 1 | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($csoSubproc.timedOut) {
            $csoOk = $false
        } else {
            $csoOk = $csoResult -and $csoResult.status -ne 'FAIL'
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

    return [PSCustomObject]@{
        checks       = $checks
        passed       = $passed
        changedFiles = $changedFiles
    }
}

# --- Main poll loop ---
[Console]::Error.WriteLine("[monitor] started: BaseRef=$BaseRef result=$resultFile poll=${PollIntervalSec}s max=${MaxWaitSec}s")

$started      = Get-Date
$deadline     = $started.AddSeconds([Math]::Max(1, $MaxWaitSec))
$pollCount    = 0
$stablePolls  = 0
$prevSnapshot = $null
$lastSnapshot = $null
$reason       = "timeout"

while ($true) {
    $pollCount++
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
    base_ref      = $BaseRef
    status        = if ($lastSnapshot.passed) { "OK" } else { "FAIL" }
    passed        = $lastSnapshot.passed
    checks        = $lastSnapshot.checks
    changed_files = $lastSnapshot.changedFiles
    file_count    = $lastSnapshot.changedFiles.Count
    reason        = $reason
    poll_count    = $pollCount
    waited_sec    = $waitedSec
    result_file   = $resultFile
}
$result | ConvertTo-Json -Depth 5 | Set-Content -Path $resultFile -Encoding UTF8

[Console]::Error.WriteLine("[monitor] done: status=$($result.status) reason=$reason -> $resultFile")
exit $(if ($lastSnapshot.passed) { 0 } else { 1 })