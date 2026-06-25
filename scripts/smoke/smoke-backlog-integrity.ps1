#requires -Version 5.1

<#
.SYNOPSIS
  Smoke test: runs check-backlog-integrity.ps1, passes if exit code 0.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$env:USERPROFILE\.config\opencode\scripts\bash-safe.ps1"

$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Script = Join-Path $RepoRoot 'scripts\check-backlog-integrity.ps1'

if (-not (Test-Path $Script)) {
    Write-Host '[FAIL] Backlog Integrity auto-check' -ForegroundColor Red
    Write-Host "  -> script not found: $Script" -ForegroundColor DarkGray
    exit 1
}

& $Script *>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host '[PASS] Backlog Integrity auto-check' -ForegroundColor Green
    exit 0
} else {
    Write-Host '[FAIL] Backlog Integrity auto-check' -ForegroundColor Red
    Write-Host "  -> exit $LASTEXITCODE" -ForegroundColor DarkGray
    exit 1
}
