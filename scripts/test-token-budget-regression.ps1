#requires -Version 7
[CmdletBinding()]
<#
.SYNOPSIS
    Pattern 3 — Token Budget Regression check.

.DESCRIPTION
    Reads `token_budget` frontmatter from each .agents/skills/*/SKILL.md and
    asserts the current file size does not exceed the declared budget by more
    than the drift threshold (default 10%). Skills WITHOUT a token_budget
    frontmatter are reported as "unbudgeted" (non-blocking warning, since not
    all skills declare budgets yet).

    This is the enforcement engine for the frontmatter `token_budget` field
    (skill-testing Pattern 3: Token Budget Regression). Without this runner,
    the frontmatter field is metadata with no enforcement.

.PARAMETER SkillsPath
    Root containing skill subdirectories (default: .agents/skills).

.PARAMETER DriftThreshold
    Allowed growth ratio (default: 1.1 = 10% over budget). Files exceeding
    budget * threshold are FAIL violations.

.PARAMETER Json
    Emit machine-readable JSON.

.EXAMPLE
    scripts\test-token-budget-regression.ps1
    scripts\test-token-budget-regression.ps1 -DriftThreshold 1.05 -Json
#>
param(
    [string]$SkillsPath = (Join-Path $PSScriptRoot "..\.agents\skills"),
    [double]$DriftThreshold = 1.1,
    [switch]$Json
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$violations = @()
$unbudgeted = @()
$passed = 0; $total = 0

$skillFiles = @(Get-ChildItem -Path $SkillsPath -Filter "SKILL.md" -Recurse -File -ErrorAction SilentlyContinue)
$total = $skillFiles.Count

foreach ($sf in $skillFiles) {
    $content = Get-Content -Raw -Path $sf.FullName -Encoding UTF8
    $fileSize = $sf.Length

    # Parse YAML frontmatter: extract token_budget value
    $budget = $null
    if ($content -match '(?m)^token_budget:\s*(\d+)\s*$') {
        $budget = [int]$Matches[1]
    }

    if ($null -eq $budget) {
        $unbudgeted += $sf.Name.Replace('\SKILL.md','')
        continue
    }

    $limit = [math]::Round($budget * $DriftThreshold, 0)
    if ($fileSize -gt $limit) {
        $delta = $fileSize - $budget
        $pct = [math]::Round((($fileSize - $budget) / $budget) * 100, 1)
        $violations += [PSCustomObject]@{
            Skill     = $sf.Directory.Name
            Budget    = $budget
            Current   = $fileSize
            Delta     = $delta
            Percent   = $pct
            Limit     = $limit
        }
    } else {
        $passed++
    }
}

$passedAll = $violations.Count -eq 0

# --- Output ---
if ($Json) {
    [PSCustomObject]@{
        passed       = $passedAll
        skills_checked = $total
        skills_budgeted = ($total - $unbudgeted.Count)
        skills_passing = $passed
        unbudgeted   = $unbudgeted
        violations   = $violations
        drift_threshold = $DriftThreshold
        budget_field = "token_budget (YAML frontmatter)"
    } | ConvertTo-Json -Depth 3
    exit $(if ($passedAll) { 0 } else { 1 })
}

if ($passedAll) {
    Write-Output "OK   Budget regression: $passed/$($total - $unbudgeted.Count) budgeted skills within $([math]::Round(($DriftThreshold-1)*100,0))% threshold"
    if ($unbudgeted.Count -gt 0) {
        Write-Output "      WARN: $($unbudgeted.Count) skills without token_budget frontmatter (use -Json for list)"
    }
} else {
    Write-Output "FAIL Budget regression violations:"
    $violations | ForEach-Object {
        Write-Output "   X  $($_.Skill): $($_.Current)B > $($_.Limit)B (budget $($_.Budget)B, +$($_.Percent)%)"
    }
}

exit $(if ($passedAll) { 0 } else { 1 })
