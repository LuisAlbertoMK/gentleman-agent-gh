#requires -Version 7.6
<#
.SYNOPSIS
    Auto-forge a skill from a pattern when it reaches its promotion threshold.
.DESCRIPTION
    Reads a pattern from the store, checks severity-based thresholds (hits × projects),
    generates a SKILL.md, runs 9 quality gates, and registers it as a lazy-load skill.
.PARAMETER PatternId
    The pattern ID to forge (e.g. "ux/a11y/hero-btn-contrast").
.PARAMETER PatternFile
    Path to a pattern JSON file (alternative to PatternId).
.PARAMETER Force
    Skip threshold check and forge regardless.
.PARAMETER DryRun
    Run all gates but don't write anything.
.PARAMETER Quiet
    Output JSON only (machine-readable).

.THRESHOLDS
    CRITICAL: ≥1 hit across ≥1 project
    HIGH:     ≥2 hits across ≥2 projects
    MEDIUM:   ≥3 hits across ≥2 projects (default)
    LOW:      ≥5 hits across ≥3 projects

.EXAMPLE
    .\scripts\wisdom-forge.ps1 -PatternId "ux/a11y/hero-btn-contrast"
    .\scripts\wisdom-forge.ps1 -PatternFile pattern.json -DryRun
    .\scripts\wisdom-forge.ps1 -PatternId "css/rgb-gotcha" -Force
