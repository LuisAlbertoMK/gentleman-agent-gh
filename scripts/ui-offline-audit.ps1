#requires -Version 5.1
<#
.SYNOPSIS
    Offline UI audit — no Ollama/vision-analyze required.
.DESCRIPTION
    Scans docs/.vitepress/config.js and skills/baseline-ui/SKILL.md for
    typography, spacing, and hierarchy anti-patterns using Select-String.
    Returns JSON with violations, score, and tarea metadata.
.PARAMETER Json
    Output results as JSON.
.NOTES
    Offline fallback for vision-analyze (avoids localhost:11434 / ECONNREFUSED).
    Based on baseline-ui skill rules: OKLCH tokens, no fixed widths,
    text-balance headings, text-pretty body, contrast >=4.5:1.
#>
param(
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Resolve repo root ──
$repoRoot = $PSScriptRoot
while ($repoRoot) {
    if (Test-Path (Join-Path $repoRoot ".git")) { break }
    $parent = Split-Path -Parent $repoRoot
    if ($parent -eq $repoRoot) { $repoRoot = $PSScriptRoot; break }
    $repoRoot = $parent
}

# ── Target files ──
$vitepressConfig = Join-Path $repoRoot "docs\.vitepress\config.js"
$baselineSkill   = Join-Path $repoRoot ".agents\skills\baseline-ui\SKILL.md"
$docsIndex       = Join-Path $repoRoot "docs\index.md"

# ── Violations accumulator ──
$violations = @()
$checksPerformed = 0

# ── Helper: add violation ──
function Add-Violation {
    param([string]$Severity, [string]$File, [string]$Rule, [string]$Detail)
    $script:violations += [ordered]@{
        severity = $Severity
        file     = $File
        rule     = $Rule
        detail   = $Detail
    }
    $script:checksPerformed++
}

# ── 1. docs/index.md — typography checks ──
if (Test-Path $docsIndex) {
    $idxContent = Get-Content $docsIndex -Raw -Encoding UTF8

    # Check: heading hierarchy (h1 must be first, no skip)
    $headings = [regex]::Matches($idxContent, '(?m)^(#{1,6})\s+')
    $prevLevel = 0
    foreach ($m in $headings) {
        $level = $m.Groups[1].Value.Length
        if ($prevLevel -gt 0 -and $level -gt ($prevLevel + 1)) {
            Add-Violation "MEDIUM" "docs/index.md" "hierarchy-skip" "Heading jumps from h$prevLevel to h$level"
        }
        $prevLevel = $level
    }
    $checksPerformed++

    # Check: missing text-balance on headings (CSS-level, flag if not in config)
    if ($idxContent -match '(?m)^#\s+' -and $idxContent -notmatch 'text-balance') {
        Add-Violation "LOW" "docs/index.md" "typography-text-balance" "H1 present but no text-balance CSS applied"
    }
    $checksPerformed++

    # Check: spacing — empty lines between heading and content (8pt rule proxy)
    if ($idxContent -match '(?m)^#\s+.+\n[^#\n]') {
        Add-Violation "LOW" "docs/index.md" "spacing-heading-gap" "H1 immediately followed by content line (no breathing room)"
    }
    $checksPerformed++
}

# ── 2. docs/.vitepress/config.js — layout/theme checks ──
if (Test-Path $vitepressConfig) {
    $cfgContent = Get-Content $vitepressConfig -Raw -Encoding UTF8

    # Check: fixed widths (anti-pattern from baseline-ui)
    $fixedWidths = Select-String -Path $vitepressConfig -Pattern '(width|size)\s*:\s*\d+px' -AllMatches
    if ($fixedWidths) {
        foreach ($match in $fixedWidths) {
            Add-Violation "HIGH" "docs/.vitepress/config.js" "fixed-width" "Fixed pixel width: $($match.Line.Trim())"
        }
    }
    $checksPerformed++

    # Check: HSL/RGB hex colors (anti-pattern — should be OKLCH)
    $hexColors = Select-String -Path $vitepressConfig -Pattern '#[0-9a-fA-F]{3,8}(?![0-9a-fA-F])' -AllMatches
    if ($hexColors) {
        foreach ($match in $hexColors) {
            Add-Violation "MEDIUM" "docs/.vitepress/config.js" "color-hex" "Hex color found: $($match.Line.Trim()) — prefer OKLCH"
        }
    }
    $checksPerformed++

    # Check: transition:all (anti-pattern)
    $transitionAll = Select-String -Path $vitepressConfig -Pattern 'transition\s*:\s*all' -AllMatches
    if ($transitionAll) {
        foreach ($match in $transitionAll) {
            Add-Violation "HIGH" "docs/.vitepress/config.js" "transition-all" "transition:all detected — animate transform+opacity only"
        }
    }
    $checksPerformed++

    # Check: h-screen (anti-pattern — use min-height:100dvh)
    $hScreen = Select-String -Path $vitepressConfig -Pattern 'h-screen' -AllMatches
    if ($hScreen) {
        Add-Violation "HIGH" "docs/.vitepress/config.js" "h-screen" "h-screen detected — use min-height:100dvh"
    }
    $checksPerformed++

    Write-Debug "ui-offline-audit: config.js checks complete"
}

# ── 3. skills/baseline-ui/SKILL.md — skill integrity ──
if (Test-Path $baselineSkill) {
    # Check: required frontmatter fields
    $skillContent = Get-Content $baselineSkill -Raw -Encoding UTF8
    $requiredFields = @("name:", "description:", "triggers:", "token_budget:")
    foreach ($field in $requiredFields) {
        if ($skillContent -notmatch [regex]::Escape($field)) {
            Add-Violation "HIGH" "skills/baseline-ui/SKILL.md" "missing-frontmatter" "Required field missing: $field"
        }
    }
    $checksPerformed++

    # Check: cross-refs exist
    $xrefs = Select-String -Path $baselineSkill -Pattern 'Cross-Refs:\s*(.*)' -AllMatches
    if ($xrefs) {
        foreach ($match in $xrefs) {
            $refs = ($match.Matches[0].Groups[1].Value) -split '\s*\|\s*'
            foreach ($ref in $refs) {
                $refTrimmed = $ref.Trim()
                if ($refTrimmed -and -not (Get-ChildItem -Path (Join-Path $repoRoot ".agents\skills") -Filter "$refTrimmed" -Directory -ErrorAction SilentlyContinue)) {
                    Add-Violation "MEDIUM" "skills/baseline-ui/SKILL.md" "broken-xref" "Cross-ref skill not found: $refTrimmed"
                }
            }
        }
    }
    $checksPerformed++
}

# ── Score calculation ──
$totalChecks = [math]::Max($checksPerformed, 1)
$criticalCount = @($violations | Where-Object { $_.severity -eq "CRITICAL" }).Count
$highCount     = @($violations | Where-Object { $_.severity -eq "HIGH" }).Count
$mediumCount   = @($violations | Where-Object { $_.severity -eq "MEDIUM" }).Count
$lowCount      = @($violations | Where-Object { $_.severity -eq "LOW" }).Count

# Score: start at 10, subtract weighted penalties
$score = 10.0
$score -= ($criticalCount * 3.0)
$score -= ($highCount * 1.5)
$score -= ($mediumCount * 0.5)
$score -= ($lowCount * 0.25)
$score = [math]::Max(0, [math]::Round($score, 1))

# ── Output ──
$result = [ordered]@{
    tarea            = "ui-offline"
    score            = $score
    violations       = $violations
    summary          = @{
        critical = $criticalCount
        high     = $highCount
        medium   = $mediumCount
        low      = $lowCount
        total    = @($violations).Count
    }
    files_scanned    = @(
        @{ path = "docs/index.md";                    exists = (Test-Path $docsIndex) }
        @{ path = "docs/.vitepress/config.js";        exists = (Test-Path $vitepressConfig) }
        @{ path = "skills/baseline-ui/SKILL.md";      exists = (Test-Path $baselineSkill) }
    )
    checks_performed = $totalChecks
    ollama_required  = $false
    timestamp        = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    note             = "Offline audit — no Ollama/vision-analyze invoked"
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Host "=== UI Offline Audit ===" -ForegroundColor Cyan
    Write-Host "  Score:      $($result.score)/10"
    Write-Host "  Violations: $($result.summary.total) (C:$criticalCount H:$highCount M:$mediumCount L:$lowCount)"
    Write-Host "  Checks:     $($result.checks_performed)"
    Write-Host "  Ollama:     Not required (offline)"
    foreach ($v in $violations) {
        $color = switch ($v.severity) { "CRITICAL" { "Red" } "HIGH" { "Yellow" } "MEDIUM" { "DarkYellow" } default { "Gray" } }
        Write-Host "  [$($v.severity)] $($v.rule): $($v.detail)" -ForegroundColor $color
    }
}
