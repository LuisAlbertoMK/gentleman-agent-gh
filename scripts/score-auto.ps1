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
                Write-Host "Score: $($cached.result.score.current)/10 (trend: $($cached.result.score.trend)) [cached]"
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

# --- PA: Project Artifacts ---

$paScore = 10
if (-not $crossRefClean)   { $paScore -= 2 }
if (-not $hasReadme)       { $paScore -= 2 }
if ($skillDirCount -lt 60) { $paScore -= 2 }
if (-not $hasProjectJson)  { $paScore -= 1 }

Add-Dimension "PA" ($math::Max(0, $paScore)) @{
    skills       = $skillDirCount
    cross_ref    = $crossRefClean
    readme       = $hasReadme
    project_json = $hasProjectJson
} "X-ref $crossRefClean, $skillDirCount skills"

# --- Sec: Security ---

$secScore      = 10
$hasWeakCrypto = $false
$hasSecrets    = $false

# Check for weak crypto patterns in scripts
$weakCryptoMatches = @(
    Select-String -Path $scriptFiles.FullName -Pattern "MD5|SHA1\b"
).PSWhere({
    $_.Line -notmatch "SHA1ToSHA256|SHA256|#deprecat|#legacy|SHA1SHA256|Select-String.*MD5"
})

if ($weakCryptoMatches) {
    $hasWeakCrypto = $true
    $secScore -= 2
}

# Check for hardcoded secrets across scripts, skills, workflows, config
$secretPaths = $scriptFiles.FullName +
               $skillMdFiles.FullName +
               @(".\.github\workflows\*.yml", ".\opencode.json")

$secretMatches = @(Select-String -Path $secretPaths -Pattern "(?i)(api[_-]?key|secret|password|token|credential)\s*[=:]\s*['""][^'""]{8,}")

if ($secretMatches) {
    $hasSecrets = $true
    $secScore -= 3
}

# Check latest error log or pssa output
$errorLogPath = "docs/metricas/errors/LATEST_error.json"
if (Test-Path $errorLogPath) {
    $errorLog = Get-Content $errorLogPath -Raw | ConvertFrom-Json
    if ($errorLog.source -ne "quality-gate" -or $errorLog.passed -lt 5) {
        $secScore -= 1
    }
} else {
    if ($pssaOutput -match "FAIL|violation|security") {
        $secScore -= 1
    }
}

Add-Dimension "Sec" ($math::Max(0, $math::Min(10, $secScore))) @{
    weak_crypto = $hasWeakCrypto
    secrets     = $hasSecrets
} "Weak crypto: $hasWeakCrypto, secrets: $hasSecrets"

# --- DC: Dead Code ---

$dcScore       = 10
$orphanSkills  = 0
$deadJunctions = 0

# Orphan skills (files in .\skills not matching .\.agents\skills\ dirs)
$skillFilesInWorkspace = Get-ChildItem ".\skills" -File -EA SilentlyContinue
$orphanSkills = $skillFilesInWorkspace.PSWhere({ $_.Name -notin $skillDirs }).Count

if ($orphanSkills -gt 5) {
    $dcScore -= 2
} elseif ($orphanSkills -gt 0) {
    $dcScore -= 1
}

# Dead junctions (symlinks pointing to missing targets)
$junctionDirs   = Get-ChildItem ".\skills" -Directory -EA SilentlyContinue
$deadJunctions  = $junctionDirs.PSWhere({ $_.Target -and -not (Test-Path $_.Target) }).Count

if ($deadJunctions -gt 0) {
    $dcScore -= 1
}

# Commented-out code patterns in scripts (exclude this file)
$commentedPatterns = @(
    Select-String -Path $scriptFiles.FullName -Pattern (
        '^\s*#\s*function\s+\w+|^\s*#\s*if\s*\(|^\s*#\s*foreach\s*\(|' +
        '^\s*#\s*for\s*\(|^\s*#\s*while\s*\(|^\s*#\s*switch\s*\(|' +
        '^\s*#\s*try\s*\{|^\s*#\s*catch\s*\{'
    )
).PSWhere({ $_.Filename -ne "score-auto.ps1" })

$commentedLines = $commentedPatterns.Count

if ($commentedLines -gt 10) {
    $dcScore -= 1
}

Add-Dimension "DC" ($math::Max(0, $math::Min(10, $dcScore))) @{
    orphans        = $orphanSkills
    dead_junctions = $deadJunctions
    commented_out  = $commentedLines
} "Orphans: $orphanSkills, dead junctions: $deadJunctions"

# --- CC: Clean Code — parallel script structure analysis ---

