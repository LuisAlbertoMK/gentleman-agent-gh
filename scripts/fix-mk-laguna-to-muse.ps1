#requires -Version 5.1
<#
.SYNOPSIS
    Migrate MK OpenCode configs laguna -> muse-spark, big-pickle untouched fallback.
.DESCRIPTION
    Purpose : replace retired 'opencode/laguna-s-2.1-free' refs with
              'opencode/muse-spark-1.2-contributor-free' in the global
              opencode.jsonc + repo opencode.json.
    Date    : 2026-08-27
    Anomaly : MK had 14 laguna global + 1 repo; LuisOrozco migrated
              14 -> 14 muse-spark global, 1 repo, big-pickle untouched.
              Identical counts -> same 1:1 replace applies to MK.
    Diff: 14 laguna -> 14 muse-spark global, 1 repo, big-pickle untouched
    Idempotent re-run. UTF-8 no-BOM write (PS 5.1 Set-Content -Encoding UTF8 adds a BOM).
.NOTES
    Built-in pwsh only, ASCII only.
#>
[CmdletBinding()]
param([switch]$WhatIf)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 1. Paths
$globalPath = "$env:USERPROFILE\.config\opencode\opencode.jsonc"
$repoPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\opencode.json'))
$repoExists = Test-Path -LiteralPath $repoPath
$globalBackup = $globalPath + '.bak-laguna-20260827'
$repoBackup = $repoPath + '.bak-laguna-20260827'
$lagunaPattern = 'opencode/laguna-s-2\.1-free'
$museSparkPattern = 'opencode/muse-spark-1\.2-contributor-free'
$bigPicklePattern = 'opencode/big-pickle'
$replacement = 'opencode/muse-spark-1.2-contributor-free'

# Helpers
function Get-Count {
    param([string]$Path, [string]$Pattern)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    $hits = Select-String -LiteralPath $Path -Pattern $Pattern -AllMatches -ErrorAction SilentlyContinue
    if ($null -eq $hits) { return 0 }
    return [int](($hits | ForEach-Object { $_.Matches.Count } | Measure-Object -Sum).Sum)
}
function Test-Json {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    try { $null = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json; return $true } catch { return $false }
}
function Show-Counts {
    param([string]$Label, [string]$Path)
    $l = Get-Count $Path $lagunaPattern
    $m = Get-Count $Path $museSparkPattern
    $b = Get-Count $Path $bigPicklePattern
    Write-Host ('{0} : laguna={1} muse-spark={2} big-pickle={3}' -f $Label, $l, $m, $b) -ForegroundColor Yellow
    return $l, $m, $b
}
function Backup-IfNeeded {
    param([string]$Source, [string]$Backup)
    if (-not (Test-Path -LiteralPath $Source)) { return }
    if (Test-Path -LiteralPath $Backup) { Write-Host "Backup already exists (kept): $Backup" -ForegroundColor DarkGray }
    elseif ($WhatIf) { Write-Host "[WhatIf] Would backup: $Backup" -ForegroundColor Cyan }
    else { Copy-Item -LiteralPath $Source -Destination $Backup; Write-Host "Backup created: $Backup" -ForegroundColor Green }
}
function Invoke-Migrate {
    param([string]$Path)
    # Get-Content -Raw + -replace; byte-preserving write (no BOM/newline) like Set-Content -NoNewline
    $content = Get-Content -LiteralPath $Path -Raw
    $updated = $content -replace $lagunaPattern, $replacement
    if ($content -ceq $updated) { return $false }
    if ($WhatIf) { Write-Host "[WhatIf] Would rewrite: $Path" -ForegroundColor Cyan; return $false }
    [System.IO.File]::WriteAllText($Path, $updated, (New-Object System.Text.UTF8Encoding($false)))
    return $true
}

# 2. Pre-flight
Write-Host "== Pre-flight ==" -ForegroundColor Cyan
if (-not (Test-Path -LiteralPath $globalPath)) {
    Write-Host "GLOBAL CONFIG NOT FOUND: $globalPath" -ForegroundColor Red
    Write-Host 'Is this the MK machine? Aborting.' -ForegroundColor Yellow
    exit 1
}
Write-Host "global : $globalPath" -ForegroundColor Gray
Write-Host "repo   : $repoPath" -ForegroundColor Gray

