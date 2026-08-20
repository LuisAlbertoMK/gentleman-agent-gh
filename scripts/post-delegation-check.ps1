#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    Post-delegation verification — combines git-diff + write-scope + empty-output
    detection into a single MANDATORY check run after every subagent delegation.

.DESCRIPTION
    Wraps three checks into one protocol-enforced gate:
      1. Empty-output detection (delegates to check-subagent-output.ps1)
      2. Write-scope validation (delegates to validate-write-scope.ps1)
      3. Git status summary

    Run after every subagent delegation BEFORE trusting its output.
    Detects silent failures (empty output, scope violations, unexpected files).

    JD Review fixes (C4-C9 cluster):
      - MEDIUM: Single-quote escaping on user-provided args (prevents cmd injection)
      - HIGH:   Timeout on pwsh subprocess calls (prevents indefinite hang)
      - LOW:    Warning when dependency scripts are missing

.PARAMETER BaseRef
    Git reference to diff against (default: HEAD).

.PARAMETER AllowedPaths
    Regex pattern(s) that modified files must match. REQUIRED for write-scope validation —
    if omitted, the check FAILS (fail-closed). Enforced by v3 Perm-4.

.PARAMETER ExpectedFiles
    Filenames that SHOULD appear in the diff (passed to check-subagent-output).

.PARAMETER SubagentOutput
    The subagent's text output (stdout). When provided, the 4-field return contract
    (Decision Taken | Files Changed | Key Findings | Nuance) is validated against
    _return-contract.md. When omitted, contract validation is skipped (not a failure).
    For multi-line content, prefer -SubagentOutputFile to avoid command-string escaping issues.

.PARAMETER SubagentOutputFile
    Path to a file containing the subagent's text output. Read with Get-Content -Raw.
    Use this instead of -SubagentOutput when the content contains newlines or special
    characters that would break the command-string transport.

.PARAMETER RepoRoot
    Repository root (default: parent of script dir).

.PARAMETER TimeoutSeconds
    Timeout for subprocess calls (default: 30). Prevents indefinite hangs.

.PARAMETER Quiet
    JSON summary on stdout.

.PARAMETER Async
    Fire-and-forget mode: launch monitor-subagent.ps1 as a background process and
    return immediately (exit 0). The monitor polls for subagent completion and
    writes final results to {BaseRef}.async-result.json in RepoRoot.
    Requires -AllowedPaths — without it the check FAILS closed (v3 Perm-4).
    All synchronous behavior is preserved when -Async is NOT set.

.PARAMETER CompletionCallback
    Optional push callback script passed through to the async monitor. The monitor
    invokes `& $CompletionCallback -ResultJson <json> -TaskId <TaskId>` after the
    final result is produced, replacing consumer-side polling. Ignored unless -Async.

.EXAMPLE
    scripts\post-delegation-check.ps1                           # git diff + empty + scope
    scripts\post-delegation-check.ps1 -AllowedPaths "src/*" -ExpectedFiles "src/utils.ts"
    scripts\post-delegation-check.ps1 -AllowedPaths "src/*" -SubagentOutputFile $tmpFile
    scripts\post-delegation-check.ps1 -AllowedPaths "src/*" -SubagentOutput $output
    scripts\post-delegation-check.ps1 -AllowedPaths "src/*" -Async   # background monitor
    scripts\post-delegation-check.ps1 -AllowedPaths "src/*" -Async -CompletionCallback "./callback.ps1"  # push mode
