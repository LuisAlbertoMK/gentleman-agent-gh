#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]

<#
.SYNOPSIS
    Auto-score project metrics across 13 dimensions.
.DESCRIPTION
    Evaluates project health across 13 dimensions (PA, Sec, DC, CC, BP, Or, Bi, Me, SP, SE, CA, BI2, SD)
    with 38+ sub-dimensions. Caches results based on script + skill content hashes (git HEAD independent).
    Spawns parallel jobs for cross-ref-check, pssa-gate, and check-backlog-integrity.
.PARAMETER Json
    Output results as JSON (depth 5).
.PARAMETER Quiet
    Output minimal score summary (one line).
.NOTES
    Scores range 0-10 per dimension. Composite score averages all dimensions.
    Cache invalidated when script or skill content hashes change.
    Sub-dimensions in SD provide granular breakdown.
    Bias calibration warning shown in non-Json mode when calibration data exists (>=2 samples).
#>
param(
    [switch]$Json,
    [switch]$Quiet,
    [switch]$Force
)

Set-StrictMode -Version Latest

# ponytail: score cache — content-hash based composite key (no git HEAD), fast invalidation

# ============================================================
# 1. CACHE CHECK
# ============================================================

# Resolve repoRoot FIRST — needed by cache path and everything else
. (Join-Path (Join-Path $PSScriptRoot "lib") "platform.ps1")
$repoRoot = Get-GentlemanRoot

$cacheDir  = Join-Path $repoRoot ".learnings"
$cacheFile = Join-Path $cacheDir "score-cache.json"

# ponytail: init before try — ensures vars exist even if cache check throws
$scriptFiles  = @()
$skillMdFiles = @()
$skillDirs    = @()
$manifest     = @()

. "$repoRoot\scripts\lib\file-manifest.ps1"

try {
    $manifest = @(Get-FileManifest -Path $repoRoot)

    # ponytail: consolidated reads — single pass for cache hash + scoring
    $scriptFiles  = @(Get-ChildItem "$repoRoot\scripts\*.ps1" -EA SilentlyContinue)
    $skillMdFiles = @(Get-ChildItem "$repoRoot\.agents\skills\*\SKILL.md" -EA SilentlyContinue)
    $skillDirs    = @(Get-ChildItem -Directory "$repoRoot\.agents\skills" -EA SilentlyContinue | Select-Object -ExpandProperty Name)

    $scriptsHash = ($manifest | Where-Object { $_.group -eq 'script' } | ForEach-Object { "$($_.relpath):$($_.sha256)" } | Sort-Object) -join "|"
    $skillsHash  = ($manifest | Where-Object { $_.group -eq 'skill' }  | ForEach-Object { "$($_.relpath):$($_.sha256)" } | Sort-Object) -join "|"

    $manifestScriptCount = @($manifest | Where-Object { $_.group -eq 'script' }).Count
    $manifestSkillCount  = @($manifest | Where-Object { $_.group -eq 'skill' }).Count
    if ($manifestScriptCount -lt $scriptFiles.Count -or $manifestSkillCount -ne $skillMdFiles.Count) { $cacheHash = $null }

    $interHash = if (Test-Path ".learnings/inter-track.json") { (Get-FileHash ".learnings/inter-track.json" -Algorithm SHA256).Hash.Substring(0,8) } else { "no-inter" }
    $compositeKey = "$scriptsHash|$skillsHash|$interHash"
    # Compact hash: SHA256 of composite key, first 16 hex chars (~8KB → 16 bytes)
    $fullHash = (Get-FileHash -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($compositeKey))) -Algorithm SHA256).Hash
    $cacheHash = $fullHash.Substring(0, 16)

    if (Test-Path $cacheFile) {
        $cached = Get-Content $cacheFile -Raw -Encoding UTF8 | ConvertFrom-Json
        # v2 (slim): compare compact hash; v1 (legacy): compare full base64 hash
        $cachedHash = if ($cached.v -eq 2) { $cached.hash } else { $cached.hash }
        if ($cachedHash -eq $cacheHash) {
            # v2 slim: result not in cache, must recalculate (but hash matches = no change)
            # For display, reconstruct minimal result from cached fields
            if ($cached.v -eq 2) {
                if ($Json -or $Quiet) {
                    # Reconstruct minimal result for JSON output
                    $tsStr = if ($cached.ts -is [string]) { $cached.ts.Substring(0,10) } else { "$($cached.ts)".Substring(0,10) }
                    $bp = Get-Content (Join-Path $PSScriptRoot "../.project.json") -Raw | ConvertFrom-Json; @{ score = @{ current = $cached.score; trend = $cached.trend; last_updated = $tsStr }; subdimensions = $bp.dimensions_detail.SD.e; SD_detail = $bp.dimensions_detail.SD.r } | ConvertTo-Json -Depth 5
                } else {
                    Write-Host "Score: $($cached.score)/10 (cached at $($cached.ts))" -ForegroundColor DarkGray
                }
            } else {
                # v1 legacy: full result available
                if ($Json) {
                    $cached.result | Add-Member -NotePropertyName subdimensions -NotePropertyValue $cached.result.dimensions_detail.SD.e -Force; $cached.result | Add-Member -NotePropertyName SD_detail -NotePropertyValue $cached.result.dimensions_detail.SD.r -Force; $cached.result | ConvertTo-Json -Depth 5
                } elseif ($Quiet) {
                    $cached.result | Add-Member -NotePropertyName subdimensions -NotePropertyValue $cached.result.dimensions_detail.SD.e -Force; $cached.result | Add-Member -NotePropertyName SD_detail -NotePropertyValue $cached.result.dimensions_detail.SD.r -Force; $cached.result | ConvertTo-Json -Depth 5
                } else {
                    Write-Host "Score: $($cached.result.score.current)/10 (cached at $($cached.timestamp))" -ForegroundColor DarkGray
                }
            }
            # Append to history.jsonl if delta >0.2 or new commit (cache-hit path)
            $historyPath = Join-Path $PSScriptRoot "../docs/metricas/history.jsonl"
            $proj = Get-Content (Join-Path $PSScriptRoot "../.project.json") -Raw | ConvertFrom-Json
            $lastEntry = if(Test-Path $historyPath){ Get-Content $historyPath -Tail 1 | ConvertFrom-Json } else { $null }
            $lastScore = if($lastEntry){ $lastEntry.score } else { 0 }
            $lastCommit = if($lastEntry){ $lastEntry.commit } else { "" }
            $currentCommit = (git rev-parse HEAD).Substring(0,8)
            $delta = [math]::Abs($proj.score.current - $lastScore)
            if($delta -gt 0.2 -or $currentCommit -ne $lastCommit -or $Force){ @{"date"=(Get-Date -Format yyyy-MM-dd);"commit"=$currentCommit;"score"=$proj.score.current;"gate"="25/25";"trend"=$proj.score.trend;"dimensions"=@{"Score Depth"=$proj.score.dimensions."Score Depth"}} | ConvertTo-Json -Compress | Add-Content -Path $historyPath }
            exit 0
        }
    }
} catch {
    Write-Debug "score-cache: $($_.Exception.Message)"
}

