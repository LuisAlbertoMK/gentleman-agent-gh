#requires -Version 5.1

<#
.SYNOPSIS
  Extract patterns from .learnings/ into reusable skills.
  Part of the self-improvement cycle.

.DESCRIPTION
  Scans .learnings/LEARNINGS.md for patterns with ≥3 repetitions
  (identified by same Pattern-Key) and generates a skill skeleton
  in .agents/skills/{name}/SKILL.md.

.PARAMETER PatternKey
  Extract a specific pattern by key (e.g. "improvement/cycle").

.PARAMETER List
  List all patterns with repetition count ≥ threshold.

.PARAMETER Threshold
  Minimum repetitions to auto-extract (default: 3).

.PARAMETER DryRun
  Show what would be extracted without writing files.

.PARAMETER Quiet
  JSON output only.
#>

param(
    [string]$PatternKey = "",
    [switch]$List,
    [int]$Threshold = 3,
    [switch]$DryRun,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$learnPath = Join-Path -Path $repoRoot -ChildPath ".learnings\LEARNINGS.md"
$skillsDir = Join-Path -Path $repoRoot -ChildPath ".agents\skills"

$results = @()

if (-not (Test-Path -LiteralPath $learnPath)) {
    Write-Host "[extract-skill] No .learnings/LEARNINGS.md found" -ForegroundColor Yellow
    exit 0
}

# Read learnings and extract Pattern-Key lines
$content = Get-Content -LiteralPath $learnPath -Raw
$patternLines = [regex]::Matches($content, '- \*\*Pattern-Key\*\*: (\S+)')
$allKeys = @()
foreach ($m in $patternLines) {
    $allKeys += $m.Groups[1].Value
}

if ($List) {
    # Count repetitions
    $grouped = $allKeys | Group-Object | Where-Object { $_.Count -ge $Threshold } | Sort-Object Count -Descending
    if ($grouped.Count -eq 0) {
        if (-not $Quiet) {
            Write-Host "[extract-skill] No patterns with ≥$Threshold repetitions found" -ForegroundColor Yellow
        }
        exit 0
    }
    if (-not $Quiet) {
        Write-Host "Patterns with ≥$Threshold repetitions:" -ForegroundColor Cyan
        foreach ($g in $grouped) {
            Write-Host "  $($g.Name) ($($g.Count)x)" -ForegroundColor Green
        }
    }
    $results = $grouped
    if ($Quiet) {
        $grouped | Select-Object Name, Count | ConvertTo-Json
    }
    exit 0
}

if ($PatternKey -ne "") {
    $allKeys = @($PatternKey)
}

foreach ($key in $allKeys) {
    # Check if skill already exists
    $safeName = $key -replace '/', '-'
    $skillPath = Join-Path -Path $skillsDir -ChildPath "$safeName\SKILL.md"

    if (Test-Path -LiteralPath $skillPath) {
        if (-not $Quiet) {
            Write-Host "[extract-skill] Skill already exists: $safeName — skipping" -ForegroundColor Yellow
        }
        continue
    }

    # Find learnings with this Pattern-Key
    $entries = [regex]::Matches($content, "(?s)## \[.*?\].*?\n.*?\*\*Pattern-Key\*\*: $key.*?\n(.*?)(?=\n## |\Z)")
    $entryCount = $entries.Count

    if ($entryCount -lt $Threshold) {
        if (-not $Quiet) {
            Write-Host "[extract-skill] '$key': $entryCount reps (< $Threshold), skipping" -ForegroundColor DarkYellow
        }
        continue
    }

    if ($DryRun) {
        Write-Host "[DRY-RUN] Would create skill: $safeName ($entryCount entries)" -ForegroundColor Cyan
        $results += [PSCustomObject]@{
            PatternKey = $key
            SkillName  = $safeName
            Entries    = $entryCount
            Path       = $skillPath
        }
        continue
    }

    # Generate skill
    $skillDir = Join-Path -Path $skillsDir -ChildPath $safeName
    New-Item -ItemType Directory -Path $skillDir -Force | Out-Null

    $description = "Auto-extracted pattern: $key ($entryCount occurrences in .learnings)"

    $skillContent = @"---
name: $safeName
description: "$description"
triggers: "$key"
license: Apache-2.0
metadata:
  tags: [auto-extracted, pattern]
  author: gentleman-vMK
  version: "1.0"
  source: extract-skill.ps1
---

## When
Pattern `$key` with $entryCount repetitions detected in .learnings.

## Critical Patterns
- See `.learnings/LEARNINGS.md` entries with Pattern-Key: `$key`
- Extracted automatically by `scripts/extract-skill.ps1`
- Review and refine this skill on first use
"@

    Set-Content -LiteralPath $skillPath -Value $skillContent -Encoding UTF8

    if (-not $Quiet) {
        Write-Host "[extract-skill] ✅ Created skill: $safeName ($entryCount entries)" -ForegroundColor Green
    }

    $results += [PSCustomObject]@{
        PatternKey = $key
        SkillName  = $safeName
        Entries    = $entryCount
        Path       = $skillPath
        Status     = "created"
    }
}

if ($results.Count -eq 0 -and -not $Quiet) {
    Write-Host "[extract-skill] No patterns extracted" -ForegroundColor Yellow
}

if ($Quiet) {
    $results | ConvertTo-Json -Depth 3
}
