<#
.SYNOPSIS
  Validate internal references in gentleman-agent-gh repo.
  Checks skills, SKILLS-INDEX, global junctions, and shared refs.

.DESCRIPTION
  Post-migration (skills/ → .agents/skills/) validator.
  Returns 0 = clean, 1 = issues found.

.PARAMETER RepoRoot
  Root of the repo. Defaults to script parent dir.

.EXAMPLE
  .\scripts\cross-ref-check.ps1
  .\scripts\cross-ref-check.ps1 -Json
#>

param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),
    [switch]$Json
)

$errors = @()
$warnings = @()

$canonicalDir = Join-Path -Path $RepoRoot -ChildPath ".agents\skills"
$globalDir = "$env:USERPROFILE\.config\opencode\skills"

Write-Host "=== Cross-Ref Check: $RepoRoot ===" -ForegroundColor Cyan

# --- [1/5] ANTI-PATTERN-CATALOG ---
Write-Host "`n[1/5] ANTI-PATTERN-CATALOG..." -NoNewline
$apc = Test-Path (Join-Path -Path $RepoRoot -ChildPath "ANTI-PATTERN-CATALOG.md")
if ($apc) { Write-Host " OK" } else { $errors += "ANTI-PATTERN-CATALOG.md not found at repo root"; Write-Host " FAIL" }

# --- [2/5] All skills have SKILL.md ---
Write-Host "[2/5] SKILL.md files..." -NoNewline
$missingSkillMd = @()
Get-ChildItem (Join-Path -Path $canonicalDir -ChildPath "*") -Directory | ForEach-Object {
    $skillName = $_.Name
    if ($skillName -eq '_shared') { return }
    $mdPath = Join-Path -Path $_.FullName -ChildPath "SKILL.md"
    if (-not (Test-Path $mdPath)) { $missingSkillMd += $skillName }
}
if ($missingSkillMd.Count -eq 0) { Write-Host " OK (all have SKILL.md)" } else { $warnings += "Skills missing SKILL.md: $($missingSkillMd -join ', ')"; Write-Host " WARN" }

# --- [3/5] SKILLS-INDEX count matches canonical ---
Write-Host "[3/5] SKILLS-INDEX count..." -NoNewline
$actualCount = (Get-ChildItem $canonicalDir -Directory | Where-Object { $_.Name -ne '_shared' }).Count
$headerLine = Select-String -Path (Join-Path -Path $RepoRoot -ChildPath "SKILLS-INDEX.md") -Pattern "all \d+ skills"
if ($headerLine -match "all (\d+) skills") {
    $declared = [int]$Matches[1]
    if ($declared -eq $actualCount) { Write-Host " OK ($actualCount)" } else { $errors += "SKILLS-INDEX says $declared but canonical has $actualCount"; Write-Host " FAIL (says $declared, actual $actualCount)" }
} else { $warnings += "SKILLS-INDEX header format unexpected"; Write-Host " WARN" }

# --- [4/5] Global junctions exist for each skill ---
Write-Host "[4/5] Global junctions..." -NoNewline
$missingGlobal = @()
if (Test-Path $globalDir) {
    Get-ChildItem $canonicalDir -Directory | Where-Object { $_.Name -ne '_shared' } | ForEach-Object {
        $skillName = $_.Name
        $globalPath = Join-Path -Path $globalDir -ChildPath $skillName
        if (-not (Test-Path $globalPath)) { $missingGlobal += $skillName }
    }
}
if ($missingGlobal.Count -eq 0) { Write-Host " OK (all in global)" } else { $warnings += "Missing global junctions: $($missingGlobal -join ', ')"; Write-Host " WARN" }

# --- [5/5] _shared references resolve ---
Write-Host "[5/5] _shared refs..." -NoNewline
$sharedFiles = @{
    'skill-resolver.md' = Test-Path (Join-Path -Path $canonicalDir -ChildPath "_shared\skill-resolver.md")
    'sdd-phase-common.md' = Test-Path (Join-Path -Path $canonicalDir -ChildPath "_shared\sdd-phase-common.md")
    'persistence-contract.md' = Test-Path (Join-Path -Path $canonicalDir -ChildPath "_shared\persistence-contract.md")
    'engram-convention.md' = Test-Path (Join-Path -Path $canonicalDir -ChildPath "_shared\engram-convention.md")
}
$missingShared = $sharedFiles.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key }
if ($missingShared.Count -eq 0) { Write-Host " OK" } else { $errors += "Missing _shared files: $($missingShared -join ', ')"; Write-Host " FAIL" }

# --- Summary ---
$result = @{
    timestamp = (Get-Date -Format "o")
    canonicalSkills = $actualCount
    errors = $errors
    warnings = $warnings
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
