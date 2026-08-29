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
    [int]$BudgetBytes = 2000,
    [int]$PromptBudgetBytes = 4000,
    [switch]$Json
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$violations = @()
$stats = @{}

# --- Scan skill SKILL.md files ---
    $skillFiles = @()
    if (Test-Path $SkillsPath) {
        $skillFiles = @(Get-ChildItem -Path $SkillsPath -Filter "SKILL.md" -Recurse -File)
    }
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
$promptFiles = @()
if (Test-Path $PromptsPath) {
    $promptFiles = @(Get-ChildItem -Path $PromptsPath -File -Include "*.md", "*.prompt" -Recurse)
}
$cmdFiles = @()
if (Test-Path $CommandsPath) {
    $cmdFiles = @(Get-ChildItem -Path $CommandsPath -File -Include "*.md", "*.prompt" -Recurse)
}
if ($promptFiles.Count -gt 0) {
    $avgPrompt = [math]::Round(($promptFiles | Measure-Object -Property Length -Average).Average, 0)
    # ADR-046: orchestrator system prompts legitimately exceed the SKILL.md cap —
    # prompts keep their own average budget (4000B).
    $overBudgetPrompt = @($promptFiles | Where-Object { $_.Length -gt $PromptBudgetBytes })

    # H-019 per-file overweight — mirrors scripts/lib/score-dims.ps1 (lines 414-428):
    # any cmd/prompt file >5120B → penalty 2; else cmdOver3KB>2 or prOver3KB>1 → penalty 1.
    $cmdOver3KB = @($cmdFiles | Where-Object { $_.Length -gt 3072 }).Count
    $cmdOver5KB = @($cmdFiles | Where-Object { $_.Length -gt 5120 }).Count
    $prOver3KB  = @($promptFiles | Where-Object { $_.Length -gt 3072 }).Count
    $prOver5KB  = @($promptFiles | Where-Object { $_.Length -gt 5120 }).Count
    $overweightPenalty = 0
    if ($cmdOver5KB -gt 0 -or $prOver5KB -gt 0) {
        $overweightPenalty = 2
    } elseif ($cmdOver3KB -gt 2 -or $prOver3KB -gt 1) {
        $overweightPenalty = 1
    }
    $overweightFiles = @($cmdFiles + $promptFiles | Where-Object { $_.Length -gt 3072 } | ForEach-Object { $_.FullName.Replace((Get-Location).Path + '\', '') })

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

$passed = $violations.Count -eq 0

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