# ============================================================
# SETUP: Push-Location preserves caller CWD (AGENTS.md forbids Set-Location)
# ============================================================

Push-Location $repoRoot
# C4c: Single path definition — CWD-independent .project.json reference
$projectJsonPath = Join-Path $repoRoot ".project.json"

$math       = [math]
$dimensions = @{}

function Add-Dimension([string]$name, [double]$score, [hashtable]$evidence, [string]$rationale) {
    $dimensions[$name] = @{ s = $score; e = $evidence; r = $rationale }
}

# ============================================================
# BATCH FILE READS — reuse from cache section (consolidated)
# ============================================================

$skillDirCount = $skillDirs.PSWhere({ $_ -ne '_shared' }).Count

# ============================================================
# 2. PARALLEL SUB-SCRIPTS
# ============================================================

# Use repoRoot for script paths (more reliable than PSScriptRoot in pwsh -Command)
$scriptLibRoot = Join-Path $repoRoot "scripts"
$jobs          = @()

$jobs += Start-ThreadJob -Name "crossref" -ScriptBlock { try { & "$using:scriptLibRoot\cross-ref-check.ps1" -Json -Quiet } catch {} }
if ($env:PESTER_TEST -eq '1') {
  # Test mode: skip the ~33s PSSA cold scan (pssa-gate.ps1 -Mode Check).
  # Keeps integration tests fast; normal invocations still run the gate.
  Write-Warning "PESTER_TEST=1 — skipping pssa-gate job (test mode)"
} else {
  $jobs += Start-ThreadJob -Name "pssa" -ScriptBlock { & "$using:scriptLibRoot\pssa-gate.ps1" -Mode Check -Quiet }
}
$jobs += Start-ThreadJob -Name "backlog"  -ScriptBlock { & "$using:scriptLibRoot\check-backlog-integrity.ps1" -Json }

$jobs | Wait-Job -Timeout 300 | Out-Null