$totalScripts = $scriptFiles.Count

$scriptStats = $scriptFiles | ForEach-Object -Parallel {
    $content = [IO.File]::ReadAllText($_.FullName)
    [PSCustomObject]@{
        h = [bool]($content -match '<#')
        p = [bool]($content -match 'param\(')
        s = [bool]($content -match 'Set-StrictMode')
        t = [bool]($content -match 'try\s*\{')
    }
} -ThrottleLimit 7

$scriptsWithHelp       = @($scriptStats | Where-Object { $_.h }).Count
$scriptsWithParams     = @($scriptStats | Where-Object { $_.p }).Count
$scriptsWithStrictMode = @($scriptStats | Where-Object { $_.s }).Count
$scriptsWithTryCatch   = @($scriptStats | Where-Object { $_.t }).Count

$helpRatio       = $math::Round($scriptsWithHelp / $totalScripts, 2)
$paramRatio      = $math::Round($scriptsWithParams / $totalScripts, 2)
$strictModeRatio = $math::Round($scriptsWithStrictMode / $totalScripts, 2)

$ccScore = $math::Round(
    ($helpRatio + $paramRatio + $strictModeRatio) / 3 * 10,
    1
)

Add-Dimension "CC" $ccScore @{
    total_scripts  = $totalScripts
    with_help      = $scriptsWithHelp
    with_params    = $scriptsWithParams
    with_strictmode = $scriptsWithStrictMode
} "S:$totalScripts H:$scriptsWithHelp P:$scriptsWithParams S:$scriptsWithStrictMode"

# --- BP: Best Practices ---

$bpScore = $math::Round(($scriptsWithParams / $totalScripts) * 10, 1)

$tryCatchRatio = $scriptsWithTryCatch / $totalScripts
if ($tryCatchRatio -ge 0.8) {
    $bpScore = $math::Min(10, $bpScore + 1)
} elseif ($tryCatchRatio -le 0.3) {
    $bpScore = $math::Max(0, $bpScore - 1)
}

Add-Dimension "BP" $bpScore @{
    param_cov = $scriptsWithParams
    trycatch  = $scriptsWithTryCatch
} "P:$scriptsWithParams/$totalScripts T:$scriptsWithTryCatch/$totalScripts"

# --- Or: Orthography / corruption detection ---

$corruptedFiles = @(
    $skillMdFiles | ForEach-Object -Parallel {
        $file = $_
        try {
            $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
            for ($i = 0; $i -lt $bytes.Length - 3; $i++) {
                # Check for double-encoded UTF-8 (mojibake) patterns
                if ($bytes[$i] -eq 0xC3 -and $bytes[$i + 1] -eq 0x83 -and $bytes[$i + 2] -ge 0x80) {
                    $true; return
                }
                if ($bytes[$i] -eq 0xC3 -and $bytes[$i + 1] -eq 0xA2 -and
                    $i + 2 -lt $bytes.Length -and $bytes[$i + 2] -eq 0xE2 -and
                    ($bytes[$i + 3] -eq 0x80 -or $bytes[$i + 3] -eq 0x82)) {
                    $true; return
                }
            }
            return $false
        } catch {
            $false
        }
    } -ThrottleLimit 4 | Where-Object { $_ }
).Count

if ($corruptedFiles -gt 10) {
    $orScore = 4
} elseif ($corruptedFiles -gt 5) {
    $orScore = 7
} elseif ($corruptedFiles -gt 0) {
    $orScore = 9
} else {
    $orScore = 10
}

Add-Dimension "Or" $orScore @{
    corrupted = $corruptedFiles
    scanned   = $skillMdFiles.Count
} "Corruption: $corruptedFiles/$($skillMdFiles.Count)"

# --- Bi: Bitacora ---

$bitacoraExists = Test-Path "BITACORA.md"
$bitacoraContent = $null
$bitacoraLines   = 0

if ($bitacoraExists) {
    $bitacoraContent = Get-Content "BITACORA.md" -Raw
    $bitacoraLines   = $bitacoraContent.Split("`n").Count
}

if ($bitacoraLines -gt 10) {
    $biScore = 10
} elseif ($bitacoraLines -gt 5) {
    $biScore = 7
} elseif ($bitacoraExists) {
    $biScore = 5
} else {
    $biScore = 0
}

Add-Dimension "Bi" $biScore @{
    exists = $bitacoraExists
    lines  = if ($bitacoraExists -and ($null -ne $bitacoraContent)) { $bitacoraLines } else { 0 }
} "BI: $bitacoraExists"

# --- Me: Metrics ---

