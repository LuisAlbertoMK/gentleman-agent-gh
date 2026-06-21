#requires -Version 5.1

<#
.SYNOPSIS
  Run all automation claim smoke tests for CYCLE.md metrics.
#>

param([switch]$Json)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$script:passed = 0
$script:failed = 0
$script:smokeResults = @()

function Add-SmokeResult {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $script:smokeResults += @{ name = $Name; passed = $Passed; detail = $Detail }
    if ($Passed) { $script:passed++ } else { $script:failed++ }
    $color = if ($Passed) { 'Green' } else { 'Red' }
    $symbol = if ($Passed) { 'PASS' } else { 'FAIL' }
    Write-Host "[$symbol] $Name" -ForegroundColor $color
    if (-not $Passed -and $Detail) { Write-Host "  -> $Detail" -ForegroundColor DarkGray }
}

# --- Smoke 1: Backlog Integrity auto-check ---
$biScript = Join-Path $RepoRoot 'scripts\check-backlog-integrity.ps1'
if (Test-Path $biScript) {
    & $biScript *>&1 | Out-Null
    Add-SmokeResult -Name 'Backlog Integrity auto-check' -Passed ($LASTEXITCODE -eq 0) -Detail "exit $LASTEXITCODE"
} else {
    Add-SmokeResult -Name 'Backlog Integrity auto-check' -Passed $false -Detail 'script not found'
}

# --- Smoke 2: Upstream check auto ---
$upScript = Join-Path $RepoRoot 'scripts\check-upstream.ps1'
if (Test-Path $upScript) {
    & $upScript -Json *>&1 | Out-Null
    Add-SmokeResult -Name 'Upstream check auto' -Passed ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) -Detail "exit $LASTEXITCODE"
} else {
    Add-SmokeResult -Name 'Upstream check auto' -Passed $false -Detail 'script not found'
}

# --- Smoke 3: Dreaming auto-trigger (session-miner exists) ---
$smScript = Join-Path $RepoRoot 'scripts\session-miner.ps1'
Add-SmokeResult -Name 'Dreaming auto-trigger (session-miner)' -Passed (Test-Path $smScript) -Detail 'exists'

# --- Smoke 4: Score freshness warning ---
$saScript = Join-Path $RepoRoot 'scripts\score-auto.ps1'
if (Test-Path $saScript) {
    & $saScript -Quiet 2>&1 | Out-Null
    Add-SmokeResult -Name 'Score freshness warning' -Passed ($LASTEXITCODE -eq 0) -Detail 'score computed'
} else {
    Add-SmokeResult -Name 'Score freshness warning' -Passed $false -Detail 'script not found'
}

# --- Smoke 5: Cycle LOOP step 3 freshness check ---
$cyclePath = Join-Path $RepoRoot 'CYCLE.md'
if (Test-Path $cyclePath) {
    $cycle = Get-Content $cyclePath -Raw -Encoding UTF8
    $hasFreshness = $cycle -match 'freshness'
    Add-SmokeResult -Name 'Cycle LOOP step 3 freshness check' -Passed $hasFreshness -Detail 'found in LOOP'
} else {
    Add-SmokeResult -Name 'Cycle LOOP step 3 freshness check' -Passed $false -Detail 'CYCLE.md not found'
}

# --- Summary ---
$allPassed = ($script:failed -eq 0)
$summary = @{
    smoke = $script:smokeResults
    passed = $script:passed
    failed = $script:failed
    allPassed = $allPassed
}

$color = if ($allPassed) { 'Green' } else { 'Red' }
Write-Host "`n=== Smoke Results: $($script:passed) passed, $($script:failed) failed ===" -ForegroundColor $color

if ($Json) { Write-Output ($summary | ConvertTo-Json -Depth 2) }
if ($allPassed) { exit 0 } else { exit 1 }
