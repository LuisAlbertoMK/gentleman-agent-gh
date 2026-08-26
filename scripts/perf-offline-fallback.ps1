#requires -Version 5.1
<#
.SYNOPSIS
    Offline performance proxy — works on PowerShell 5.1 (no pwsh7 required).
.DESCRIPTION
    Estimates project performance metrics without invoking pwsh7 or hardware-profile.ps1.
    Uses:
      - Script file count + total size as a proxy for hardware capability
      - .project.json cached score (if available) as the real score
      - Measure-Command over a lightweight I/O operation as speed proxy
    Intended as a fallback when hardware-profile.ps1 is blocked by pwsh7 requirement.
.PARAMETER Json
    Output results as JSON.
.NOTES
    This script deliberately avoids pwsh7-only features:
      - No Start-ThreadJob, no ForEach-Object -Parallel
      - No $IsLinux/$IsMacOS (uses platform.ps1 shim)
      - No hardware-profile.ps1 calls
#>
param(
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Resolve repo root via platform.ps1 (PS 5.1 compatible) ──
$libDir   = Join-Path $PSScriptRoot "lib"
$platform = Join-Path $libDir "platform.ps1"
if (Test-Path $platform) { . $platform }
$repoRoot = if (Get-Command Get-GentlemanRoot -ErrorAction SilentlyContinue) {
    Get-GentlemanRoot
} else {
    # Fallback: walk up from scripts/ to find .git
    $dir = $PSScriptRoot
    while ($dir) {
        if (Test-Path (Join-Path $dir ".git")) { break }
        $parent = Split-Path -Parent $dir
        if ($parent -eq $dir) { $dir = $PSScriptRoot; break }
        $dir = $parent
    }
    $dir
}

# ── 1. Script inventory (proxy for project size / "hardware" load) ──
$scripts = @(Get-ChildItem -Path (Join-Path $repoRoot "scripts") -Filter "*.ps1" -ErrorAction SilentlyContinue)
$scriptCount = $scripts.Count
$totalSizeKB = 0
if ($scriptCount -gt 0) {
    $measure = $scripts | Measure-Object -Property Length -Sum
    $totalSizeKB = [math]::Round($measure.Sum / 1024, 1)
}

# ── 2. Speed proxy — Measure-Command over lightweight I/O ──
$speedMs = 0
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    # Lightweight operation: enumerate + hash-check (mimics what score-auto does for cache)
    $null = Get-ChildItem -Path $repoRoot -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 50 | ForEach-Object { $_.Length }
    $stopwatch.Stop()
    $speedMs = $stopwatch.ElapsedMilliseconds
} catch {
    $speedMs = -1
}

# ── 3. Score from cache (if available — avoids re-running score-auto) ──
$score = $null
$tokenBudget = $null
$cacheFile = Join-Path (Join-Path $repoRoot ".learnings") "score-cache.json"
$projectFile = Join-Path $repoRoot ".project.json"

# Try .project.json first (single source of truth)
if (Test-Path $projectFile) {
    try {
        $pj = Get-Content $projectFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $score = $pj.score.current
        # tokenBudget: infer from compaction.reserved + keep.tokens if present
        if ($pj.compaction) {
            $reserved = if ($pj.compaction.reserved) { $pj.compaction.reserved } else { 6000 }
            $keep = if ($pj.compaction.keep -and $pj.compaction.keep.tokens) { $pj.compaction.keep.tokens } else { 12000 }
            $tokenBudget = $reserved + $keep
        }
    } catch {
        Write-Debug "perf-offline: .project.json parse failed: $($_.Exception.Message)"
    }
}

# Fallback to cache
if ($null -eq $score -and (Test-Path $cacheFile)) {
    try {
        $cached = Get-Content $cacheFile -Raw -Encoding UTF8 | ConvertFrom-Json
        # v2 (slim): read from top-level fields; v1 (legacy): read from result.score
        if ($cached.v -eq 2) {
            $score = $cached.score
        } else {
            $score = $cached.result.score.current
        }
        $tokenBudget = 18000  # medium default: 6000 reserved + 12000 keep
    } catch {
        Write-Debug "perf-offline: cache parse failed: $($_.Exception.Message)"
    }
}

# Final defaults
if ($null -eq $score)     { $score = 0 }
if ($null -eq $tokenBudget) { $tokenBudget = 12000 }

# ── 4. Tier classification (mimics hardware-profile logic) ──
$tier = "unknown"
if ($scriptCount -le 15 -and $totalSizeKB -le 100) {
    $tier = "low"
} elseif ($scriptCount -le 40 -and $totalSizeKB -le 300) {
    $tier = "medium"
} else {
    $tier = "high"
}

# ── 5. Output ──
$result = [ordered]@{
    score        = $score
    tokenBudget  = $tokenBudget
    scriptCount  = $scriptCount
    scriptSizeKB = $totalSizeKB
    speedMs      = $speedMs
    tier         = $tier
    source       = if (Test-Path $projectFile) { ".project.json" }
                   elseif (Test-Path $cacheFile) { "score-cache.json" }
                   else { "none" }
    note         = "Offline proxy — no pwsh7/hardware-profile.ps1 invoked"
    timestamp    = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Host "=== Offline Perf Proxy ===" -ForegroundColor Cyan
    Write-Host "  Score:        $($result.score)/10"
    Write-Host "  Token Budget: $($result.tokenBudget)"
    Write-Host "  Scripts:      $($result.scriptCount) ($($result.scriptSizeKB) KB)"
    Write-Host "  Speed Proxy:  $($result.speedMs)ms"
    Write-Host "  Tier:         $($result.tier)"
    Write-Host "  Source:       $($result.source)"
}
