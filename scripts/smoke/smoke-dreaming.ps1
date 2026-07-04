#requires -Version 7.6

<#
.SYNOPSIS
  Smoke test: checks session-miner.ps1 exists.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$env:USERPROFILE\.config\opencode\scripts\bash-safe.ps1"

$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Target = Join-Path $RepoRoot 'scripts\session-miner.ps1'

if (Test-Path $Target) {
    Write-Host '[PASS] Dreaming auto-trigger (session-miner)' -ForegroundColor Green
    exit 0
} else {
    Write-Host '[FAIL] Dreaming auto-trigger (session-miner)' -ForegroundColor Red
    Write-Host "  -> not found: $Target" -ForegroundColor DarkGray
    exit 1
}
