#requires -Version 7
[CmdletBinding()]
<#
.SYNOPSIS
    Extract reference material from a SKILL.md into docs/skills/{skill}/reference.md.
.DESCRIPTION
    Keeps the SKILL.md "core" (rules, format, essential tables) under the 3KB token budget
    (ADR-007) by moving worked examples, testing patterns, edge cases, anti-patterns,
    and quick-reference cards to an external file. The SKILL.md is rewritten with a
    Reference Materials section linking to the extracted content.

    This is a DRY, reversible operation — all original content is preserved verbatim
    in reference.md; nothing is deleted, only relocated.

.PARAMETER Skill
    Skill directory name (e.g. 'sdd-tasks').
.PARAMETER CoreLines
    Number of lines to keep as core (lines before the first extractable section).
    Determined by: find the '---' separator that immediately precedes
    '## Examples', '## Testing', '## Edge Cases', '## Anti-Patterns', etc.

.EXAMPLE
    .\scripts\extract-skill-reference.ps1 -Skill 'metricas' -CoreLines 107
    .\scripts\extract-skill-reference.ps1 -Skill 'e2e-testing' -CoreLines 84
#>
param(
    [Parameter(Mandatory=$true)][string]$Skill,
    [Parameter()][int]$CoreLines
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\lib\platform.ps1"
$repoRoot = Get-GentlemanRoot
Push-Location $repoRoot

$skillDir    = Join-Path $repoRoot ".agents\skills\$Skill"
$skillMd     = Join-Path $skillDir "SKILL.md"
$docsDir     = Join-Path $repoRoot "docs\skills\$Skill"
$referenceMd = Join-Path $docsDir "reference.md"

if (-not (Test-Path $skillMd)) {
    Write-Error "SKILL.md not found: $skillMd"
    exit 1
}

# Read original
$content = Get-Content $skillMd -Raw -Encoding UTF8
$lines   = $content -split "`n"
$origSize = $content.Length
$origLines = $lines.Count

# --- Auto-detect core boundary if CoreLines not provided ---
# Finds the first "extractable" heading (Examples/Testing/Edge Cases/Anti-Patterns/etc.)
# and the '---' section separator immediately preceding it (NOT the frontmatter ---).
if ($CoreLines -eq 0) {
    # Case-insensitive matching for extractable section headings (reference material only).
    # Matches Examples, Example, Anti-Patterns, Edge Cases, Testing Patterns, etc.
    # Core instructions (rules, output format, dimension tables) are NOT matched.
    $extractablePrefixes = @('## examples', '## example', '## anti-pattern', '## edge case',
                             '## testing', '## tests', '## sample', '## scenario',
                             '## walkthrough', '## worked example', '## appendix',
                             '## output envelope', '## guardrail')
    $firstExtractableIdx = $null
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lower = $lines[$i].Trim().ToLower()
        foreach ($prefix in $extractablePrefixes) {
            if ($lower.StartsWith($prefix)) { $firstExtractableIdx = $i; break }
        }
        if ($null -ne $firstExtractableIdx) { break }
    }
    if ($null -eq $firstExtractableIdx) {
        Write-Error "No extractable section found in $Skill/SKILL.md (core seems lean already)"
        exit 0
    }
    # Find the '---' separator within 3 lines BEFORE the heading (section separator, not frontmatter)
    $coreBoundary = $null
    $searchFrom = [math]::Max(0, $firstExtractableIdx - 4)
    for ($j = $firstExtractableIdx - 1; $j -ge $searchFrom; $j--) {
        if ($lines[$j].Trim() -eq '---') { $coreBoundary = $j; break }
    }
    if ($null -eq $coreBoundary) { $coreBoundary = $firstExtractableIdx - 1 }
    $CoreLines = $coreBoundary + 1  # convert 0-indexed position to 1-indexed line count
}

if ($CoreLines -lt 1 -or $CoreLines -ge $lines.Count) {
    Write-Error "CoreLines ($CoreLines) out of range for file with $($lines.Count) lines"
    exit 1
}

# Core = lines 1..CoreLines (indices 0..CoreLines-1)
$core = ($lines[0..($CoreLines-1)] -join "`n").TrimEnd()

# Extract = lines CoreLines+1..end (everything after core, including separators)
$extract = ($lines[$CoreLines..($lines.Count-1)] -join "`n").Trim()

# Build reference.md
$refHeader = @"
# $Skill — Reference Materials

> **Externalized from** `.agents/skills/$Skill/SKILL.md` to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: `$Skill` sub-agent when producing output.

"@
$refContent = $refHeader + $extract

# Create docs dir
if (-not (Test-Path $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
}
$refContent | Set-Content $referenceMd -Encoding UTF8

# Build reduced SKILL.md
$refSection = @"

---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → `docs/skills/$Skill/reference.md`

---
"@

$reducedContent = $core + $refSection
$reducedContent | Set-Content $skillMd -Encoding UTF8

$newSize = (Get-Item $skillMd).Length
$refSize = (Get-Item $referenceMd).Length
$reduction = [math]::Round((1 - $newSize/$origSize) * 100, 1)

Write-Host "[$Skill] SKILL.md: $origLines lines, $origSize bytes" -ForegroundColor Gray
Write-Host "[$Skill] SKILL.md reduced: $($reducedContent.Split("`n").Count) lines, $newSize bytes ($reduction% reduction)" -ForegroundColor Green
Write-Host "[$Skill] reference.md: $refSize bytes" -ForegroundColor Cyan
Write-Host "[$Skill] Extracted lines: $($CoreLines+1)-$origLines" -ForegroundColor DarkGray

Pop-Location
exit 0