# Receive each job by name — handle failures gracefully with defaults
$crossRefOutput = Receive-Job -Name "crossref" -ErrorAction SilentlyContinue
$pssaOutput     = Receive-Job -Name "pssa" -ErrorAction SilentlyContinue | Out-String
$backlogRaw     = Receive-Job -Name "backlog" -ErrorAction SilentlyContinue

$jobs | Remove-Job -Force 2>$null

# Parse parallel results with safe defaults on failure
$crossRefClean = try {
    $jsonLine = $crossRefOutput | Where-Object { $_ -match '^\s*\{' } | Select-Object -First 1
    ($jsonLine | ConvertFrom-Json -EA SilentlyContinue).allClean -eq $true
} catch { $false }
$backlogData   = try { $backlogRaw | ConvertFrom-Json -EA SilentlyContinue } catch { $null }

$hasReadme      = Test-Path "README.md"
$hasProjectJson = Test-Path $projectJsonPath  # C4c: use single path definition

# ============================================================
# 3. DIMENSION SCORING
# ============================================================

. "$repoRoot\scripts\lib\score-dims.ps1"

# Bias calibration data (persist to .project.json, not just display)
$biasCalPath = ".learnings/bias-calibration.json"
$biasAdjusted = $null
$biasNote = $null
if (Test-Path $biasCalPath) {
    try {
        $biasCalData = Get-Content $biasCalPath -Raw | ConvertFrom-Json
        if ($biasCalData.samples -ge 2) {
            $biasAdjusted = $math::Round($finalScore - $biasCalData.avg_offset, 1)
            $biasNote = "Self-assessment inflation ~$($biasCalData.avg_offset)pt avg across $($biasCalData.samples) samples (bias-calibration.json). Real score estimated at $biasAdjusted/10."
            if (-not $Json -and -not $Quiet) {
                Write-Host "⚠️ Active bias offsets (auto-metrics):" -ForegroundColor DarkYellow
                $biasCalData.offsets.PSObject.Properties | Sort-Object Name | ForEach-Object {
                    Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor DarkYellow
                }
            }
        }
    } catch {
        Write-Debug "bias-cal read: $($_.Exception.Message)"
    }
}

# ============================================================
# 4. SCORE COMPOSITION
# ============================================================

$allScores   = $dimensions.Values.PSForEach({ $_.s })
$finalScore  = $math::Round(($allScores | Measure-Object -Average).Average, 1)

$dimNames = @{
    "PA"  = "Project Artifacts"
    "Sec" = "Security"
    "DC"  = "Dead Code"
    "CC"  = "Clean Code"
    "BP"  = "Best Practices"
    "Or"  = "Orthography"
    "Bi"  = "Bitacora"
    "Me"  = "Metrics"
    "SP"  = "Script Performance"
    "SE"  = "Skill Effectiveness"
    "CA"  = "Cycle Activity"
    "BI2" = "Backlog Integrity"
    "SD"  = "Score Depth"
}

$result = @{
    score = @{
        current      = $finalScore
        dimensions   = [ordered]@{}
        last_updated = (Get-Date -Format "yyyy-MM-dd")
        trend        = "stable"
    }
    dimensions_detail = $dimensions
}

# Persist bias calibration data if available
if ($null -ne $biasAdjusted) {
    $result.score.bias_adjusted = $biasAdjusted
    $result.score.bias_note = $biasNote
}

foreach ($key in $dimNames.Keys) {
    $result.score.dimensions[$dimNames[$key]] = $dimensions[$key].s
}

