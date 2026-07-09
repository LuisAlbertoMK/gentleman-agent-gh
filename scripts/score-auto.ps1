#requires -Version 7.6

<#
.SYNOPSIS
    Auto-score project metrics across 13 dimensions.
.DESCRIPTION
    Evaluates project health across 13 dimensions (PA, Sec, DC, CC, BP, Or, Bi, Me, SP, SE, CA, BI2, SD)
    with 35+ sub-dimensions. Caches results based on git HEAD + script hashes + skill hashes.
    Spawns parallel jobs for cross-ref-check, pssa-gate, and check-backlog-integrity.
.PARAMETER Json
    Output results as JSON (depth 5).
.PARAMETER Quiet
    Output minimal score summary (one line).
.NOTES
    Scores range 0-10 per dimension. Composite score averages all dimensions.
    Cache invalidated when git HEAD, script sizes, or skill sizes change.
    Sub-dimensions in SD provide granular breakdown.
    Bias calibration warning shown in non-Json mode when calibration data exists (>=2 samples).
#>
param(
    [switch]$Json,
    [switch]$Quiet
)

Set-StrictMode -Version Latest

# ponytail: score cache — git-HEAD based composite hash, fast invalidation

# ============================================================
# 1. CACHE CHECK
# ============================================================

$cacheDir  = Join-Path "$PSScriptRoot\.." ".learnings"
$cacheFile = Join-Path $cacheDir "score-cache.json"

try {
    $repoRoot = "$PSScriptRoot\.."

    $gitHead = git -C $repoRoot rev-parse HEAD 2>$null

    $scriptsHash = (
        Get-ChildItem "$repoRoot\scripts\*.ps1" -EA SilentlyContinue |
            ForEach-Object { "$($_.Name):$($_.Length)" } |
            Sort-Object
    ) -join "|"

    $skillsHash = (
        Get-ChildItem "$repoRoot\.agents\skills\*\SKILL.md" -EA SilentlyContinue |
            ForEach-Object { "$($_.Name):$($_.Length)" } |
            Sort-Object
    ) -join "|"

    $compositeKey = "$gitHead|$scriptsHash|$skillsHash"
    $cacheHash    = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($compositeKey))

    if (Test-Path $cacheFile) {
        $cached = Get-Content $cacheFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cached.hash -eq $cacheHash) {
            if ($Json) {
                $cached.result | ConvertTo-Json -Depth 5
            } elseif ($Quiet) {
                $cached.result | ConvertTo-Json -Depth 5
            } else {
                Write-Host "Score: $($cached.result.score.current)/10 (cached at $($cached.timestamp))" -ForegroundColor DarkGray
            }
            exit 0
        }
    }
} catch {
    Write-Debug "score-cache: $($_.Exception.Message)"
}

# ============================================================
# SETUP: Push-Location preserves caller CWD (AGENTS.md forbids Set-Location)
# ============================================================

Push-Location "$PSScriptRoot\.."

& "$PSScriptRoot\restore-project-score.ps1" -Quiet 2>&1 | Out-Null

$math       = [math]
$dimensions = @{}

function Add-Dimension([string]$name, [double]$score, [hashtable]$evidence, [string]$rationale) {
    $dimensions[$name] = @{ s = $score; e = $evidence; r = $rationale }
}

# ============================================================
# BATCH FILE READS — cache Get-ChildItem results
# ============================================================

$skillDirs    = Get-ChildItem -Directory ".\.agents\skills" -Name
$skillMdFiles = Get-ChildItem ".\.agents\skills\*\SKILL.md" -EA SilentlyContinue
$scriptFiles  = Get-ChildItem ".\scripts\*.ps1" -EA SilentlyContinue

$skillDirCount = $skillDirs.PSWhere({ $_ -ne '_shared' }).Count

# ============================================================
# 2. PARALLEL SUB-SCRIPTS
# ============================================================

$scriptRoot = $PSScriptRoot
$jobs       = @()

$jobs += Start-Job -Name "crossref"  -ScriptBlock { & "$using:scriptRoot\cross-ref-check.ps1" -Json -Quiet }
$jobs += Start-Job -Name "pssa"     -ScriptBlock { & "$using:scriptRoot\pssa-gate.ps1" -Mode Check -Quiet }
$jobs += Start-Job -Name "backlog"  -ScriptBlock { & "$using:scriptRoot\check-backlog-integrity.ps1" -Json }

$jobs | Wait-Job -Timeout 30 | Out-Null

# Receive each job by name (order-safe)
$crossRefOutput = Receive-Job -Name "crossref" -ErrorAction SilentlyContinue
$pssaOutput     = Receive-Job -Name "pssa" -ErrorAction SilentlyContinue | Out-String
$backlogRaw     = Receive-Job -Name "backlog" -ErrorAction SilentlyContinue

$jobs | Remove-Job -Force 2>$null

# Parse parallel results
$crossRefClean = ($crossRefOutput | ConvertFrom-Json -EA SilentlyContinue).allClean -eq $true
$backlogData   = $backlogRaw | ConvertFrom-Json -EA SilentlyContinue

$hasReadme      = Test-Path "README.md"
$hasProjectJson = Test-Path ".project.json"

# ============================================================
# 3. DIMENSION SCORING
# ============================================================

. "$PSScriptRoot\lib\score-dims.ps1"

# Bias calibration warning (auto-metrics correction, not project score)
$biasCalPath = ".learnings/bias-calibration.json"
if (-not $Json -and -not $Quiet -and (Test-Path $biasCalPath)) {
    try {
        $biasCalData = Get-Content $biasCalPath -Raw | ConvertFrom-Json
        if ($biasCalData.samples -ge 2) {
            Write-Host "⚠️ Active bias offsets (auto-metrics):" -ForegroundColor DarkYellow
            $biasCalData.offsets.PSObject.Properties | Sort-Object Name | ForEach-Object {
                Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor DarkYellow
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

foreach ($key in $dimNames.Keys) {
    $result.score.dimensions[$dimNames[$key]] = $dimensions[$key].s
}

# Compare with existing .project.json for trend
if (Test-Path ".project.json") {
    try {
        $prevProjectData = Get-Content ".project.json" -Raw -Encoding UTF8 | ConvertFrom-Json
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
# SAVE TO CACHE
# ============================================================

try {
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    }
    $cacheObject = @{
        hash      = $cacheHash
        timestamp = (Get-Date -Format "o")
        result    = $result
    }
    $cacheObject | ConvertTo-Json -Depth 5 | Set-Content $cacheFile -Encoding UTF8
} catch {
    Write-Debug "score-cache save: $($_.Exception.Message)"
}

Pop-Location

# ============================================================
# 5. OUTPUT
# ============================================================

if ($Json) {
    $result | ConvertTo-Json -Depth 5
} elseif ($Quiet) {
    $result | ConvertTo-Json -Depth 5
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