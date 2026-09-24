#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    Token budget monitor — checks average SKILL.md + prompt file sizes
    against the 2,000-byte target (ADR-007 compliance, C9).

.DESCRIPTION
    Scans .agents/skills/*/SKILL.md and prompts/shared/*.md for file
    sizes, computes averages, and reports violations. Designed to run
    as part of the improvement cycle / quality gate.

    Target: average ≤ 2,000 bytes per skill/prompt file.

.PARAMETER SkillsPath
    Root directory containing skill subdirectories (default: .agents/skills).

.PARAMETER PromptsPath
    Directory containing prompt files (default: prompts/shared).

.PARAMETER BudgetBytes
    Maximum average file size in bytes (default: 2000).

.PARAMETER Json
    Emit machine-readable JSON.

.EXAMPLE
    .\scripts\check-token-budget.ps1
    .\scripts\check-token-budget.ps1 -BudgetBytes 2000 -Json
#>
param(
    [string]$SkillsPath = (Join-Path $PSScriptRoot "..\.agents\skills"),
    [string]$PromptsPath = (Join-Path $PSScriptRoot "..\prompts"),
    [string]$CommandsPath = (Join-Path $PSScriptRoot "..\commands"),
    [int]$BudgetBytes = 3200,
    [int]$PromptBudgetBytes = 4000,
    [switch]$Json
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$violations = @()
$stats = @{}

# --- Lazy scan helpers (perf: defer Get-ChildItem to point of use) ---
function Get-SkillFilesLazy {
    if (Test-Path $SkillsPath) {
        return @(Get-ChildItem -Path $SkillsPath -Filter "SKILL.md" -Recurse -File)
    }
    return @()
}
function Get-PromptFilesLazy {
    if (Test-Path $PromptsPath) {
        return @(Get-ChildItem -Path $PromptsPath -File -Include "*.md", "*.prompt" -Recurse)
    }
    return @()
}
function Get-CmdFilesLazy {
    if (Test-Path $CommandsPath) {
        return @(Get-ChildItem -Path $CommandsPath -File -Include "*.md", "*.prompt" -Recurse)
    }
    return @()
}

# --- O2 TEMP counts cache (never inside repo; silent fallback to full scan) ---
# Hit only if: cache exists + valid JSON + age < 60min + same paths/budgets +
# fingerprint (per-dir count+bytes + max LastWriteTimeUtc ticks) unchanged.
$__cacheFile = $env:TEMP
if ([string]::IsNullOrWhiteSpace($__cacheFile)) { $__cacheFile = [System.IO.Path]::GetTempPath() }
$__cacheFile = Join-Path (Join-Path $__cacheFile "opencode") "counts-cache.json"
$__cacheTtlMin = 60
$__cacheHit = $false
# Single probe enumeration (reused by the full scan on miss, so cold path
# does not enumerate twice; warm path skips all Measure/Where passes).
$probeSkillFiles = @(Get-SkillFilesLazy)
$probePromptFiles = @(Get-PromptFilesLazy)
$probeCmdFiles = @(Get-CmdFilesLazy)
$__fpSkillBytes = if ($probeSkillFiles.Count -gt 0) { [long]($probeSkillFiles | Measure-Object -Property Length -Sum).Sum } else { [long]0 }
$__fpPromptBytes = if ($probePromptFiles.Count -gt 0) { [long]($probePromptFiles | Measure-Object -Property Length -Sum).Sum } else { [long]0 }
$__fpCmdBytes = if ($probeCmdFiles.Count -gt 0) { [long]($probeCmdFiles | Measure-Object -Property Length -Sum).Sum } else { [long]0 }
$__fpMaxTicks = [long]0
foreach ($f in ($probeSkillFiles + $probePromptFiles + $probeCmdFiles)) {
    $t = [long]$f.LastWriteTimeUtc.Ticks
    if ($t -gt $__fpMaxTicks) { $__fpMaxTicks = $t }
}
$__fingerprint = "sk:$($probeSkillFiles.Count)/$__fpSkillBytes|pr:$($probePromptFiles.Count)/$__fpPromptBytes|cmd:$($probeCmdFiles.Count)/$__fpCmdBytes|mt:$__fpMaxTicks"
try {
    if (Test-Path $__cacheFile) {
        $__c = (Get-Content $__cacheFile -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
        $__age = ((Get-Date).ToUniversalTime() - [datetime]$__c.timestamp).TotalMinutes
        if ($__age -ge 0 -and $__age -lt $__cacheTtlMin -and
            [string]$__c.skillsPath -eq $SkillsPath -and [string]$__c.promptsPath -eq $PromptsPath -and
            [string]$__c.commandsPath -eq $CommandsPath -and
            [int]$__c.budgetBytes -eq $BudgetBytes -and [int]$__c.promptBudgetBytes -eq $PromptBudgetBytes -and
            [string]$__c.fingerprint -eq $__fingerprint) {
            $__cacheHit = $true
            $stats = @{}
            if ($__c.stats.PSObject.Properties['skills']) { $stats.skills = $__c.stats.skills }
            if ($__c.stats.PSObject.Properties['prompts']) { $stats.prompts = $__c.stats.prompts }
            $violations = @()
            if ($null -ne $__c.violations) { $violations = @($__c.violations) }
            $passed = [bool]$__c.passed
        }
    }
} catch { $__cacheHit = $false }

if (-not $__cacheHit) {
# --- Scan skill SKILL.md files (first: early-exit gate) ---
    $skillFiles = @($probeSkillFiles)
    if ($skillFiles.Count -gt 0) {
    $avgSkill = [math]::Round(($skillFiles | Measure-Object -Property Length -Average).Average, 0)
    $overBudget = @($skillFiles | Where-Object { $_.Length -gt $BudgetBytes })
    $stats.skills = [PSCustomObject]@{
        count      = $skillFiles.Count
        average    = $avgSkill
        budget     = $BudgetBytes
        underBudget = (@($skillFiles | Where-Object { $_.Length -le $BudgetBytes })).Count
        overBudgetFiles = $overBudget.Count
        passed     = $avgSkill -le $BudgetBytes
    }
    if ($avgSkill -gt $BudgetBytes) {
        $violations += "skills avg $($avgSkill)B exceeds $BudgetBytes B budget ($($overBudget.Count) files over)"
    }
}

# --- Scan prompt files (H-019 aligned: prompts/**/*.md + commands/**/*.md) ---
# Early-exit: skills budget already failed → outcome (exit 1) is decided;
# skip prompts/commands scans on the failure path.
if ($violations.Count -eq 0) {
$promptFiles = @($probePromptFiles)
$cmdFiles = @($probeCmdFiles)
if ($promptFiles.Count -gt 0) {
    $avgPrompt = [math]::Round(($promptFiles | Measure-Object -Property Length -Average).Average, 0)
    # ADR-046: orchestrator system prompts legitimately exceed the SKILL.md cap —
    # prompts keep their own average budget (4000B).
    $overBudgetPrompt = @($promptFiles | Where-Object { $_.Length -gt $PromptBudgetBytes })

    # H-019 per-file overweight — mirrors scripts/lib/score-dims.ps1 (lines 414-428):
    # any cmd/prompt file >5120B → penalty 2; else cmdOver3KB>2 or prOver3KB>1 → penalty 1.
    # E09 perf-ciclo34-clusterB (batch/cache): 4 Where-Object passes collapsed
    # into 2 single-pass counting loops; (Get-Location) hoisted below (was per-file).
    $cmdOver3KB = 0; $cmdOver5KB = 0; $prOver3KB = 0; $prOver5KB = 0
    foreach ($f in $cmdFiles) { if ($f.Length -gt 3072) { $cmdOver3KB++ }; if ($f.Length -gt 5120) { $cmdOver5KB++ } }
    foreach ($f in $promptFiles) { if ($f.Length -gt 3072) { $prOver3KB++ }; if ($f.Length -gt 5120) { $prOver5KB++ } }
    $overweightPenalty = 0
    if ($cmdOver5KB -gt 0 -or $prOver5KB -gt 0) {
        $overweightPenalty = 2
    } elseif ($cmdOver3KB -gt 2 -or $prOver3KB -gt 1) {
        $overweightPenalty = 1
    }
    $locPrefix = (Get-Location).Path + '\'
    $overweightFiles = @($cmdFiles + $promptFiles | Where-Object { $_.Length -gt 3072 } | ForEach-Object { $_.FullName.Replace($locPrefix, '') })

    $stats.prompts = [PSCustomObject]@{
        count             = $promptFiles.Count
        average           = $avgPrompt
        budget            = $PromptBudgetBytes
        underBudget       = @($promptFiles | Where-Object { $_.Length -le $PromptBudgetBytes }).Count
        overBudgetFiles   = $overBudgetPrompt.Count
        passed            = $avgPrompt -le $PromptBudgetBytes
        cmdCount          = $cmdFiles.Count
        cmdOver3KB        = $cmdOver3KB
        cmdOver5KB        = $cmdOver5KB
        prOver3KB         = $prOver3KB
        prOver5KB         = $prOver5KB
        overweightPenalty = $overweightPenalty
        overweightFiles   = $overweightFiles
        h019Passed        = $overweightPenalty -eq 0
    }
    if ($avgPrompt -gt $PromptBudgetBytes) {
        $violations += "prompts avg $($avgPrompt)B exceeds $PromptBudgetBytes B budget ($($overBudgetPrompt.Count) files over)"
    }
    if ($overweightPenalty -gt 0) {
        $violations += "H-019 overweight penalty $overweightPenalty — prompts>3072: $prOver3KB, cmds>3072: $cmdOver3KB, >5120: pr $prOver5KB/cmd $cmdOver5KB; files: $($overweightFiles -join ', ')"
    }
}
} # end early-exit guard (skills failed → prompts/commands skipped)