#>
param(
    [string]$BaseRef        = "HEAD",
    [string[]]$AllowedPaths = @(),
    [string[]]$ExpectedFiles = @(),
    [string]$SubagentOutput = "",
    [string]$SubagentOutputFile = "",
    [string]$RepoRoot       = $(Split-Path -Parent $PSScriptRoot),
    [int]$TimeoutSeconds    = 30,
    [switch]$Quiet,
    [switch]$Async,
    [string]$CompletionCallback = ""
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

# --- Async mode: fire-and-forget background monitor ---
function Launch-AsyncMonitor {
    param(
        [string]$BaseRef,
        [string[]]$AllowedPaths,
        [string[]]$ExpectedFiles,
        [string]$RepoRoot,
        [string]$TaskId = "",
        [string]$CompletionCallback = ""
    )
    $monitorScript = Join-Path $RepoRoot 'scripts\monitor-subagent.ps1'
    if (-not (Test-Path $monitorScript)) { $monitorScript = Join-Path $PSScriptRoot 'monitor-subagent.ps1' }
    if (-not (Test-Path $monitorScript)) {
        throw "monitor-subagent.ps1 not found at $monitorScript — cannot start async monitor"
    }
    $escapedMonitor = ConvertTo-SqlLiteral $monitorScript
    $escapedBase    = ConvertTo-SqlLiteral $BaseRef
    $escapedRoot    = ConvertTo-SqlLiteral $RepoRoot
    $cmd = "& '$escapedMonitor' -BaseRef '$escapedBase' -RepoRoot '$escapedRoot'"
    if ($AllowedPaths) {
        $cmd += " -AllowedPaths '" + (ConvertTo-SqlLiteral ($AllowedPaths -join ',')) + "'"
    }
    if ($ExpectedFiles) {
        $escapedFiles = ($ExpectedFiles | ForEach-Object { "'" + (ConvertTo-SqlLiteral $_) + "'" }) -join ' '
        $cmd += " -ExpectedFiles $escapedFiles"
    }
    if ($CompletionCallback) {
        $cmd += " -CompletionCallback '" + (ConvertTo-SqlLiteral $CompletionCallback) + "'"
    }
    if ($TaskId) {
        $cmd += " -TaskId '" + (ConvertTo-SqlLiteral $TaskId) + "'"
    }
    $argLine = "-NoProfile -NoLogo -Command `"$cmd`""
    # Capture the process so the caller can register its PID in the delegation registry
    $proc = Start-Process -FilePath "pwsh" -ArgumentList $argLine -WindowStyle Hidden -PassThru
    return $proc
}

# --- Resolve subagent output (string or file) ---
if ($SubagentOutputFile) {
    if (Test-Path $SubagentOutputFile) {
        $SubagentOutput = Get-Content -Raw -Path $SubagentOutputFile
    } else {
        Write-Warning "SubagentOutputFile not found: $SubagentOutputFile — contract validation skipped"
    }
}

$results = @{
    baseRef      = $BaseRef
    passed       = $true
    checks       = @()
}

# --- 0. Async mode: launch monitor and return immediately ---
if ($Async) {
    if (-not $AllowedPaths) {
        $results.checks += [PSCustomObject]@{ name = "write_scope"; passed = $false; detail = "FAIL-CLOSED: AllowedPaths not provided — write-scope mandatory for all subagent delegations (v3 Perm-4)" }
        $results.passed = $false
        if ($Quiet) { $results | ConvertTo-Json -Compress }
        else { Write-Output "FAIL Async monitor NOT started — AllowedPaths required (fail-closed per v3 Perm-4)" }
        exit 1
    }

    # Validate CompletionCallback: must be an existing .ps1 file + reject metachar injection
    if ($CompletionCallback) {
        $callbackResolved = Resolve-Path $CompletionCallback -ErrorAction SilentlyContinue
        if (-not $callbackResolved) {
            $results.checks += [PSCustomObject]@{ name = "callback_validation"; passed = $false; detail = "CompletionCallback path does not exist: $CompletionCallback" }
            $results.passed = $false
            if ($Quiet) { $results | ConvertTo-Json -Compress }
            else { Write-Output "FAIL CompletionCallback path does not exist: $CompletionCallback" }
            exit 1
        }
        $CompletionCallback = $callbackResolved.Path
        if ($CompletionCallback -match '[$`^()\[\];{}]') {
            $results.checks += [PSCustomObject]@{ name = "callback_validation"; passed = $false; detail = "CompletionCallback path contains unsafe metacharacters" }
            $results.passed = $false
            if ($Quiet) { $results | ConvertTo-Json -Compress }
            else { Write-Output "FAIL CompletionCallback contains unsafe characters" }
            exit 1
        }
    }

    $proc = Launch-AsyncMonitor -BaseRef $BaseRef -AllowedPaths $AllowedPaths -ExpectedFiles $ExpectedFiles -RepoRoot $RepoRoot -TaskId $BaseRef -CompletionCallback $CompletionCallback

    # Register the monitor PID in the delegation registry so cancel/poll can find it
    $regScript = Join-Path $RepoRoot 'scripts\delegation-registry.ps1'
    if (-not (Test-Path $regScript)) { $regScript = Join-Path $PSScriptRoot 'delegation-registry.ps1' }
    if (Test-Path $regScript) {
        $escapedReg   = ConvertTo-SqlLiteral $regScript
        $escapedPaths = ConvertTo-SqlLiteral ($AllowedPaths -join ',')
        $escapedBaseRef = ConvertTo-SqlLiteral $BaseRef
        $regCmd = "& '$escapedReg' -Action register -TaskId '$escapedBaseRef' -BaseRef '$escapedBaseRef' -AllowedPaths '$escapedPaths' -MonitorPid $($proc.Id) -Quiet"
        try {
            & pwsh -NoProfile -NoLogo -Command $regCmd 2>&1 | Out-Null
        } catch {
            Write-Warning "post-delegation-check: registry registration failed: $($_.Exception.Message)"
        }
    }
    $resultFile = Join-Path $RepoRoot (($BaseRef -replace '[/\\:*?"<>|]', '_') + '.async-result.json')
    Write-Output "Async monitor started (PID $($proc.Id)) — result file: $resultFile"
    exit 0
}