$hasMetricsDir = Test-Path "docs/metricas"
$hasErrorsDir  = Test-Path "docs/metricas/errors"
$hasErrorJson  = Test-Path "docs/metricas/errors/LATEST_error.json"
$hasReports    = (Get-ChildItem "docs/metricas" -File -EA SilentlyContinue).Count -gt 0

$meScore = 4
if ($hasMetricsDir -and $hasErrorJson) {
    $meScore = 9
} elseif ($hasMetricsDir) {
    $meScore = 7
}
if ($hasReports -and $hasErrorsDir) {
    $meScore = $math::Min(10, $meScore + 1)
}

Add-Dimension "Me" $meScore @{
    md = $hasMetricsDir
    ed = $hasErrorsDir
    ej = $hasErrorJson
    rp = $hasReports
} "MD:$hasMetricsDir EJ:$hasErrorJson"

# --- SP: Script Performance ---

$avgScriptSizeKB = $math::Round(
    ($scriptFiles | Measure-Object -Average Length).Average / 1KB,
    1
)
$hugeScriptCount = $scriptFiles.PSWhere({ $_.Length -gt 51200 }).Count

$spScore = 10
if ($totalScripts -lt 15 -or $totalScripts -gt 50) {
    $spScore -= 1
}
# Note: condition order matters — >15 checked first, >20 uses elseif
if ($avgScriptSizeKB -gt 15) {
    $spScore -= 1
} elseif ($avgScriptSizeKB -gt 20) {
    $spScore -= 2
}
if ($hugeScriptCount -gt 0) {
    $spScore -= 2
}

Add-Dimension "SP" ($math::Max(0, $math::Min(10, $spScore))) @{
    sc   = $totalScripts
    avg  = $avgScriptSizeKB
    huge = $hugeScriptCount
} "S:$totalScripts avg:${avgScriptSizeKB}KB"

# --- SE: Skill Effectiveness ---

$skillsNonShared = $skillMdFiles.PSWhere({ $_.Directory.Name -ne '_shared' })
$totalSkills     = $skillsNonShared.Count
$over3KBSkills   = $skillsNonShared.PSWhere({ $_.Length -gt 3072 }).Count
$over5KBSkills   = $skillsNonShared.PSWhere({ $_.Length -gt 5120 }).Count
$totalSkillBytes = ($skillsNonShared | Measure-Object -Sum Length).Sum
$avgSkillSizeKB  = $math::Round($totalSkillBytes / $totalSkills / 1KB, 1)

# Extend overweight check to commands/ + prompts/ (H-019)
$cmdFiles    = Get-ChildItem "commands\*.md" -EA SilentlyContinue
$promptFiles = Get-ChildItem "prompts" -Recurse -File -EA SilentlyContinue

$cmdOver3KB  = $cmdFiles.PSWhere({ $_.Length -gt 3072 }).Count
$cmdOver5KB  = $cmdFiles.PSWhere({ $_.Length -gt 5120 }).Count
$prOver3KB   = $promptFiles.PSWhere({ $_.Length -gt 3072 }).Count
$prOver5KB   = $promptFiles.PSWhere({ $_.Length -gt 5120 }).Count

$overweightPenalty = 0
if ($cmdOver5KB -gt 0 -or $prOver5KB -gt 0) {
    $overweightPenalty = 2
} elseif ($cmdOver3KB -gt 2 -or $prOver3KB -gt 1) {
    $overweightPenalty = 1
}

$seScore = 10
if ($over5KBSkills -gt 0) {
    $seScore -= 2
} elseif ($over3KBSkills -gt 3) {
    $seScore -= 2
} elseif ($over3KBSkills -gt 1) {
    $seScore -= 1
}
$seScore -= $overweightPenalty

if ($avgSkillSizeKB -le 2.5) {
    $seScore = $math::Min(10, $seScore + 0.5)
}
if ($totalSkills -lt 60) {
    $seScore -= 2
}

Add-Dimension "SE" ($math::Round($math::Max(0, $math::Min(10, $seScore)), 1)) @{
    total  = $totalSkills
    o3     = $over3KBSkills
    o5     = $over5KBSkills
    avg    = $avgSkillSizeKB
    bytes  = $totalSkillBytes
    cmdO3  = $cmdOver3KB
    cmdO5  = $cmdOver5KB
    prO3   = $prOver3KB
    prO5   = $prOver5KB
} "T:$totalSkills >3:$over3KBSkills >5:$over5KBSkills avg:${avgSkillSizeKB}KB cmdO3:$cmdOver3KB cmdO5:$cmdOver5KB prO3:$prOver3KB prO5:$prOver5KB"