#>
param(
    [string]$PatternId = "",
    [string]$PatternFile = "",
    [switch]$Force,
    [switch]$DryRun,
    [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$patternsDir = Join-Path $repoRoot "docs" "cross-project" "patterns"
$skillsDir = Join-Path $repoRoot ".agents" "skills"

# Severity → threshold mapping
$thresholds = @{
    CRITICAL = @{ Hits = 1;  Projects = 1 }
    HIGH     = @{ Hits = 2;  Projects = 2 }
    MEDIUM   = @{ Hits = 3;  Projects = 2 }
    LOW      = @{ Hits = 5;  Projects = 3 }
}

# ─── Load pattern ───────────────────────────────────────────────
function Load-Pattern {
    param([string]$Id, [string]$File)
    if ($Id) {
        $found = @(Get-ChildItem $patternsDir -Filter "*.json" | Where-Object {
            try { (Get-Content $_.FullName -Raw | ConvertFrom-Json).id -eq $Id } catch { $false }
        })
        if ($found.Length -eq 0) { Write-Error "Pattern not found: $Id"; exit 1 }
        $filePath = $found[0].FullName
    } elseif ($File) {
        if (-not (Test-Path $File)) { Write-Error "File not found: $File"; exit 1 }
        $filePath = $File
    } else { Write-Error "Provide -PatternId or -PatternFile"; exit 1 }

    try { $pattern = Get-Content $filePath -Raw | ConvertFrom-Json } catch { Write-Error "Invalid JSON: $_"; exit 1 }
    return $pattern, $filePath
}

# ─── Check threshold ────────────────────────────────────────────
function Test-ForgeThreshold {
    param($Pattern)
    if ($Force) { return $true, "forced" }

    $sev = if ($Pattern.severity -and $thresholds.ContainsKey($Pattern.severity)) { $Pattern.severity } else { "MEDIUM" }
    $t = $thresholds[$sev]
    $hits = if ($Pattern.hits) { [int]$Pattern.hits } else { 0 }

    # Count distinct projects from context.files
    $projects = 0
    if ($Pattern.context -and $Pattern.context.files) {
        $projects = @($Pattern.context.files | Select-Object -Unique).Length
    }
    if ($projects -lt 1) { $projects = 1 }  # at least the originating project

    if ($hits -ge $t.Hits -and $projects -ge $t.Projects) {
        return $true, "threshold met (${sev}: $($t.Hits)×$($t.Projects))"
    }
    $needHits = [Math]::Max(0, $t.Hits - $hits)
    $needProj = [Math]::Max(0, $t.Projects - $projects)
    return $false, "needs $needHits more hit(s) and $needProj more project(s) for ${sev} threshold"
}

# ─── Generate SKILL.md ──────────────────────────────────────────
function New-SkillContent {
    param($Pattern)
    $slug = ($Pattern.id -replace '[/\s]+', '-').ToLower()
    # Ensure cross-project- prefix
    if ($slug -notlike "cross-project-*") { $slug = "cross-project-$slug" }
    # Trim trailing junk
    $slug = $slug -replace '-+$', ''

    $desc = if ($Pattern.rule -and $Pattern.rule.summary) {
        $d = $Pattern.rule.summary -replace '[”“]', '"' -replace "'", "`'"
        if ($d.Length -gt 115) { $d.Substring(0, 112) + "..." } else { $d }
    } else { $Pattern.title }

    $triggerKeywords = @($Pattern.title)
    if ($Pattern.tags) { $triggerKeywords += $Pattern.tags }
    if ($Pattern.signal -and $Pattern.signal.keywords) { $triggerKeywords += $Pattern.signal.keywords }
    if ($Pattern.signal -and $Pattern.signal.css_selectors) { $triggerKeywords += $Pattern.signal.css_selectors }
    $triggerStr = ($triggerKeywords | Select-Object -Unique) -join ', '

    $details = if ($Pattern.rule -and $Pattern.rule.details) { $Pattern.rule.details } else { "" }
    $check = if ($Pattern.rule -and $Pattern.rule.check) { $Pattern.rule.check } else { "" }
    $fix = if ($Pattern.rule -and $Pattern.rule.fix) { $Pattern.rule.fix } else { "" }

    return @"
---
name: $slug
description: "$desc"
license: Apache-2.0
metadata:
  tags: [$(($Pattern.tags -join ', '))]
  author: gentleman-vMK (auto-forged)
  version: "1.0"
  changelog: "1.0: auto-forged from pattern $($Pattern.id)"
  source_pattern: "$($Pattern.id)"
  source_severity: "$($Pattern.severity)"
triggers: "$triggerStr"
---

## Rule
$details

## Check
$check

## Fix
$fix

## Source Pattern
This skill was auto-forged from pattern **$($Pattern.id)**.
Last updated: $($Pattern.updated). Confidence: $($Pattern.confidence).
"@
}

# ─── Quality Gates ──────────────────────────────────────────────
$gateResults = @()

function Add-Gate {
    param([string]$Name, [scriptblock]$Check, [switch]$NoLog)
    try {
        $ok = & $Check
        $script:gateResults += [PSCustomObject]@{ Gate = $Name; Status = if ($ok) { "PASS" } else { "FAIL" } }
        return $ok
    } catch {
        $script:gateResults += [PSCustomObject]@{ Gate = $Name; Status = "FAIL"; Error = $_.Exception.Message }
        return $false
    }
}

function Test-YamlFrontmatter {
    param([string]$Content)
    # Verify --- exists and has closing --- (allow leading newline from here-string)
    $trimmed = $Content.TrimStart()
    return $trimmed.StartsWith("---") -and ($Content -match '(?s)---\s*\n.*?\n---')
}

function Test-TriggerUnique {
    param([string[]]$Triggers)
    $allSkills = @(Get-ChildItem $skillsDir -Filter "SKILL.md" -Recurse -ErrorAction SilentlyContinue)
    $allTriggerText = @()
    foreach ($sf in $allSkills) {
        try {
            $c = Get-Content $sf.FullName -Raw
            if ($c -match '(?s)triggers:\s*"([^"]+)"') {
                $allTriggerText += ($Matches[1] -split ',') | ForEach-Object { $_.Trim().ToLower() }
            }
        } catch { continue }
    }

    $conflicts = @()
    foreach ($t in $Triggers) {
        $tl = $t.Trim().ToLower()
        if ($tl -ne "" -and $allTriggerText -contains $tl) { $conflicts += $t }
    }
    if ($conflicts.Length -gt 0) { return $false }
    return $true
}

function Test-NoSecrets {
    param([string]$Content)
    $secretsPatterns = @(
        '-----BEGIN (RSA|OPENSSH|PRIVATE|EC) KEY-----',
        '(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*[''"][^''"]{8,}',
        'C:\\Users\\[^\\]+'
    )
    foreach ($p in $secretsPatterns) {
        if ($Content -match $p) { return $false }
    }
    return $true
}

# ─── Check existing skill directories for conflict ──────────────
function Test-NoConflict {
    param([string]$SkillName)
    $existing = @(Get-ChildItem $skillsDir -Directory | Where-Object { $_.Name -eq $SkillName })
    return $existing.Length -eq 0
}

# ─── Main forge logic ──────────────────────────────────────────
$pattern, $filePath = Load-Pattern -Id $PatternId -File $PatternFile

$sev = if ($pattern.severity) { $pattern.severity } else { "MEDIUM" }
$id = $pattern.id
$hits = if ($pattern.hits) { [int]$pattern.hits } else { 0 }

if (-not $Quiet) {
    Write-Host "═══════════════════════════════════════════"
    Write-Host "  Wisdom Forge Pipeline"
    Write-Host "  Pattern : $id"
    Write-Host "  Severity: $sev (hits: $hits)"
    if ($DryRun) { Write-Host "  [DRY-RUN — no changes will be made]" }
    Write-Host "═══════════════════════════════════════════"
}

# Step 1: Threshold check
if (-not $Force) {
    $ok, $reason = Test-ForgeThreshold $pattern
    if (-not $ok) {
        if (-not $Quiet) { Write-Host "[✗] $reason" }
        $result = [PSCustomObject]@{ Status = "BLOCKED"; Reason = $reason; PatternId = $id; Gates = $gateResults }
        if (-not $Quiet) { $result | ConvertTo-Json -Depth 3 } else { $result | ConvertTo-Json -Depth 3 }
        exit 0
    }
    if (-not $Quiet) { Write-Host "[✓] $reason" }
} else {
    if (-not $Quiet) { Write-Host "[!] Threshold check skipped (--Force)" }
}

# Step 2: Generate SKILL.md
$slug = ($pattern.id -replace '[/\s]+', '-').ToLower()
if ($slug -notlike "cross-project-*") { $slug = "cross-project-$slug" }
$slug = $slug -replace '-+$', ''
$skillDir = Join-Path $skillsDir $slug
$skillFile = Join-Path $skillDir "SKILL.md"

$skillContent = New-SkillContent $pattern
$skillSize = [System.Text.Encoding]::UTF8.GetByteCount($skillContent)

if (-not $Quiet) { Write-Host "[GENERATE] Skill: $slug ($skillSize bytes)" }

# Step 3: Quality gates
$allPass = $true

# Gate 1: YAML frontmatter
$g1ok = Add-Gate -Name "yaml-frontmatter" -Check { Test-YamlFrontmatter $skillContent }
if (-not $g1ok) { $allPass = $false }

# Gate 2: prefix
$hasPrefix = $slug -like "cross-project-*"
$gateResults += [PSCustomObject]@{ Gate = "name-prefix"; Status = if ($hasPrefix) { "PASS" } else { "FAIL" } }
if (-not $hasPrefix) { $allPass = $false }

# Gate 3: description value length (≤120 chars)
$descValue = if ($skillContent -match '(?m)^description:\s*"([^"]+)"') { $Matches[1] } else { "" }
$descLen = $descValue.Length
$descOk = $descLen -le 120
$gateResults += [PSCustomObject]@{ Gate = "description-length"; Status = if ($descOk) { "PASS" } else { "FAIL" }; Detail = "$descLen chars (max 120)" }
if (-not $descOk) { $allPass = $false }

# Gate 4: triggers
$triggers = if ($pattern.tags) { @($pattern.tags) } else { @() }
$triggersOk = $triggers.Length -gt 0
$gateResults += [PSCustomObject]@{ Gate = "triggers-nonempty"; Status = if ($triggersOk) { "PASS" } else { "FAIL" } }
if (-not $triggersOk) { $allPass = $false }

# Gate 5: trigger uniqueness
$uniqueOk = Test-TriggerUnique $triggers
$gateResults += [PSCustomObject]@{ Gate = "triggers-unique"; Status = if ($uniqueOk) { "PASS" } else { "FAIL" } }
if (-not $uniqueOk) { $allPass = $false }

# Gate 6: has rules
$hasRules = ($pattern.rule -and ($pattern.rule.check -or $pattern.rule.fix -or $pattern.rule.details))
$gateResults += [PSCustomObject]@{ Gate = "has-rules"; Status = if ($hasRules) { "PASS" } else { "FAIL" } }
if (-not $hasRules) { $allPass = $false }

# Gate 7: size ≤ 2KB
$sizeOk = $skillSize -le 2048
$gateResults += [PSCustomObject]@{ Gate = "size-max-2kb"; Status = if ($sizeOk) { "PASS" } else { "FAIL" }; Detail = "$skillSize bytes" }
if (-not $sizeOk) { $allPass = $false }

# Gate 8: no conflict with existing skill dir
$conflictOk = Test-NoConflict $slug
$gateResults += [PSCustomObject]@{ Gate = "no-directory-conflict"; Status = if ($conflictOk) { "PASS" } else { "FAIL" } }
if (-not $conflictOk) { $allPass = $false }

# Gate 9: no secrets
$secretsOk = Test-NoSecrets $skillContent
$gateResults += [PSCustomObject]@{ Gate = "no-secrets"; Status = if ($secretsOk) { "PASS" } else { "FAIL" } }
if (-not $secretsOk) { $allPass = $false }

# Show gates
if (-not $Quiet) {
    Write-Host "`n── Quality Gates ──"
    foreach ($g in $gateResults) {
        $icon = if ($g.Status -eq "PASS") { "✓" } else { "✗" }
        $detail = if ($g.Detail) { " ($($g.Detail))" } else { "" }
        Write-Host "  [$icon] $($g.Gate)$detail"
    }
}

# Step 4: If any gate failed → BLOCKED
if (-not $allPass) {
    if (-not $Quiet) { Write-Host "`n[✗] BLOCKED: quality gates failed. No forge." }
    $result = [PSCustomObject]@{
        Status = "BLOCKED"
        Reason = "Quality gates failed"
        PatternId = $id
        Gates = $gateResults
        ForgePath = ""
    }
    $result | ConvertTo-Json -Depth 4
    exit 0
}

if (-not $Quiet) { Write-Host "`n[✓] All gates PASSED" }

# If dry-run, stop here
if ($DryRun) {
    if (-not $Quiet) { Write-Host "[DRY-RUN] Would create: $skillDir" }
    $result = [PSCustomObject]@{
        Status = "DRY_RUN"
        PatternId = $id
        SkillName = $slug
        SkillPath = $skillDir
        SkillSize = $skillSize
        Gates = $gateResults
    }
    $result | ConvertTo-Json -Depth 4
    exit 0
}

# Step 5: Write
if (-not (Test-Path $skillDir)) { New-Item -ItemType Directory -Path $skillDir -Force | Out-Null }
Set-Content -Path $skillFile -Value $skillContent -Encoding UTF8
if (-not $Quiet) { Write-Host "[WRITE] $skillFile" }

# Step 6: Update pattern — add skill_ref, set status=promoted
$pattern | Add-Member -NotePropertyName "skill_ref" -NotePropertyValue $slug -Force
$pattern | Add-Member -NotePropertyName "status" -NotePropertyValue "promoted" -Force
$pattern | Add-Member -NotePropertyName "promoted_at" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd") -Force
$pattern | ConvertTo-Json -Depth 6 | Set-Content $filePath -Encoding UTF8
if (-not $Quiet) { Write-Host "[UPDATE] Pattern status → promoted, skill_ref → $slug" }

# Step 7: Output
$result = [PSCustomObject]@{
    Status    = "FORGED"
    PatternId = $id
    SkillName = $slug
    SkillPath = $skillDir
    SkillFile = $skillFile
    SkillSize = $skillSize
    Gates     = $gateResults
    EngramPayload = [PSCustomObject]@{
        TopicKey  = "forge/$slug"
        Type      = "architecture"
        Title     = "Forged skill: $slug"
        Content   = "**What**: Auto-forged skill from pattern `$id` (severity: $sev, hits: $hits)`n**Why**: Pattern reached promotion threshold`n**Where**: $skillFile`n**Learned**: Forged via wisdom-forge.ps1 — 9 quality gates passed"
    }
}

if (-not $Quiet) {
    Write-Host "`n═══════════════════════════════════════════"
    Write-Host "  FORGED: $slug"
    Write-Host "  mem_save: forge/$slug"
    Write-Host "═══════════════════════════════════════════"
}
$result | ConvertTo-Json -Depth 5
