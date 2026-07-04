#requires -Version 7.6

<#
.SYNOPSIS
  Smoke test: runs check-upstream.ps1 -Json, passes if exit code 0 or 1.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$env:USERPROFILE\.config\opencode\scripts\bash-safe.ps1"

$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Script = Join-Path $RepoRoot 'scripts\check-upstream.ps1'

if (-not (Test-Path $Script)) {
    Write-Host '[FAIL] Upstream check auto' -ForegroundColor Red
    Write-Host "  -> script not found: $Script" -ForegroundColor DarkGray
    exit 1
}

& $Script -Json *>&1 | Out-Null

if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) {
    Write-Host '[PASS] Upstream check auto' -ForegroundColor Green
    exit 0
} else {
    Write-Host '[FAIL] Upstream check auto' -ForegroundColor Red
    Write-Host "  -> exit $LASTEXITCODE" -ForegroundColor DarkGray
    exit 1
}
