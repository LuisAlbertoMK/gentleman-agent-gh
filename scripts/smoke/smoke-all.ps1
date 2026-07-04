#requires -Version 7.6

<#
.SYNOPSIS
  Run all automation claim smoke tests for CYCLE.md metrics.
#>

param([switch]$Json)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$env:USERPROFILE\.config\opencode\scripts\bash-safe.ps1"

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

$smokeDir = Join-Path $RepoRoot 'scripts\smoke'
$smokeScripts = @(
    @{ name = 'Backlog Integrity auto-check'; file = 'smoke-backlog-integrity.ps1' }
    @{ name = 'Upstream check auto';          file = 'smoke-upstream-check.ps1' }
    @{ name = 'Dreaming auto-trigger (session-miner)'; file = 'smoke-dreaming.ps1' }
    @{ name = 'Score freshness warning';       file = 'smoke-score-freshness.ps1' }
    @{ name = 'Cycle LOOP step 3 freshness check'; file = 'smoke-cycle-loop.ps1' }
    @{ name = 'JsonFast serialization module'; file = 'smoke-jsonfast.ps1' }
)

foreach ($s in $smokeScripts) {
    $path = Join-Path $smokeDir $s.file
    if (-not (Test-Path $path)) {
        Add-SmokeResult -Name $s.name -Passed $false -Detail "script not found: $($s.file)"
    } else {
        & $path *>&1 | Out-Null
        Add-SmokeResult -Name $s.name -Passed ($LASTEXITCODE -eq 0) -Detail "exit $LASTEXITCODE"
    }
}

# --- Summary ---
$allPassed = ($script:failed -eq 0)
$summary = @{
    smoke     = $script:smokeResults
    passed    = $script:passed
    failed    = $script:failed
    allPassed = $allPassed
}

$color = if ($allPassed) { 'Green' } else { 'Red' }
Write-Host "`n=== Smoke Results: $($script:passed) passed, $($script:failed) failed ===" -ForegroundColor $color

if ($Json) { Write-Output ($summary | ConvertTo-Json -Depth 2) }
if ($allPassed) { exit 0 } else { exit 1 }
