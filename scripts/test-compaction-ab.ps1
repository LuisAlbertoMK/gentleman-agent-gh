#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    A/B compaction test driver (STUB) — toggles opencode.json compaction
    keep.tokens 6000<->4000 (+ reserved 4000<->2000), backup/restore,
    runs benchmark-regression + check-token-budget, compares median, validates JSON.

.DESCRIPTION
    Part of the P2 pruning A/B plan (docs/mejoras/perf-pruning-4000-ab-2026-08-28.md).

    Phase A (control): keep 6000 / reserved 4000   — opencode.json:246,248
    Phase B (experiment): keep 4000 / reserved 2000

    Safety: backs up opencode.json, validates JSON with ConvertFrom-Json BEFORE
    writing, restores the original in `finally` (even on failure). Never pushes.

.PARAMETER Keep
    Target keep.tokens. If omitted, auto-toggles from the current value
    (6000 -> 4000, anything else -> 6000).

.PARAMETER Reserved
    Target reserved. Default: 2000 when Keep=4000, 4000 when Keep=6000.

.PARAMETER BenchCommand
    Command passed to benchmark-regression.ps1 -Command. Default: a light,
    deterministic sync command (representative of repo perf workload).

.PARAMETER Runs
    Sample count for benchmark-regression (protocol §0.7: >=5, default 10).

.PARAMETER Json
    Emit machine-readable JSON summary on stdout (agent-consumable).

.EXAMPLE
    .\scripts\test-compaction-ab.ps1 -Keep 4000 -Runs 10 -Json
    # Sets keep 4000 / reserved 2000, benches 10x, checks token budget, restores config.

.EXAMPLE
    .\scripts\test-compaction-ab.ps1 -WhatIf
    # Dry run: prints intended toggle + commands, touches nothing.
#>
param(
    [ValidateSet(4000, 6000)]
    [int]$Keep,
    [int]$Reserved,
    [string]$BenchCommand = "scripts/sync-vmk.ps1 -DryRun -Json",
    [ValidateRange(5, 100)]
    [int]$Runs = 10,
    [switch]$Json
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$configPath = Join-Path $repoRoot "opencode.json"
$backupPath = Join-Path $repoRoot ".test-compaction-ab.bak.json"
$benchScript = Join-Path $PSScriptRoot "benchmark-regression.ps1"
$budgetScript = Join-Path $PSScriptRoot "check-token-budget.ps1"

function Write-Result {
    param([object]$Payload)
    if ($Json) { $Payload | ConvertTo-Json -Depth 5 -Compress }
    else { $Payload | Format-List | Out-String }
}

# --- Preflight ---------------------------------------------------------------
if (-not (Test-Path -LiteralPath $configPath)) {
    throw "opencode.json not found at $configPath"
}
if (-not (Test-Path -LiteralPath $benchScript)) {
    throw "benchmark-regression.ps1 missing: $benchScript"
}
if (-not (Test-Path -LiteralPath $budgetScript)) {
    throw "check-token-budget.ps1 missing: $budgetScript"
}

# --- Resolve toggle from current config ---------------------------------------
try {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json -ErrorAction Stop
} catch {
    throw "Existing opencode.json is NOT valid JSON — refusing to touch it: $($_.Exception.Message)"
}

$currentKeep = [int]$config.compaction.keep.tokens
$currentReserved = [int]$config.compaction.reserved

if (-not $PSBoundParameters.ContainsKey('Keep')) {
    $Keep = if ($currentKeep -ge 6000) { 4000 } else { 6000 }
}
if (-not $PSBoundParameters.ContainsKey('Reserved')) {
    $Reserved = if ($Keep -eq 4000) { 2000 } else { 4000 }
}

# --- Backup -------------------------------------------------------------------
Copy-Item -LiteralPath $configPath -Destination $backupPath -Force
Write-Verbose "Backup -> $backupPath"

$restored = $false
try {
    if ($PSCmdlet.ShouldProcess($configPath, "set compaction keep.tokens=$Keep reserved=$Reserved")) {
        # --- Toggle (write-through to raw JSON, order-preserving) --------------
        $raw = Get-Content -LiteralPath $configPath -Raw
        $raw = $raw -replace '("keep"\s*:\s*\{\s*"tokens"\s*:\s*)\d+', "`${1}$Keep"
        $raw = $raw -replace '("reserved"\s*:\s*)\d+', "`${1}$Reserved"
        Set-Content -LiteralPath $configPath -Value $raw -Encoding utf8NoBOM -NoNewline

        # Validate AFTER write — if invalid, restore immediately and fail fast.
        try {
            $null = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Copy-Item -LiteralPath $backupPath -Destination $configPath -Force
            $restored = $true
            throw "Post-write JSON validation failed — original restored: $($_.Exception.Message)"
        }

        # --- Benchmark (10 runs per protocol §0.7, median-based) ---------------
        $benchOut = & $benchScript -Command $BenchCommand -Runs $Runs -Json -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) { throw "benchmark-regression exited $LASTEXITCODE" }
        $bench = $benchOut | Out-String | ConvertFrom-Json

        # --- Token budget gate (ADR-007) ---------------------------------------
        $budgetOut = & $budgetScript -Json -ErrorAction Stop
        if ($LASTEXITCODE -ne 0) { throw "check-token-budget exited $LASTEXITCODE" }
        $budget = ($budgetOut | Out-String | ConvertFrom-Json)

        $summary = [ordered]@{
            phase   = if ($Keep -eq 4000) { "B (prune 4000/2000)" } else { "A (control 6000/4000)" }
            keep    = $Keep
            reserved = $Reserved
            prevKeep = $currentKeep
            prevReserved = $currentReserved
            runs    = $Runs
            median_ms = $bench.median_ms
            baseline_median_ms = $bench.baseline_median_ms
            regression = [bool]$bench.regression
            tokenBudget = $budget
            restored = $false
        }

        Write-Result $summary
    }
} finally {
    # --- Restore original config unconditionally -------------------------------
    if (-not $restored -and (Test-Path -LiteralPath $backupPath)) {
        Copy-Item -LiteralPath $backupPath -Destination $configPath -Force
        $restored = $true
        Remove-Item -LiteralPath $backupPath -Force
        Write-Verbose "Config restored (keep=$currentKeep reserved=$currentReserved)"
    }
}

if ($Json -and $restored) {
    Write-Output '{"restored":true}'
}