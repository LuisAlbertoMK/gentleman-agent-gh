#requires -Version 5.1
<#
.SYNOPSIS
  Unified session close pipeline — log, inter-track, git status, and output structured summary.
  Designed for the !close workflow shortcut.
.DESCRIPTION
  Run this at session end BEFORE calling mem_session_summary.
  Handles: BITACORA log, inter-track increment, git status check.
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
$interTrack = Join-Path -Path $repoRoot -ChildPath "scripts/inter-track.ps1"
$scoreAuto = Join-Path -Path $repoRoot -ChildPath "scripts/score-auto.ps1"
$projectJson = Join-Path -Path $repoRoot -ChildPath ".project.json"
$dateShort = Get-Date -Format "yyyy-MM-dd"

# Log to BITACORA
$entry = "$dateShort - $Description"
if (Test-Path -LiteralPath $bitacoraPath) {
    $existingContent = Get-Content -LiteralPath $bitacoraPath -Raw
    $newContent = "$entry`r`n$existingContent"
    Set-Content -LiteralPath $bitacoraPath -Value $newContent -Encoding UTF8
}

# Auto-freshness: update .project.json if >24h stale
if (Test-Path -LiteralPath $projectJson -PathType Leaf) {
    try {
        $proj = Get-Content -LiteralPath $projectJson -Raw -Encoding UTF8 | ConvertFrom-Json
        $lastUpdate = [datetime]::ParseExact($proj.score.last_updated, "yyyy-MM-dd", $null)
        $staleDays = [math]::Floor(((Get-Date) - $lastUpdate).TotalDays)
        if ($staleDays -ge 1 -and (Test-Path -LiteralPath $scoreAuto -PathType Leaf)) {
            $freshJson = & $scoreAuto -Json 2>$null | ConvertFrom-Json
            if ($freshJson) {
                $freshJson | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $projectJson -Encoding UTF8
                Write-Host "  .project.json auto-updated (was $staleDays day(s) stale)" -ForegroundColor Green
            }
        }
    } catch {
        # Non-blocking: don't crash session close on score refresh failure
        Write-Host "  .project.json freshness check skipped ($($_.Exception.Message))" -ForegroundColor DarkYellow
    }
}

# Increment inter-track
if (Test-Path -LiteralPath $interTrack) {
    & $interTrack -Increment -Quiet
}

# Git status
$gitStatus = git status --short 2>&1
$hasChanges = (@($gitStatus | Where-Object { $_ -match '\S' }).Count) -gt 0
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
    Write-Host "Changes: $(if($hasChanges){ ($result.changeCount).ToString() + ' file(s) modified' }else{ 'clean' })" -ForegroundColor Yellow
    Write-Host "inter  : incremented"
    Write-Host ""

    Write-Host "Now complete the Engram close protocol:" -ForegroundColor Green
    Write-Host "--- auto-metrics ---" -ForegroundColor Yellow
    Write-Host "Run auto-metrics if session had code/task work (>=3 tool calls)."
    Write-Host ""
    Write-Host "--- error patterns ---" -ForegroundColor Yellow
    Write-Host "Run: mem_search(type='error|bugfix') for cross-session patterns."
    Write-Host ""
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