# 3. Backups (only if not already created)
Write-Host "== Backup ==" -ForegroundColor Cyan
Backup-IfNeeded $globalPath $globalBackup
Backup-IfNeeded $repoPath $repoBackup

# 4. Count before
Write-Host "== Count before ==" -ForegroundColor Cyan
$globLagunaBefore, $globMuseBefore, $globPickleBefore = Show-Counts 'global' $globalPath
if ($repoExists) { $repoLagunaB, $repoMuseB, $repoPickleB = Show-Counts 'repo' $repoPath }

# 5. Replace (Get-Content -Raw + -replace; same for global and repo)
Write-Host "== Migrate laguna -> muse-spark ==" -ForegroundColor Cyan
$globalChanged = Invoke-Migrate $globalPath
$repoChanged = $false
if ($repoExists) { $repoChanged = Invoke-Migrate $repoPath }
if ($globalChanged -or $repoChanged) { Write-Host 'Replace applied. Verifying...' -ForegroundColor Green }
else { Write-Host 'Nothing to replace (already migrated?).' -ForegroundColor DarkGray }

# 6. Count after + validate
Write-Host "== Count after + validate ==" -ForegroundColor Cyan
$globLagunaA, $globMuseA, $globPickleA = Show-Counts 'global' $globalPath
$globJsonOk = Test-Json $globalPath
Write-Host ('global json valid : {0}' -f $globJsonOk) -ForegroundColor Gray
if ($repoExists) {
    $repoLagunaA, $repoMuseA, $repoPickleA = Show-Counts 'repo' $repoPath
    $repoJsonOk = Test-Json $repoPath
    Write-Host ('repo json valid   : {0}' -f $repoJsonOk) -ForegroundColor Gray
}
$ok = $true
if ($globLagunaA -ne 0 -or $globMuseA -ne 14 -or $globPickleA -lt 2 -or -not $globJsonOk) { $ok = $false }
if ($repoExists -and ($repoLagunaA -ne 0 -or $repoMuseA -ne 1 -or -not $repoJsonOk)) { $ok = $false }
if ($WhatIf) { $ok = $true } # dry run: nothing written, nothing to fail

# 7. Summary - before/after, backups, restart warning
Write-Host "== Summary ==" -ForegroundColor Cyan
Write-Host 'Before -> After (laguna / muse-spark / big-pickle):' -ForegroundColor White
Write-Host ('  global : {0}/{1}/{2} -> {3}/{4}/{5}' -f $globLagunaBefore, $globMuseBefore, $globPickleBefore, $globLagunaA, $globMuseA, $globPickleA) -ForegroundColor Yellow
if ($repoExists) {
    Write-Host ('  repo   : {0}/{1}/{2} -> {3}/{4}/{5}' -f $repoLagunaB, $repoMuseB, $repoPickleB, $repoLagunaA, $repoMuseA, $repoPickleA) -ForegroundColor Yellow
}
Write-Host "Backups        : $globalBackup" -ForegroundColor Green
if ($repoExists) { Write-Host "                 $repoBackup" -ForegroundColor Green }
if ($WhatIf) { Write-Host 'WhatIf mode    : nothing was written' -ForegroundColor Cyan }
elseif ($ok) { Write-Host 'VALIDATION     : PASS - laguna=0, muse-spark 14 G / 1 R, big-pickle intact' -ForegroundColor Green }
else { Write-Host 'VALIDATION     : FAIL - inspect counts; restore from backups if needed.' -ForegroundColor Red }
Write-Host ''
Write-Host '      ***** RESTART OpenCode required *****' -ForegroundColor White -BackgroundColor Red
Write-Host '      Close all OpenCode sessions; config is loaded at startup.' -ForegroundColor Yellow

# 8. git diff --stat (only if inside a git work tree)
Write-Host "== git diff --stat ==" -ForegroundColor Cyan
try {
    $gitRoot = ([string](git -C $PSScriptRoot rev-parse --show-toplevel 2>$null)).Trim()
    if ($LASTEXITCODE -eq 0 -and $gitRoot -ne '') { git -C $gitRoot diff --stat -- opencode.json }
    else { Write-Host 'Not a git work tree - skipping diff.' -ForegroundColor DarkGray }
} catch {
    Write-Host 'git unavailable - skipping diff.' -ForegroundColor DarkGray
}

if (-not $ok -and -not $WhatIf) { exit 1 }
exit 0