# --- 1. Empty-output detection ---
$csoScript = Join-Path $RepoRoot 'scripts\check-subagent-output.ps1'
if (Test-Path $csoScript) {
    $escapedBase = ConvertTo-SqlLiteral $BaseRef
    $escapedRoot = ConvertTo-SqlLiteral $RepoRoot
    $csoCmd = "& '$csoScript' -BaseRef '$escapedBase' -RepoRoot '$escapedRoot' -Quiet"
    if ($SubagentOutput) {
        # C4d: pass subagent text output so Validate-AgentReturnContract runs
        $escapedOutput = ConvertTo-SqlLiteral $SubagentOutput
        $csoCmd += " -AgentOutput '$escapedOutput'"
    }
    if ($ExpectedFiles) {
        $escapedFiles = ($ExpectedFiles | ForEach-Object { "'" + (ConvertTo-SqlLiteral $_) + "'" }) -join ' '
        $csoCmd += " -ExpectedFiles " + $escapedFiles
    }
    $csoSubproc = Invoke-SubprocessWithTimeout -CommandLine $csoCmd -TimeoutSec $TimeoutSeconds
    $csoResult = $csoSubproc.output | Where-Object { $_ -match '^\{' } | Select-Object -First 1 | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($csoSubproc.timedOut) {
        Write-Warning "check-subagent-output.ps1 timed out after $TimeoutSeconds s"
        $csoOk = $false
    } else {
        $csoOk = $csoResult -and $csoResult.status -ne 'FAIL'
    }
    $results.checks += [PSCustomObject]@{
        name   = "empty_output"
        passed = $csoOk
        detail = if ($csoSubproc.timedOut) { "TIMEOUT after $TimeoutSeconds s" }
                 elseif ($csoResult) { $csoResult.status } else { "no JSON returned" }
    }
    if (-not $csoOk) { $results.passed = $false }

    # C4d: Extract contract validation result from check-subagent-output
    if ($SubagentOutput -and $csoResult) {
        # StrictMode-safe: the child exits early (empty-output FAIL JSON) without a
        # contract_valid property — treat absent property as "not a contract violation".
        $hasContractValid  = $null -ne $csoResult.PSObject.Properties['contract_valid']
        $hasContractDetail = $null -ne $csoResult.PSObject.Properties['contract_detail']
        $contractOk = if ($hasContractValid) { $csoResult.contract_valid -ne $false } else { $true }
        $contractDetail = if ($hasContractDetail -and $csoResult.contract_detail) { $csoResult.contract_detail } else { "pass" }
        $results.checks += [PSCustomObject]@{
            name   = "contract_validation"
            passed = $contractOk
            detail = $contractDetail
        }
        if (-not $contractOk) { $results.passed = $false }
    }
} else {
    Write-Warning "check-subagent-output.ps1 not found at $csoScript — empty-output check skipped"
}

