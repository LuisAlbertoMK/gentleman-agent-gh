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

function Test-CandidateBudget {
    [CmdletBinding()]
    param(
        [string]$BaseRef = "",
        [array]$FileEntries = $null,
        [int]$BudgetBytes = 204800,
        [string]$RepoRoot = ""
    )
    # Upstream v3.4.0 adapted: frozen evidence must fit 200 KiB per runtime
    # BEFORE persisting authority (markers). Generated paths travel as
    # metadata summary (1 KiB each) instead of full bytes, capped at the first
    # 50 generated files — beyond that cap real bytes are counted (B5: the cap
    # itself is not evadible by stuffing N generated paths).
    # PS 5.1-safe syntax by design (no ternary, no ??, no HashData).
    # FAIL-CLOSED (B5): BaseRef must resolve via git rev-parse --verify and no
    # git error is swallowed — any git failure throws instead of undercounting.
    $entries = @()
    if ($null -ne $FileEntries -and $FileEntries.Count -gt 0) {
        $entries = $FileEntries
    }
    else {
        $gitArgs = @()
        if ($BaseRef -ne "") {
            if ($RepoRoot -ne "") {
                & git -C "$RepoRoot" rev-parse --verify --quiet "$BaseRef" 2>$null | Out-Null
            }
            else {
                & git rev-parse --verify --quiet "$BaseRef" 2>$null | Out-Null
            }
            if ($LASTEXITCODE -ne 0) {
                throw "Test-CandidateBudget: invalid BaseRef '$BaseRef' — git rev-parse --verify failed (fail-closed)"
            }
            $gitArgs = @("diff", "--numstat", $BaseRef)
        }
        else {
            $gitArgs = @("diff", "--cached", "--numstat")
        }
        $numstatLines = @()
        if ($RepoRoot -ne "") {
            $numstatLines = & git -C "$RepoRoot" @gitArgs 2>$null
        }
        else {
            $numstatLines = & git @gitArgs 2>$null
        }
        if ($LASTEXITCODE -ne 0) {
            throw "Test-CandidateBudget: git diff --numstat failed (exit $LASTEXITCODE) — fail-closed, refusing silent empty budget"
        }
        if ($null -eq $numstatLines) {
            $numstatLines = @()
        }
        $generatedAsMetadata = 0
        foreach ($line in $numstatLines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $parts = $line -split "`t"
            if ($parts.Count -lt 3) { continue }
            $path = $parts[2].Trim()
            if ($path -eq "") { continue }
            # Handle renames "old => new" — take the new side.
            if ($path -like "*=>*") {
                $sides = $path -split "=>"
                $path = $sides[$sides.Count - 1].Trim().Trim('{', '}', ' ', '"')
            }
            $size = 0
            $isGenerated = ($path -like "*.generated.*") -or ($path -like "dist/*") -or ($path -like "*/dist/*") -or ($path -like "*.min.js")
            $useMetadata = $false
            if ($isGenerated) {
                $generatedAsMetadata++
                if ($generatedAsMetadata -le 50) {
                    $useMetadata = $true
                }
            }
            if ($useMetadata) {
                $size = 1024
            }
            else {
                $blobSize = $null
                if ($RepoRoot -ne "") {
                    $blobSize = & git -C "$RepoRoot" cat-file -s ":$path" 2>$null
                }
                else {
                    $blobSize = & git cat-file -s ":$path" 2>$null
                }
                if ($blobSize -match "^\d+$") {
                    $size = [int]$blobSize
                }
                else {
                    $fsRoot = $RepoRoot
                    if ($fsRoot -eq "") { $fsRoot = (Get-Location).Path }
                    $full = Join-Path $fsRoot $path
                    if (Test-Path -LiteralPath $full) {
                        $size = [int](Get-Item -LiteralPath $full).Length
                    }
                    else {
                        throw "Test-CandidateBudget: cannot size staged path '$path' (no blob, no file) — fail-closed"
                    }
                }
            }
            $entries = $entries + @(@{ Path = $path; Bytes = $size })
        }
    }
    # Normalize entries to effective bytes (generated => 1 KiB metadata, capped
    # at the first 50 generated files; beyond the cap real bytes are kept).
    $effective = @()
    $generatedSeen = 0
    foreach ($e in $entries) {
        $p = ""
        $b = 0
        if ($e -is [hashtable]) {
            $p = [string]$e["Path"]
            $b = [int]$e["Bytes"]
        }
        elseif ($null -ne $e.Path) {
            $p = [string]$e.Path
            $b = [int]$e.Bytes
        }
        else { continue }
        if (($p -like "*.generated.*") -or ($p -like "dist/*") -or ($p -like "*/dist/*") -or ($p -like "*.min.js")) {
            $generatedSeen++
            if ($generatedSeen -le 50) {
                $b = 1024
            }
        }
        $effective = $effective + @([pscustomobject]@{ Path = $p; Bytes = $b })
    }
    $total = 0
    foreach ($e in $effective) { $total = $total + [int]$e.Bytes }
    if ($total -gt $BudgetBytes) {
        $top5 = $effective | Sort-Object -Property Bytes -Descending | Select-Object -First 5
        $lines = @()
        foreach ($t in $top5) {
            $lines = $lines + ("  {0} ({1} bytes)" -f $t.Path, $t.Bytes)
        }
        $msg = "candidate exceeds 200 KiB per-runtime budget — reduce scope`n" + ($lines -join "`n")
        throw $msg
    }
    return [pscustomobject]@{ TotalBytes = $total; BudgetBytes = $BudgetBytes; FileCount = $effective.Count }
}

. (Join-Path $PSScriptRoot "lib\platform.ps1")

$repoRoot = Get-GentlemanRoot
if (-not $repoRoot) { throw "Cannot determine repo root. Set GENTLEMAN_AGENT_ROOT." }

Write-Host "=== Gate Prep ===" -ForegroundColor Cyan
Write-Host "Repo: $repoRoot" -ForegroundColor Gray

# Step 1: Stage ALL tracked changes
 Write-Host "==> Step 1: Staging all changes..." -ForegroundColor Cyan
 Push-Location $repoRoot
 try {
 # Exclude marker dirs from staging (they're gitignored working-dir artifacts)
 & git add -A -- ':!.jd-cleared/' ':!.breaker-cleared/'
 $staged = git diff --cached --name-only | Where-Object { $_ -notlike '.jd-cleared/*' -and $_ -notlike '.breaker-cleared/*' }
$trackedCount = ($staged | Measure-Object -Line).Lines
Write-Host "  Staged: $trackedCount files" -ForegroundColor Green

# Freeze-point budget guard (upstream v3.4.0 adapted): frozen evidence must
# fit 200 KiB per runtime BEFORE persisting authority (markers below).
# Generated paths travel as metadata summary (1 KiB each).
$budgetBaseRef = ""
if ($env:CANDIDATE_BASEREF -ne $null -and $env:CANDIDATE_BASEREF -ne "") { $budgetBaseRef = $env:CANDIDATE_BASEREF }
Test-CandidateBudget -BaseRef $budgetBaseRef -RepoRoot $repoRoot | Out-Null
Write-Host "  Candidate budget: within 200 KiB per-runtime" -ForegroundColor Green

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

 } finally {
 Pop-Location
 }
Write-Host "=== Gate Prep complete ===" -ForegroundColor Green
Write-Host "  Next: run '.githooks/pre-commit-gate.ps1'" -ForegroundColor Gray
