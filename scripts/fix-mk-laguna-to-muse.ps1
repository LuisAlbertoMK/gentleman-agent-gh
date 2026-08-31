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
$globalBackup = Join-Path ([System.IO.Path]::GetDirectoryName($globalPath)) ([System.IO.Path]::GetFileName($globalPath) + '.bak-laguna-20260827')
$repoBackup = Join-Path ([System.IO.Path]::GetDirectoryName($repoPath)) ([System.IO.Path]::GetFileName($repoPath) + '.bak-laguna-20260827')
# Validate backup parents early (no traversal)
if ([System.IO.Path]::GetDirectoryName($globalBackup) -ne [System.IO.Path]::GetDirectoryName($globalPath)) { throw "Backup path traversal detected for globalBackup" }
if ([System.IO.Path]::GetDirectoryName($repoBackup) -ne [System.IO.Path]::GetDirectoryName($repoPath)) { throw "Backup path traversal detected for repoBackup" }
$lagunaPattern = 'opencode/laguna-s-2\.1-free'
$museSparkPattern = 'opencode/muse-spark-1\.2-contributor-free'
$bigPicklePattern = 'opencode/big-pickle'
$replacement = 'opencode/muse-spark-1.2-contributor-free'

# Helpers
function Get-Count {
    param([string]$Path, [string]$Pattern)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    try {
        $hits = Select-String -LiteralPath $Path -Pattern $Pattern -AllMatches -ErrorAction Stop
    } catch {
        Write-Host "WARN: Select-String failed for $Path : $_" -ForegroundColor Yellow
        return 0
    }
    if ($null -eq $hits) { return 0 }
    return [int](($hits | ForEach-Object { $_.Matches.Count } | Measure-Object -Sum).Sum)
}
function Test-JsonConfig {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        $obj = $raw | ConvertFrom-Json -Depth 10 -ErrorAction Stop
        if ($null -eq $obj) { throw "JSON null after parse: $Path" }
        $propCount = @($obj.PSObject.Properties).Count
        if ($propCount -eq 0) { throw "JSON schema validation failed: empty object in $Path" }
        $propNames = @($obj.PSObject.Properties | ForEach-Object { $_.Name })
        if ($Path -match 'opencode\.jsonc?$') {
            $hasAgent = $propNames -contains 'agent'
            $hasMcp = $propNames -contains 'mcp'
            $hasModel = $propNames -contains 'model'
            $hasDefaultAgent = $propNames -contains 'default_agent'
            if (-not ($hasAgent -or $hasMcp -or $hasModel -or $hasDefaultAgent)) {
                throw "JSON schema validation failed: expected agent/mcp/model/default_agent in $Path, got: $($propNames -join ',')"
            }
        }
        return $true
    } catch {
        return $false
    }
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
    $srcDir = [System.IO.Path]::GetDirectoryName($Source)
    $bakDir = [System.IO.Path]::GetDirectoryName($Backup)
    if ($bakDir -ne $srcDir) { throw "Backup path traversal detected: Backup parent '$bakDir' != source parent '$srcDir'" }
    $srcFile = [System.IO.Path]::GetFileName($Source)
    $bakFile = [System.IO.Path]::GetFileName($Backup)
    if (-not $bakFile.StartsWith($srcFile)) { throw "Backup filename validation failed: '$bakFile' does not start with '$srcFile'" }
    if (Test-Path -LiteralPath $Backup) { Write-Host "Backup already exists (kept): $Backup" -ForegroundColor DarkGray }
    elseif ($WhatIf) { Write-Host "[WhatIf] Would backup: $Backup" -ForegroundColor Cyan }
    else { Copy-Item -LiteralPath $Source -Destination $Backup; Write-Host "Backup created: $Backup" -ForegroundColor Green }
}
function Invoke-Migrate {
    param([string]$Path)
    # Get-Content -Raw + -replace; byte-preserving write (no BOM/newline) like Set-Content -NoNewline
    $content = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    $updated = $content -replace $lagunaPattern, $replacement
    if ($content -ceq $updated) { return $false }
    if ($WhatIf) { Write-Host "[WhatIf] Would rewrite: $Path" -ForegroundColor Cyan; return $false }
    $tmp = "$Path.tmp"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($tmp, $updated, $utf8NoBom)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
    # Verify hash/content post-move (atomic write check)
    $written = [System.IO.File]::ReadAllText($Path, $utf8NoBom)
    if ($written -cne $updated) {
        $expectedHash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($updated))).Replace('-','')
        $actualHash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
        if ($expectedHash -ne $actualHash) { throw "Atomic write verification failed: hash mismatch for $Path (expected $expectedHash, got $actualHash)" }
        throw "Atomic write verification failed: content mismatch after Move-Item for $Path"
    }
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
$globJsonOk = Test-JsonConfig $globalPath
Write-Host ('global json valid : {0}' -f $globJsonOk) -ForegroundColor Gray
if ($repoExists) {
    $repoLagunaA, $repoMuseA, $repoPickleA = Show-Counts 'repo' $repoPath
    $repoJsonOk = Test-JsonConfig $repoPath
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

# 8. git diff --stat (only if inside a git work tree) with timeout
Write-Host "== git diff --stat ==" -ForegroundColor Cyan
try {
    $job = Start-Job -ScriptBlock { git -C $using:PSScriptRoot rev-parse --show-toplevel 2>$null }
    $completed = Wait-Job -Job $job -Timeout 10
    if (-not $completed) {
        Stop-Job -Job $job | Out-Null
        Remove-Job -Job $job -Force | Out-Null
        Write-Host 'WARNING: git rev-parse timed out after 10s - skipping diff.' -ForegroundColor Yellow
    } else {
        $gitRoot = ([string](Receive-Job -Job $job)).Trim()
        Remove-Job -Job $job -Force | Out-Null
        if ($gitRoot -ne '') {
            $diffJob = Start-Job -ScriptBlock { git -C $using:gitRoot diff --stat -- opencode.json }
            $diffCompleted = Wait-Job -Job $diffJob -Timeout 10
            if (-not $diffCompleted) {
                Stop-Job -Job $diffJob | Out-Null
                Remove-Job -Job $diffJob -Force | Out-Null
                Write-Host 'WARNING: git diff timed out after 10s - skipping.' -ForegroundColor Yellow
            } else {
                $diffOut = Receive-Job -Job $diffJob
                Remove-Job -Job $diffJob -Force | Out-Null
                if ($diffOut) { $diffOut | Out-Host }
                else { Write-Host 'No diff or not a git work tree.' -ForegroundColor DarkGray }
            }
        } else {
            Write-Host 'Not a git work tree - skipping diff.' -ForegroundColor DarkGray
        }
    }
} catch {
    Write-Host 'git unavailable - skipping diff.' -ForegroundColor DarkGray
}

if (-not $ok -and -not $WhatIf) { exit 1 }
exit 0