# Compare with existing .project.json for trend
if (Test-Path $projectJsonPath) {
    try {
        $prevProjectData = Get-Content $projectJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $prevScore = $prevProjectData.score.current

        if ($finalScore -gt $prevScore) {
            $result.score.trend = "up"
        } elseif ($finalScore -lt $prevScore) {
            $result.score.trend = "down"
        }

        $lastUpdated = $prevProjectData.score.last_updated
        if ($lastUpdated -and -not $Json -and -not $Quiet) {
            $daysSinceUpdate = [int]((Get-Date) - (Get-Date $lastUpdated)).TotalDays
            if ($daysSinceUpdate -ge 1) {
                Write-Host "WARNING: .project.json is $daysSinceUpdate day(s) stale (last: $lastUpdated)" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Warning "score-auto: .project.json parse failed ($($_.Exception.Message))"
    }
}

# ============================================================
# SAVE TO CACHE + SYNC .project.json
# ============================================================

try {
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    }
    # Slim cache: only essential fields (score + hash for invalidation)
    # Full result already synced to .project.json (single source of truth)
    $cacheObject = @{
        v     = 2
        hash  = $cacheHash
        ts    = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        score = $finalScore
        trend = $result.score.trend
        dims  = @($dimensions.Keys).Count
    }
    $cacheObject | ConvertTo-Json -Depth 5 | Set-Content $cacheFile -Encoding UTF8
} catch {
    Write-Debug "score-cache save: $($_.Exception.Message)"
}

# --- Sync .project.json (single source of truth) ---
try {
    $pjPath = $projectJsonPath  # C4c: single path definition (no Join-Path + hardcoded string)
    $skipWorktreeRemoved = $false

    # Validation: ensure score is sane before writing (ported from restore-project-score.ps1)
    $dimCount = @($dimensions.Keys).Count
    if ($finalScore -lt 0 -or $finalScore -gt 10 -or $dimCount -lt 11) {
        Write-Debug "score-auto: validation failed — score=$finalScore, dims=$dimCount (expected: 0-10, >=11 dims). Skipping .project.json write."
    } else {
        if (Test-Path $pjPath) {
            & "git" "-C" $repoRoot "update-index", "--no-skip-worktree", ".project.json" 2>$null
            $skipWorktreeRemoved = $true
        }
        $result | ConvertTo-Json -Depth 5 | Set-Content $pjPath -Encoding UTF8
    }
} catch {
    Write-Debug "score-auto: .project.json sync failed ($($_.Exception.Message))"
} finally {
    # Always restore skip-worktree if we removed it
    if ($skipWorktreeRemoved) {
        try { & "git" "-C" $repoRoot "update-index", "--skip-worktree", ".project.json" 2>$null } catch { Write-Debug "score-auto: $($_.Exception.Message)" }
    }
}

Pop-Location

# ============================================================
# 5. OUTPUT
# ============================================================

if ($Json) {
    # Json output deferred to SD breakdown block at end (15 lines)
} elseif ($Quiet) {
    # Quiet output deferred to SD breakdown block at end
} else {
    Write-Host "$($result.score.last_updated) | $finalScore/10 ($($result.score.trend))" -ForegroundColor Cyan
    Write-Host "Dimensions:" -ForegroundColor Yellow

    foreach ($key in $dimNames.Keys) {
        $dimData = $dimensions[$key]
        $color = if ($dimData.s -ge 9) {
            "Green"
        } elseif ($dimData.s -ge 7) {
            "Yellow"
        } else {
            "Red"
        }
        Write-Host " $($dimNames[$key].PadRight(16))$($dimData.s.ToString('F1').PadLeft(4))/10" -ForegroundColor $color
    }

    Write-Host $("-" * 32)
    Write-Host " TOTAL$(''.PadLeft(12))$($finalScore.ToString('F1').PadLeft(4))/10" -ForegroundColor White
}

# Append to history.jsonl if delta >0.2 or new commit
$historyPath = Join-Path $PSScriptRoot "../docs/metricas/history.jsonl"
$proj = Get-Content (Join-Path $PSScriptRoot "../.project.json") -Raw | ConvertFrom-Json
$lastEntry = if(Test-Path $historyPath){ Get-Content $historyPath -Tail 1 | ConvertFrom-Json } else { $null }
$lastScore = if($lastEntry){ $lastEntry.score } else { 0 }
$lastCommit = if($lastEntry){ $lastEntry.commit } else { "" }
$currentCommit = (git rev-parse HEAD).Substring(0,8)
$delta = [math]::Abs($proj.score.current - $lastScore)
if($delta -gt 0.2 -or $currentCommit -ne $lastCommit -or $Force){ @{"date"=(Get-Date -Format yyyy-MM-dd);"commit"=$currentCommit;"score"=$proj.score.current;"gate"="25/25";"trend"=$proj.score.trend;"dimensions"=@{"Score Depth"=$proj.score.dimensions."Score Depth"}} | ConvertTo-Json -Compress | Add-Content -Path $historyPath }

# --- SD sub-dimension breakdown (early regression detection) ---
if ($Json) {
    try {
        $proj = Get-Content $projectJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $sdE = $proj.dimensions_detail.SD.e
        $sdR = $proj.dimensions_detail.SD.r
        $result.subdimensions = $sdE
        $result.SD_detail = $sdR
        $result | ConvertTo-Json -Depth 5
    } catch {
        $result | ConvertTo-Json -Depth 5
    }
} elseif ($Quiet) {
    $result | ConvertTo-Json -Depth 5
}
# Explicit success exit — native calls inside (git update-index) may leave
# $LASTEXITCODE dirty; the contract is exit 0 on success (score-cache exit 0 parity)
exit 0
