#requires -Version 7.6

<#
.SYNOPSIS
    Dimension-scoring library for score-auto.ps1 — 13 metric dimensions.
.DESCRIPTION
    Dot-sourced by score-auto.ps1. Uses variables from the caller's scope
    ($math, $dimensions, $scriptFiles, $skillMdFiles, etc.) and calls
    Add-Dimension for each of the 13 dimensions.
.NOTES
    This file is NOT meant to be invoked directly.
#>

# Ensure $PSScriptRoot reflects the caller (score-auto.ps1) directory
if (-not $PSScriptRoot) { $scriptRoot = $PWD.Path } else { $scriptRoot = $PSScriptRoot }
# Use $scriptRoot for any relative paths

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
if ($totalScripts -lt 15 -or $totalScripts -gt 60) {
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
$subScores += $(if ($totalScripts -ge 15 -and $totalScripts -le 60) { 10 } else { 7 })
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