# --- 2. Write-scope validation ---
if ($AllowedPaths) {
    $wsScript = Join-Path $RepoRoot 'scripts\validate-write-scope.ps1'
    if (Test-Path $wsScript) {
        $escapedPaths = "'" + ((ConvertTo-SqlLiteral ($AllowedPaths -join ','))) + "'"
        $escapedBase  = ConvertTo-SqlLiteral $BaseRef
        $wsCmd = "& '$wsScript' -AllowedPaths $escapedPaths -BaseRef '$escapedBase'"
        $wsSubproc = Invoke-SubprocessWithTimeout -CommandLine $wsCmd -TimeoutSec $TimeoutSeconds
        if ($wsSubproc.timedOut) {
            Write-Warning "validate-write-scope.ps1 timed out after $TimeoutSeconds s"
            $wsOk = $false
        } else {
            $wsOutput = ($wsSubproc.output | Where-Object { $_ -match '\[CLEAN\]|\[VIOLATION\]' } | Select-Object -First 1)
            $wsOk = $wsOutput -match '\[CLEAN\]'
        }
        $results.checks += [PSCustomObject]@{
            name   = "write_scope"
            passed = $wsOk
            detail = if ($wsSubproc.timedOut) { "TIMEOUT after $TimeoutSeconds s" }
                     elseif ($wsOk) { "in scope" } else { "VIOLATION: files outside allowed paths" }
        }
        if (-not $wsOk) { $results.passed = $false }
    } else {
        Write-Warning "validate-write-scope.ps1 not found at $wsScript — write-scope check skipped"
    }
} else {
    $results.checks += [PSCustomObject]@{ name = "write_scope"; passed = $false; detail = "FAIL-CLOSED: AllowedPaths not provided — write-scope mandatory for all subagent delegations" }
    $results.passed = $false
}

# --- 3. Git status summary ---
$statusRaw = git -C $RepoRoot status --porcelain 2>&1
$changedFiles = @($statusRaw | Where-Object { $_ -and $_ -notmatch '^warning:' } |
    ForEach-Object { ($_ -replace '^\?\?\s+', '' -replace '^[MADRCU?!]+\s+', '').Trim() } |
    Where-Object { $_ })

$results.changed_files = $changedFiles
$results.file_count    = $changedFiles.Count

# --- Output ---
if ($Quiet) {
    $results | ConvertTo-Json -Compress
} else {
    $icon = if ($results.passed) { "OK  " } else { "FAIL" }
    Write-Output "$icon Post-delegation check ($($results.passed ? 'PASS' : 'FAIL')): $($results.file_count) file(s) changed"
    $results.checks | ForEach-Object {
        $c = if ($_.passed) { "  OK  " } else { "  FAIL" }
        Write-Output "$c $($_.name): $($_.detail)"
    }
    if ($results.changed_files) {
        Write-Output "  Files:"
        $results.changed_files | ForEach-Object { Write-Output "    $_" }
    }
    if (-not $results.passed) {
        Write-Output "`n  X  SILENT FAILURE RISK — review before proceeding"
        Write-Output "     See: mejora-log.md:571, RUNBOOK.md:26"
    }
}

$ec = if ($results.passed) { 0 } else { 1 }
exit $ec
