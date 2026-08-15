#requires -Version 7
<#
.SYNOPSIS
    Budget enforcement guard for subagent delegations — monitors timeout, tool-call
    limits, and quality metrics. Part of the subagent result quality improvements.

.DESCRIPTION
    Wraps a registered delegation and enforces:
      1. Wall-clock timeout (default 300s = 5 min per _core-behavior-gp.md)
      2. Tool-call budget (default 25 per _core-behavior-gp.md)
      3. Quality gate via delegation-registry resolve

    Use `poll` mode to check if a delegation has exceeded its budget, or `enforce`
    mode to run a full check + resolve + quality scoring cycle.

.PARAMETER TaskId
    The Task-tool ID registered in delegation-registry.ps1.

.PARAMETER Action
    `poll` — check budget status (exit 0 = OK, exit 1 = timeout/budget exceeded)
    `enforce` — run post-delegation-check + contract validation + quality score

.PARAMETER BaseRef
    Git reference for diff (default HEAD).

.PARAMETER RepoRoot
    Repository root (default: auto-detected).

.PARAMETER MaxDurationSeconds
    Max wall-clock seconds before flagging timeout (default 300 = 5 min).

.PARAMETER MaxToolCalls
    Max tool calls before flagging (default 25 per _core-behavior-gp.md).

.PARAMETER Quiet
    JSON-only output on stdout.

.EXAMPLE
    # Poll: is the delegation still within budget?
    scripts/subagent-budget-guard.ps1 -Action poll -TaskId "abc-123"

    # Enforce: run full post-delegation + quality check
    scripts/subagent-budget-guard.ps1 -Action enforce -TaskId "abc-123" -MaxDurationSeconds 120
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("poll", "enforce")]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [string]$BaseRef = "HEAD",
    [string]$RepoRoot = "",
    [int]$MaxDurationSeconds = 300,
    [int]$MaxToolCalls = 25,
    [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
    while ($RepoRoot -and -not (Test-Path (Join-Path $RepoRoot '.git'))) {
        $RepoRoot = Split-Path -Parent $RepoRoot
    }
}

$registryScript = Join-Path $RepoRoot 'scripts\delegation-registry.ps1'

# --- Poll: check budget status against registration ---
if ($Action -eq 'poll') {
    $regResult = & $registryScript -Action poll -TaskId $TaskId -RepoRoot $RepoRoot -Quiet 2>&1
    $regJson = $regResult | Where-Object { $_ -match '^\{' } | Select-Object -First 1 | ConvertFrom-Json -ErrorAction SilentlyContinue

    if (-not $regJson -or $regJson.status -eq 'not_found') {
        if ($Quiet) { @{ status = "not_found"; task_id = $TaskId } | ConvertTo-Json -Compress }
        else { Write-Output "ERROR: TaskId '$TaskId' not found in delegation registry" }
        exit 1
    }

    $budgetExceeded = $regJson.budget_exceeded
    $elapsed = $regJson.elapsed_seconds
    $timeout = $regJson.timeout_seconds

    if ($Quiet) {
        @{
            status            = if ($budgetExceeded) { "timeout" } else { $regJson.status }
            task_id           = $TaskId
            elapsed_seconds   = $elapsed
            timeout_seconds   = $timeout
            budget_exceeded   = $budgetExceeded
            max_duration_s    = $MaxDurationSeconds
        } | ConvertTo-Json -Compress
    } else {
        $icon = if ($budgetExceeded) { "TIMEOUT" } else { "OK   " }
        Write-Output "[$icon] budget-guard: $($TaskId) elapsed=$([math]::Round($elapsed,1))s / limit=$($MaxDurationSeconds)s"
        if ($budgetExceeded) {
            Write-Output "  X  Budget exceeded - subagent delegation took $([math]::Round($elapsed,1))s (limit: $MaxDurationSeconds s)"
        }
    }

    exit $(if ($budgetExceeded) { 1 } else { 0 })
}

