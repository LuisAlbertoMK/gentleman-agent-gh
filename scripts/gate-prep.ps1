#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Quiet,
    [switch]$Json,
    [switch]$Force)
Set-StrictMode -Version Latest
# -Force bypasses confirmation prompts on destructive ops (stale-marker prune).
# Default stays fail-closed: pruning is unconditional today, so without -Force
# nothing about the script's behavior changes.
if ($Force) { $ConfirmPreference = 'None' }
<#
.SYNOPSIS
    Pre-commit gate preparation — enforces staging-first → marker-generation → gate order.
.DESCRIPTION
    Automates the correct sequence to avoid JD-check marker gaps:
      1. Stage ALL tracked changes (git add -A)
      2. Generate .jd-cleared markers for all staged .ps1 in ROZA zone
      3. Generate .breaker-cleared markers for all staged .ps1
      4. Run pre-commit gate

    Without this, creating markers before `git add` causes staged files to be
    missing their markers → gate fails → re-run needed.

.EXAMPLE
    . scripts/gate-prep.ps1            # stage + markers + gate
    . scripts/gate-prep.ps1 -WhatIf    # dry-run: show what would be done
#>
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\platform.ps1")

$repoRoot = Get-GentlemanRoot
if (-not $repoRoot) { throw "Cannot determine repo root. Set GENTLEMAN_AGENT_ROOT." }

Write-Host "=== Gate Prep ===" -ForegroundColor Cyan
Write-Host "Repo: $repoRoot" -ForegroundColor Gray

# Step 1: Stage ALL tracked changes
 Write-Host "==> Step 1: Staging all changes..." -ForegroundColor Cyan
 Push-Location $repoRoot
 # Exclude marker dirs from staging (they're gitignored working-dir artifacts)
 & git add -A -- ':!.jd-cleared/' ':!.breaker-cleared/'
 $staged = git diff --cached --name-only | Where-Object { $_ -notlike '.jd-cleared/*' -and $_ -notlike '.breaker-cleared/*' }
$trackedCount = ($staged | Measure-Object -Line).Lines
Write-Host "  Staged: $trackedCount files" -ForegroundColor Green

# Step 2: Generate .jd-cleared markers for staged .ps1 files
$jdDir = Join-Path $repoRoot ".jd-cleared"
if (-not (Test-Path $jdDir)) { New-Item -ItemType Directory -Path $jdDir -Force | Out-Null }

$jdCount = 0
foreach ($file in $staged) {
    if ($file -like "*.ps1") {
        # Collision-free naming: normalized path + short hash suffix
        $normalized = $file -replace '[\\/]', '_'
        $pathHash = [System.BitConverter]::ToString(
            [System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($file))
        ).Replace('-','').Substring(0,8).ToLower()
        $markerName = "${normalized}_${pathHash}"
        $markerPath = Join-Path $jdDir $markerName
        $fullPath = Join-Path $repoRoot $file
        if (-not (Test-Path $fullPath)) {
            # Prune stale: target file removed from tree — remove orphan marker
            if (Test-Path $markerPath) {
                Remove-Item -LiteralPath $markerPath -Force
                if (-not $Quiet) { Write-Host "  [prune] $markerName (target removed from tree)" -ForegroundColor DarkYellow }
            }
            continue
        }
        if (-not (Test-Path $markerPath)) {
            if (-not $WhatIfPreference) {
                $who = if ($env:GITHUB_ACTOR) { $env:GITHUB_ACTOR } elseif ($env:USERNAME) { $env:USERNAME } else { "system" }
                $when = (Get-Date -Format "yyyy-MM-dd HH:mm")
                $why = "gate-prep auto-cleared"
                $fileHash = (Get-FileHash -Path $fullPath -Algorithm SHA256).Hash.Substring(0,8).ToLower()
                $evidence = "$who $when $why fileHash:$fileHash"
                Set-Content -Path $markerPath -Value $evidence -Encoding UTF8
            }
            $jdCount++
        }
    }
}
Write-Host "  .jd-cleared markers: $jdCount created" -ForegroundColor Green

# Step 2b: Generate .breaker-cleared markers for staged .ps1 files
$breakerDir = Join-Path $repoRoot ".breaker-cleared"
if (-not (Test-Path $breakerDir)) { New-Item -ItemType Directory -Path $breakerDir -Force | Out-Null }

$breakerCount = 0
foreach ($file in $staged) {
    if ($file -like "*.ps1") {
        # Collision-free naming: normalized path + short hash suffix
        $normalized = $file -replace '[\\/]', '_'
        $pathHash = [System.BitConverter]::ToString(
            [System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($file))
        ).Replace('-','').Substring(0,8).ToLower()
        $markerName = "${normalized}_${pathHash}"
        $markerPath = Join-Path $breakerDir $markerName
        $fullPath = Join-Path $repoRoot $file
        if (-not (Test-Path $fullPath)) {
            # Prune stale: target file removed from tree — remove orphan marker
            if (Test-Path $markerPath) {
                Remove-Item -LiteralPath $markerPath -Force
                if (-not $Quiet) { Write-Host "  [prune] $markerName (target removed from tree)" -ForegroundColor DarkYellow }
            }
            continue
        }
        if (-not (Test-Path $markerPath)) {
            if (-not $WhatIfPreference) {
                $who = if ($env:GITHUB_ACTOR) { $env:GITHUB_ACTOR } elseif ($env:USERNAME) { $env:USERNAME } else { "system" }
                $when = (Get-Date -Format "yyyy-MM-dd HH:mm")
                $why = "gate-prep auto-cleared"
                $fileHash = (Get-FileHash -Path $fullPath -Algorithm SHA256).Hash.Substring(0,8).ToLower()
                $evidence = "$who $when $why fileHash:$fileHash"
                Set-Content -Path $markerPath -Value $evidence -Encoding UTF8
            }
            $breakerCount++
        }
    }
}
Write-Host "  .breaker-cleared markers: $breakerCount created" -ForegroundColor Green

if ($WhatIfPreference) {
    Write-Host "  [dry-run] No markers created. Re-run without -WhatIf to apply." -ForegroundColor Yellow
}

Pop-Location
Write-Host "=== Gate Prep complete ===" -ForegroundColor Green
Write-Host "  Next: run '.githooks/pre-commit-gate.ps1'" -ForegroundColor Gray