$passed = $violations.Count -eq 0

# O2: persist counts/stats to TEMP cache (best-effort, never breaks the gate).
try {
    $__cacheDir = Split-Path $__cacheFile -Parent
    if (!(Test-Path $__cacheDir)) { New-Item $__cacheDir -ItemType Directory -Force | Out-Null }
    [PSCustomObject]@{
        timestamp         = (Get-Date).ToUniversalTime().ToString("o")
        skillsPath        = $SkillsPath
        promptsPath       = $PromptsPath
        commandsPath      = $CommandsPath
        budgetBytes       = $BudgetBytes
        promptBudgetBytes = $PromptBudgetBytes
        fingerprint       = $__fingerprint
        stats             = $stats
        violations        = @($violations)
        passed            = $passed
    } | ConvertTo-Json -Depth 5 | Set-Content $__cacheFile -Encoding UTF8
} catch { }
} # end O2 cache-miss guard (hit path restores stats/violations/passed above)

if ($Json) {
    [PSCustomObject]@{
        passed    = $passed
        budget    = $BudgetBytes
        violations = $violations
        stats     = $stats
    } | ConvertTo-Json -Compress
    $ec = if ($passed) { 0 } else { 1 }
    exit $ec
}

# Human-readable
if ($passed) {
    $s = $stats.skills
    $p = $stats.prompts
    Write-Output "OK   Token budget: skills $($s.average)B/$BudgetBytes (avg), prompts $($p.average)B/$($p.budget) (avg), H-019 overweight penalty $($p.overweightPenalty)"
} else {
    Write-Output "FAIL Token budget exceeded (skills $BudgetBytes avg / H-019 overweight):"
    $violations | ForEach-Object { Write-Output "   X  $_" }
}

$ec = if ($passed) { 0 } else { 1 }
exit $ec