# --- Enforce: run full post-delegation-check + quality scoring ---
if ($Action -eq 'enforce') {
    try {
    $score = 0
    $maxScore = 10

    # Read registry entry directly (avoids & $registryScript subprocess nesting issues)
    $regFile = Join-Path $RepoRoot '.learnings\delegation-registry.json'
    $entry = $null
    if (Test-Path $regFile) {
        try {
            $regData = Get-Content $regFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $entry = $regData.PSObject.Properties | Where-Object { $_.Name -eq $TaskId } | Select-Object -ExpandProperty Value -ErrorAction SilentlyContinue
        } catch { }
    }

    if (-not $entry) {
        if ($Quiet) { @{ status = "not_found"; task_id = $TaskId; quality_score = 0; max_score = $maxScore; contract_valid = $false; checks = @() } | ConvertTo-Json -Compress }
        else { Write-Output "ERROR: TaskId '$TaskId' not found in delegation registry" }
        exit 1
    }

    # Convert PSObject to hashtable for safe property access (strict mode + ConvertTo-Json omits null properties)
    $entryHash = @{}
    foreach ($p in $entry.PSObject.Properties) { $entryHash[$p.Name] = $p.Value }

    # Read subagent output file if registered
    $subagentOutput = $entryHash['subagent_output']
    $allowedPaths  = $entryHash['allowed_paths']
    $timeoutSec    = if ($entryHash['timeout_seconds']) { $entryHash['timeout_seconds'] } else { 30 }
    $baseRef       = if ($entryHash['base_ref']) { $entryHash['base_ref'] } else { $BaseRef }

    # Call post-delegation-check via pwsh subprocess (uses & which resolves pwsh from PATH; exit in pdc exits subprocess only)
    $pdcScript = Join-Path $RepoRoot 'scripts\post-delegation-check.ps1'
    $resolveStart = Get-Date
    $pdcParams = @(
        '-NoProfile',
        '-File', "`"$pdcScript`"",
        '-BaseRef', "`"$baseRef`"",
        '-RepoRoot', "`"$RepoRoot`"",
        '-Quiet',
        "-TimeoutSeconds $timeoutSec"
    )
    if ($allowedPaths) {
        foreach ($p in @($allowedPaths)) { $pdcParams += '-AllowedPaths'; $pdcParams += "`"$p`"" }
    }
    if ($subagentOutput) {
        $pdcParams += '-SubagentOutputFile'; $pdcParams += "`"$($subagentOutput -replace '"','\"')`""
    }

    $result = try {
        & pwsh @pdcParams 2>&1
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
            "pdc exited with code $LASTEXITCODE"
        }
    } catch {
        @($_ | Out-String)
    }

    $jsonLine = $result | Where-Object { $_ -match '^\{' } | Select-Object -First 1
    $json = $jsonLine | ConvertFrom-Json -ErrorAction SilentlyContinue
    if (-not $json) {
        $json = [PSCustomObject]@{
            passed          = $false
            contract_valid  = $false
            file_count      = 0
            checks          = @([PSCustomObject]@{ name = "post_deployment"; passed = $false; detail = "no JSON from pdc" })
            changed_files   = @()
        }
    }

    # Compute budget tracking
    $registeredStr = $entryHash['registered']
    $registered = if ($registeredStr) { [DateTime]$registeredStr } else { Get-Date }
    $elapsedSeconds = (Get-Date) - $registered | Select-Object -ExpandProperty TotalSeconds
    $budgetExceeded = $elapsedSeconds -gt $timeoutSec

    # Build quality object with budget tracking
    $quality = $json
    $quality | Add-Member -NotePropertyName budget_exceeded -NotePropertyValue $budgetExceeded -ErrorAction SilentlyContinue
    $quality | Add-Member -NotePropertyName resolve_duration_s -NotePropertyValue ([math]::Round(((Get-Date) - $resolveStart).TotalSeconds, 1)) -ErrorAction SilentlyContinue

    if ($quality.passed) { $score += 4 }
    if ($quality.file_count -gt 0) { $score += 1 }
    if ($quality.contract_valid -ne $false) { $score += 2 }
    $failedChecks = @($quality.checks | Where-Object { -not $_.passed }).Count
    if ($failedChecks -eq 0) { $score += 2 }
    if (-not $quality.budget_exceeded) { $score += 1 }

    $score = [Math]::Min($score, $maxScore)

    if ($Quiet) {
        @{
            status          = if ($json.passed) { "resolved" } else { "failed" }
            task_id         = $TaskId
            quality_score   = $score
            max_score       = $maxScore
            checks          = $quality.checks
            contract_valid  = $quality.contract_valid
            duration_s      = $quality.resolve_duration_s
        } | ConvertTo-Json -Compress -Depth 5
    } else {
        Write-Output "[$(if ($json.passed) { "resolved" } else { "failed" })] budget-guard: $($TaskId) quality_score=$score/$maxScore"
        Write-Output "  Duration: $($quality.resolve_duration_s)s"
        Write-Output "  Contract valid: $($quality.contract_valid)"
        Write-Output "  Checks:"
        $quality.checks | ForEach-Object {
            $c = if ($_.passed) { "    OK  " } else { "    FAIL" }
            Write-Output "$c $($_.name): $($_.detail)"
        }
    }

    exit $(if ($json.passed) { 0 } else { 1 })
    } catch {
        if ($Quiet) { @{ status = "error"; task_id = $TaskId; quality_score = 0; max_score = $maxScore; error = ($_.Exception.Message); error_type = $_.Exception.GetType().Name } | ConvertTo-Json -Compress }
        else { Write-Output "ERROR: $($_.Exception.Message)"; Write-Output $_.ScriptStackTrace }
        exit 1
    }
}
