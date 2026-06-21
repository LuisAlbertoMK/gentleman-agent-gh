#requires -Version 5.1

<#
.SYNOPSIS
  Validate internal references in gentleman-agent-gh repo.
  Checks skills, SKILLS-INDEX, global junctions, and shared refs.

.DESCRIPTION
  Post-migration (skills/ → .agents/skills/) validator.
  Returns 0 = clean, 1 = issues found.

.PARAMETER RepoRoot
  Root of the repo. Defaults to script parent dir.

.PARAMETER Json
  Output structured JSON for agent consumption.

.EXAMPLE
  .\scripts\cross-ref-check.ps1
  .\scripts\cross-ref-check.ps1 -Json
#>

param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),
    [switch]$Json
)

Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'
$errors = @()
$warnings = @()

$canonicalDir = Join-Path -Path $RepoRoot -ChildPath ".agents\skills"
$globalDir = "$env:USERPROFILE\.config\opencode\skills"

if (-not (Test-Path $canonicalDir)) {
    Write-Host "FATAL: Skills directory not found: $canonicalDir" -ForegroundColor Red
    exit 1
}

Write-Host "=== Cross-Ref Check: $RepoRoot ===" -ForegroundColor Cyan

# --- [1/8] ANTI-PATTERN-CATALOG ---
Write-Host "`n[1/8] ANTI-PATTERN-CATALOG..." -NoNewline
$apc = Test-Path (Join-Path -Path $RepoRoot -ChildPath "ANTI-PATTERN-CATALOG.md")
if ($apc) { Write-Host " OK" } else { $errors += "ANTI-PATTERN-CATALOG.md not found at repo root"; Write-Host " FAIL" }

# --- [2/8] All skills have SKILL.md ---
Write-Host "[2/8] SKILL.md files..." -NoNewline
$missingSkillMd = @()
try {
    $skillDirs = Get-ChildItem (Join-Path -Path $canonicalDir -ChildPath "*") -Directory
} catch {
    Write-Host " FAIL`nFATAL: Cannot list skill directories: $_" -ForegroundColor Red
    exit 1
}
$skillDirs | ForEach-Object {
    $skillName = $_.Name
    if ($skillName -eq '_shared') { return }
    $mdPath = Join-Path -Path $_.FullName -ChildPath "SKILL.md"
    if (-not (Test-Path $mdPath)) { $missingSkillMd += $skillName }
}
if ($missingSkillMd.Count -eq 0) { Write-Host " OK (all have SKILL.md)" } else { $warnings += "Skills missing SKILL.md: $($missingSkillMd -join ', ')"; Write-Host " WARN" }

# --- [3/8] SKILLS-INDEX count matches canonical ---
Write-Host "[3/8] SKILLS-INDEX count..." -NoNewline
$actualCount = ($skillDirs | Where-Object { $_.Name -ne '_shared' }).Count
$headerLine = Select-String -Path (Join-Path -Path $RepoRoot -ChildPath "SKILLS-INDEX.md") -Pattern "all \d+ skills"
if ($headerLine -match "all (\d+) skills") {
    $declared = [int]$Matches[1]
    if ($declared -eq $actualCount) { Write-Host " OK ($actualCount)" } else { $errors += "SKILLS-INDEX says $declared but canonical has $actualCount"; Write-Host " FAIL (says $declared, actual $actualCount)" }
} else { $warnings += "SKILLS-INDEX header format unexpected"; Write-Host " WARN" }

# --- [4/8] Global junctions exist for each skill ---
Write-Host "[4/8] Global junctions..." -NoNewline
$missingGlobal = @()
if (Test-Path $globalDir) {
    Get-ChildItem $canonicalDir -Directory | Where-Object { $_.Name -ne '_shared' } | ForEach-Object {
        $skillName = $_.Name
        $globalPath = Join-Path -Path $globalDir -ChildPath $skillName
        if (-not (Test-Path $globalPath)) { $missingGlobal += $skillName }
    }
}
if ($missingGlobal.Count -eq 0) { Write-Host " OK (all in global)" } else { $warnings += "Missing global junctions: $($missingGlobal -join ', ')"; Write-Host " WARN" }

