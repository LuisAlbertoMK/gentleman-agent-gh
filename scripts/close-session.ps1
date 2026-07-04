#requires -Version 7.6
<#
.SYNOPSIS
  Unified session close — BITACORA + git status + mem_session_summary template.
  Designed for the !close workflow shortcut.
.DESCRIPTION
  Run this at session end BEFORE calling mem_session_summary.
  Handles: BITACORA log, git status check.
  Outputs the structured info needed for the agent's Engram close protocol.
.PARAMETER Goal
  What was the session goal? Pre-fills the summary template.
.PARAMETER Description
  Short description of what was accomplished (logged to BITACORA).
.PARAMETER Quiet
  Output JSON only (machine-readable).
.EXAMPLE
  .\scripts\close-session.ps1 -Goal "Implement !close, stdlib assertion, context-watchdog checkpoint"
.EXAMPLE
  .\scripts\close-session.ps1 -Goal "Fix N+1 query" -Description "Optimized UserList query" -Quiet
#>
param(
    [string]$Goal = "",
    [string]$Description = "Session close",
    [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
$bitacoraPath = Join-Path -Path $repoRoot -ChildPath "BITACORA.md"

# Log to BITACORA
$entry = "$(Get-Date -Format 'yyyy-MM-dd') - $Description"
if (Test-Path -LiteralPath $bitacoraPath) {
    $existingContent = Get-Content -LiteralPath $bitacoraPath -Raw
    Set-Content -LiteralPath $bitacoraPath -Value "$entry`r`n$existingContent" -Encoding UTF8
}

# Git status
$gitStatus = git status --short 2>&1
$hasChanges = @($gitStatus | Where-Object { $_ -match '\S' }).Count -gt 0
try {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch) { $branch = "unknown" }
} catch { $branch = "unknown" }

$result = [PSCustomObject]@{
    action      = "close-session"
    timestamp   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    branch      = $branch
    hasChanges  = $hasChanges
    changeCount = if ($hasChanges) { @($gitStatus | Where-Object { $_ -match '\S' }).Count } else { 0 }
    goal        = $Goal
}

if ($Quiet) {
    $result | ConvertTo-Json
} else {
    Write-Host "=== SESSION CLOSE ===" -ForegroundColor Cyan
    Write-Host "Branch : $branch"
    Write-Host "Changes: $(if($hasChanges){ "$($result.changeCount) file(s) modified" }else{ 'clean' })" -ForegroundColor Yellow
    Write-Host ""

    # Score prompt only on significant changes
    if ($hasChanges) {
        Write-Host "Run '!score' to update project score after changes." -ForegroundColor Yellow
        Write-Host ""
    }

    Write-Host "--- mem_session_summary ---" -ForegroundColor Yellow
    Write-Host "Call with:" -ForegroundColor Yellow
    Write-Host "## Goal" -ForegroundColor Gray
    if ($Goal) { Write-Host "$Goal" -ForegroundColor White }
    Write-Host "## Instructions" -ForegroundColor Gray
    Write-Host "## Discoveries" -ForegroundColor Gray
    Write-Host "## Accomplished" -ForegroundColor Gray
    Write-Host "## Next Steps" -ForegroundColor Gray
    Write-Host "## Relevant Files" -ForegroundColor Gray
}