# --- CA: Cycle Activity ---

$interTrackPath = ".learnings\inter-track.json"
$cycleCount     = 0
$cycleTarget    = 30
$cycleScore     = 0

if (Test-Path $interTrackPath) {
    try {
        $interTrack = Get-Content $interTrackPath -Raw | ConvertFrom-Json
        $cycleCount  = [int]$interTrack.cycle.count
        $cycleTarget = [int]$interTrack.cycle.target
        $cycleScore  = $math::Min(10, $math::Round(($cycleCount / $cycleTarget) * 10, 1))
    } catch {
        $cycleScore = 0
    }
}

Add-Dimension "CA" $cycleScore @{
    ic = $cycleCount
    it = $cycleTarget
} "IC:$cycleCount/$cycleTarget"

# --- BI2: Backlog Integrity ---

if ($backlogData) {
    $backlogScore      = $backlogData.score
    $backlogPassed     = $backlogData.passed
    $backlogTotalItems = $backlogData.totalItems
} else {
    $backlogScore      = 0
    $backlogPassed     = 0
    $backlogTotalItems = 0
}

Add-Dimension "BI2" $backlogScore @{
    passed = $backlogPassed
    total  = $backlogTotalItems
} "$backlogPassed/$backlogTotalItems items"

# --- SD: Score Depth (35+ sub-dimensions) ---

# Compute new sub-dimension values
# Tool Hygiene: % scripts with Quiet/Json switches
$quietSwitchCount = @($scriptFiles | ForEach-Object -Parallel {
    $content = [IO.File]::ReadAllText($_.FullName)
    if ($content -match '\[switch\]\$Quiet|\[switch\]\$Json') { $true } else { $false }
} | Where-Object { $_ }).Count
$toolHygieneScore = $math::Round($quietSwitchCount / $totalScripts * 10, 1)

# Delegation Rate: subagent mentions in BITACORA (last 30 lines)
$delegationScore = 0
if ($bitacoraContent) {
    $recentLines = ($bitacoraContent -split "`n")[-30..-1] -join "`n"
    $subagentMentions = [regex]::Matches($recentLines, 'subagent|subagente|explore|parallel').Count
    $delegationScore = $math::Min(10, $math::Round($subagentMentions, 0))
}

# Gate Pass Rate: from capture-errors quality-gate data
$gatePassRate = $null
$gatePassScore = 0
$latErrorPath = "docs/metricas/errors/LATEST_error.json"
if (Test-Path $latErrorPath) {
    try {
        $latError = Get-Content $latErrorPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($latError.source -eq "quality-gate" -and $latError.total -gt 0) {
            $gatePassRate = $latError.passed / $latError.total
            $gatePassScore = $math::Round($gatePassRate * 10, 1)
        } elseif ($latError.passed -ge 5) {
            $gatePassScore = 10
        }
    } catch { $gatePassScore = 0 }
}

# Cross-Ref Freshness: when was .project.json last updated
$crossRefFreshScore = 10
$pjPath = ".project.json"
if (Test-Path $pjPath) {
    $pjAge = [int]((Get-Date) - (Get-Item $pjPath).LastWriteTime).TotalDays
    if ($pjAge -gt 7)  { $crossRefFreshScore = 5 }
    elseif ($pjAge -gt 3) { $crossRefFreshScore = 7 }
    elseif ($pjAge -gt 1) { $crossRefFreshScore = 9 }
}

# Audit Freshness: days since last "audit" entry in BITACORA
$auditFreshScore = 10
if ($bitacoraContent) {
    $auditDates = @([regex]::Matches($bitacoraContent, '(\d{4}-\d{2}-\d{2}).*audit|\[audit\]', 'Multiline') | ForEach-Object {
        try { [datetime]::ParseExact($_.Groups[1].Value, 'yyyy-MM-dd', $null) } catch { $null }
    })
    if ($auditDates.Count -gt 0) {
        $lastAudit = ($auditDates | Sort-Object -Descending)[0]
        $auditDays = [int]((Get-Date) - $lastAudit).TotalDays
        if ($auditDays -gt 14) { $auditFreshScore = 4 }
        elseif ($auditDays -gt 7)  { $auditFreshScore = 7 }
        elseif ($auditDays -gt 1)  { $auditFreshScore = 9 }
    }
}

$subScores = @()

# Project Artifacts sub-dimensions
$paEvidence = $dimensions["PA"].e
$subScores += $(if ($paEvidence.readme) { 10 } else { 0 })
$subScores += $(if ($paEvidence.cross_ref) { 10 } else { 0 })
$subScores += $math::Min(10, $paEvidence.skills / 6)
$subScores += $(if ($paEvidence.project_json) { 10 } else { 0 })

