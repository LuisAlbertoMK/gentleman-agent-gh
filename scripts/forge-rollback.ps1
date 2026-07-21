#requires -Version 7
<#
.SYNOPSIS
    Rollback a forged skill — remove directory, demote pattern back to active.
.DESCRIPTION
    Reverses the forge operation: removes the skill directory, reverts the
    pattern status to "active", clears the skill_ref, and logs the rollback.
.PARAMETER SkillName
    Skill directory name to remove (e.g. "cross-project-ux-a11y-hero-btn-contrast").
.PARAMETER PatternId
    Pattern ID to demote back to active (alternative to auto-detect).
.PARAMETER Quiet
    Output JSON only.

.EXAMPLE
    .\scripts\forge-rollback.ps1 -SkillName "cross-project-ux-a11y-hero-btn-contrast"
    .\scripts\forge-rollback.ps1 -PatternId "ux/a11y/hero-btn-contrast"
#>
param(
    [string]$SkillName = "",
    [string]$PatternId = "",
    [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$patternsDir = Join-Path $repoRoot "docs" "cross-project" "patterns"
$skillsDir = Join-Path $repoRoot ".agents" "skills"

$actions = @()

# ─── Resolve skill directory ────────────────────────────────────
if (-not $SkillName -and -not $PatternId) { Write-Error "Provide -SkillName or -PatternId"; exit 1 }

$resolvedSkillDir = ""
$resolvedPatternFile = ""

if ($SkillName) {
    $resolvedSkillDir = Join-Path $skillsDir $SkillName
    if (-not (Test-Path $resolvedSkillDir)) {
        Write-Error "Skill directory not found: $resolvedSkillDir"; exit 1
    }
    # Try to auto-detect pattern from SKILL.md source_pattern metadata
    $skillFile = Join-Path $resolvedSkillDir "SKILL.md"
    if (Test-Path $skillFile) {
        $skillContent = Get-Content $skillFile -Raw
        if ($skillContent -match 'source_pattern:\s*"([^"]+)"') {
            $resolvedPatternId = $Matches[1]
            $PatternId = $resolvedPatternId
        }
    }
}

if ($PatternId) {
    $found = @(Get-ChildItem $patternsDir -Filter "*.json" | Where-Object {
        try { (Get-Content $_.FullName -Raw | ConvertFrom-Json).id -eq $PatternId } catch { $false }
    })
    if ($found.Length -gt 0) { $resolvedPatternFile = $found[0].FullName }
}

# ─── Remove skill directory ─────────────────────────────────────
$skillRemoved = $false
if ($resolvedSkillDir -and (Test-Path $resolvedSkillDir)) {
    Remove-Item -Recurse -Force $resolvedSkillDir
    $actions += "Removed skill directory: $resolvedSkillDir"
    $skillRemoved = $true
    if (-not $Quiet) { Write-Host "  [✓] Removed: $resolvedSkillDir" }
} elseif ($SkillName -and -not $resolvedSkillDir) {
    Write-Error "Cannot resolve skill directory for: $SkillName"; exit 1
}

# ─── Demote pattern back to active ──────────────────────────────
if ($resolvedPatternFile -and (Test-Path $resolvedPatternFile)) {
    $pattern = Get-Content $resolvedPatternFile -Raw | ConvertFrom-Json
    $pattern | Add-Member -NotePropertyName "status" -NotePropertyValue "active" -Force
    $pattern | Add-Member -NotePropertyName "skill_ref" -NotePropertyValue $null -Force
    # Remove promoted_at if exists
    if ($pattern.PSObject.Properties['promoted_at']) {
        $pattern.PSObject.Properties.Remove('promoted_at')
    }
    $pattern | Add-Member -NotePropertyName "updated" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd") -Force
    $pattern | ConvertTo-Json -Depth 6 | Set-Content $resolvedPatternFile -Encoding UTF8
    $actions += "Demoted pattern: $PatternId → active (cleared skill_ref)"
    if (-not $Quiet) { Write-Host "  [✓] Pattern '$PatternId' → status=active" }
}

if ($actions.Length -eq 0) {
    Write-Error "Nothing to rollback — no skill dir found and no pattern matched"
    exit 1
}

$result = [PSCustomObject]@{
    Status     = "ROLLED_BACK"
    SkillName  = $SkillName
    PatternId  = $PatternId
    Actions    = $actions
    Timestamp  = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
}

if (-not $Quiet) {
    Write-Host "`n═══════════════════════════════"
    Write-Host "  Rollback complete"
    Write-Host "═══════════════════════════════"
}
$result | ConvertTo-Json -Depth 3