# --- [5/8] _shared references resolve ---
Write-Host "[5/8] _shared refs..." -NoNewline
$sharedFiles = @{
    'skill-resolver.md' = Test-Path (Join-Path -Path $canonicalDir -ChildPath "_shared\skill-resolver.md")
    'sdd-phase-common.md' = Test-Path (Join-Path -Path $canonicalDir -ChildPath "sdd\references\sdd-phase-common.md")
    'persistence-contract.md' = Test-Path (Join-Path -Path $canonicalDir -ChildPath "_shared\persistence-contract.md")
    'engram-convention.md' = Test-Path (Join-Path -Path $canonicalDir -ChildPath "_shared\engram-convention.md")
}
$missingShared = @($sharedFiles.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key })
if ($missingShared.Count -eq 0) { Write-Host " OK" } else { $errors += "Missing _shared files: $($missingShared -join ', ')"; Write-Host " FAIL" }

# --- [6/8] Cross-Refs in skills point to real skills ---
Write-Host "[6/8] Cross-refs to real skills..." -NoNewline
$brokenRefs = @()
$allSkillNames = ($skillDirs | Where-Object { $_.Name -ne '_shared' } | ForEach-Object { $_.Name.ToLower() })
$refPattern = 'Cross-Refs:\s*(.+)'
$apPattern = 'Anti-Patterns:\s*(.+)'
Get-ChildItem $canonicalDir -Directory | Where-Object { $_.Name -ne '_shared' } | ForEach-Object {
    $skillName = $_.Name
    $mdPath = Join-Path -Path $_.FullName -ChildPath "SKILL.md"
    if (-not (Test-Path $mdPath)) { return }
    try {
        $content = Get-Content $mdPath -Raw
    } catch {
        Write-Debug "cross-ref: cannot read $mdPath ($($_.Exception.Message))"
        return
    }
    if (-not $content) { return }
    # Check Cross-Refs: line — only match single-word hyphens (skill names)
    if ($content -match $refPattern) {
        $refs = $Matches[1] -split '\s*[\|,]\s*' | ForEach-Object { $_.Trim() } | Where-Object { $_ -cmatch '^[a-z][a-z0-9_-]+$' }
        foreach ($ref in $refs) {
            $refLower = $ref.ToLower()
            if ($allSkillNames -notcontains $refLower) {
                $brokenRefs += "$skillName cross-refs '$ref' which doesn't exist"
            }
        }
    }
    # Check Anti-Patterns: line — skip multi-word descriptors, only match skill names
    if ($content -match $apPattern) {
        $aps = $Matches[1] -split '\s*[\|,]\s*' | ForEach-Object { $_.Trim() } | Where-Object { $_ -cmatch '^[a-z][a-z0-9_-]+$' }
        foreach ($ap in $aps) {
            $apLower = $ap.ToLower()
            if ($allSkillNames -notcontains $apLower) {
                $brokenRefs += "$skillName anti-pattern references '$ap' which doesn't exist"
            }
        }
    }
}
if ($brokenRefs.Count -eq 0) { Write-Host " OK" } else { $errors += $brokenRefs; Write-Host " FAIL ($($brokenRefs.Count) broken)" }