# Security sub-dimensions
$secEvidence = $dimensions["Sec"].e
$subScores += $(if ($secEvidence.weak_crypto) { 5 } else { 10 })
$subScores += $(if ($secEvidence.secrets) { 3 } else { 10 })

# Dead Code sub-dimensions
$dcEvidence = $dimensions["DC"].e
$subScores += $(if ($dcEvidence.orphans -le 0) { 10 } elseif ($dcEvidence.orphans -le 5) { 7 } else { 5 })
$subScores += $(if ($dcEvidence.dead_junctions -le 0) { 10 } else { 7 })
$subScores += $(if ($dcEvidence.commented_out -le 10) { 10 } else { 7 })

# Clean Code sub-dimensions
$ccEvidence = $dimensions["CC"].e
$subScores += $math::Round($ccEvidence.with_help / $totalScripts * 10, 1)
$subScores += $math::Round($ccEvidence.with_params / $totalScripts * 10, 1)
$subScores += $math::Round($ccEvidence.with_strictmode / $totalScripts * 10, 1)

# Best Practices sub-dimensions
$bpEvidence = $dimensions["BP"].e
$subScores += $math::Round($bpEvidence.param_cov / $totalScripts * 10, 1)
$subScores += $math::Round($bpEvidence.trycatch / $totalScripts * 10, 1)

# Orthography sub-dimension
$subScores += $(if ($corruptedFiles -le 0) { 10 } elseif ($corruptedFiles -le 5) { 9 } elseif ($corruptedFiles -le 10) { 7 } else { 4 })

# Bitacora sub-dimensions
$biEvidence = $dimensions["Bi"].e
$subScores += $(if ($biEvidence.exists) { 10 } else { 0 })
$subScores += $math::Min(10, $biEvidence.lines / 2)

# Metrics sub-dimensions
$subScores += $(if ($hasMetricsDir) { 10 } else { 0 })
$subScores += $(if ($hasErrorsDir) { 10 } else { 0 })
$subScores += $(if ($hasErrorJson) { 10 } else { 0 })
$subScores += $(if ($hasReports) { 10 } else { 0 })

# Script Performance sub-dimensions
$subScores += $(if ($totalScripts -ge 15 -and $totalScripts -le 50) { 10 } else { 7 })
$subScores += $(if ($avgScriptSizeKB -le 10) { 10 } elseif ($avgScriptSizeKB -le 15) { 7 } else { 5 })
$subScores += $(if ($hugeScriptCount -le 0) { 10 } else { 5 })

# Skill Effectiveness sub-dimensions
$subScores += $(if ($totalSkills -ge 60) { 10 } else { 7 })
$subScores += $(if ($over3KBSkills -le 0) { 10 } elseif ($over3KBSkills -le 1) { 9 } else { 7 })
$subScores += $(if ($over5KBSkills -le 0) { 10 } else { 7 })
$subScores += $(if ($avgSkillSizeKB -le 2.0) { 10 } elseif ($avgSkillSizeKB -le 2.5) { 9.5 } else { 7 })

# Cycle Activity sub-dimension
$subScores += $math::Min(10, $cycleCount / $cycleTarget * 10)

# Backlog Integrity sub-dimension
$subScores += $(if ($backlogTotalItems -gt 0) { $backlogPassed / $backlogTotalItems * 10 } else { 0 })

# Tool Hygiene sub-dimension
$subScores += $toolHygieneScore
# Delegation Rate sub-dimension
$subScores += $delegationScore
# Gate Pass Rate sub-dimension
$subScores += $gatePassScore
# Cross-Ref Freshness sub-dimension
$subScores += $crossRefFreshScore
# Audit Freshness sub-dimension
$subScores += $auditFreshScore

# ponytail: 35 sub-dims total (30 base + 5 new)
$depthScore = ($subScores | Measure-Object -Average).Average
if ($depthScore -is [double]) {
    $depthScore = $math::Round($depthScore, 1)
}

Add-Dimension "SD" $depthScore @{
    subd = $subScores.Count
} "Depth: $($subScores.Count) sub-dims: $depthScore/10"

# Bias calibration warning (auto-metrics correction, not project score)
$biasCalPath = ".learnings/bias-calibration.json"
if (-not $Json -and (Test-Path $biasCalPath)) {
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
        if ($lastUpdated -and -not $Json) {
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
    Write-Host "Score: $finalScore/10 (trend: $($result.score.trend))"
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