# --- [7/8] config_refs in skill metadata point to real files ---
Write-Host "[7/8] config_refs to real files..." -NoNewline
$missingConfig = @()
$configRefPattern = 'config_refs:\s*(.+)'
Get-ChildItem $canonicalDir -Directory | Where-Object { $_.Name -ne '_shared' } | ForEach-Object {
    $skillName = $_.Name
    $mdPath = Join-Path -Path $_.FullName -ChildPath "SKILL.md"
    if (-not (Test-Path $mdPath)) { return }
    try {
        $content = Get-Content $mdPath -Raw -Encoding UTF8
    } catch {
        Write-Debug "cross-ref: cannot read $mdPath ($($_.Exception.Message))"
        return
    }
    if (-not $content) { return }
    if ($content -match $configRefPattern) {
        $refs = $Matches[1] -split '\s*[\|,]\s*' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        foreach ($ref in $refs) {
            $refPath = Join-Path $RepoRoot $ref
            if (-not (Test-Path $refPath)) {
                $missingConfig += "$skillName config_refs '$ref' not found at $refPath"
            }
        }
    }
}
if ($missingConfig.Count -eq 0) { Write-Host " OK" } else { $errors += $missingConfig; Write-Host " FAIL ($($missingConfig.Count) missing)" }

# --- [8/8] review-rules.jsonc integrity ---
Write-Host "[8/8] review-rules.jsonc..." -NoNewline
$rulesPath = Join-Path $RepoRoot "review-rules.jsonc"
if (Test-Path $rulesPath) {
    try {
        $raw = Get-Content $rulesPath -Raw -Encoding UTF8
        $stripped = $raw -replace '(?m)^\s*//.*$','' -replace '(?m)\s*//[^"\n]*$','' -replace '(?s)/\*.*?\*/',''
        $parsed = $stripped | ConvertFrom-Json
        $zoneCount = $parsed.zones.PSObject.Properties.Name.Count
        $ctxCount = $parsed.context_zones.PSObject.Properties.Name.Count
        $modeCount = $parsed.modes.PSObject.Properties.Name.Count
        $profCount = $parsed.jd_profiles.PSObject.Properties.Name.Count
        $selCount = $parsed.jd_profile_selector.Count
        $issues = @()
        if ($zoneCount -ne 3) { $issues += "Expected 3 zones, found $zoneCount" }
        if ($ctxCount -ne 4) { $issues += "Expected 4 context zones, found $ctxCount" }
        if ($modeCount -ne 5) { $issues += "Expected 5 modes, found $modeCount" }
        if ($profCount -lt 1) { $issues += "Expected >=1 jd_profiles, found $profCount" }
        if ($selCount -lt 1) { $issues += "Expected >=1 jd_profile_selector, found $selCount" }
        if ($issues.Count -eq 0) { Write-Host " OK (3 zones, 4 context, 5 modes, $profCount profiles, $selCount selectors)" } else { $errors += "review-rules.jsonc: $($issues -join '; ')"; Write-Host " FAIL" }
    } catch { $errors += "review-rules.jsonc parse error: $_"; Write-Host " FAIL" }
} else { $warnings += "review-rules.jsonc not found at repo root"; Write-Host " WARN (not found)" }

# --- Summary ---
$result = @{
    timestamp = (Get-Date -Format "o")
    canonicalSkills = $actualCount
    errors = $errors
    warnings = $warnings
    brokenCrossRefs = $brokenRefs.Count
    allClean = ($errors.Count -eq 0 -and $warnings.Count -eq 0)
}

Write-Host "`n=== Results ===" -ForegroundColor Cyan
if ($Json) {
    Write-Output ($result | ConvertTo-Json -Depth 2)
} elseif ($result.allClean) {
    Write-Host "OK ALL CHECKS PASSED" -ForegroundColor Green
    exit 0
} else {
    if ($errors.Count -gt 0) { Write-Host "ERRORS ($($errors.Count)):" -ForegroundColor Red; $errors | ForEach-Object { Write-Host "  * $_" -ForegroundColor Red } }
    if ($warnings.Count -gt 0) { Write-Host "WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow; $warnings | ForEach-Object { Write-Host "  * $_" -ForegroundColor Yellow } }
    if ($errors.Count -gt 0) { exit 1 } else { exit 0 }
}
