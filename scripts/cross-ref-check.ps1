# cross-ref-check.ps1 — Validate internal references in gentleman-agent-gh
# Usage: powershell -File scripts\cross-ref-check.ps1 [-RepoRoot <path>]
# Returns: 0 = clean, 1 = issues found

param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent)
)

$errors = @()
$warnings = @()

Write-Host "=== Cross-Ref Check: $RepoRoot ===" -ForegroundColor Cyan

# 1. Check _shared references resolve
Write-Host "`n[1/5] Shared refs..." -NoNewline
$sharedRefs = Select-String -Path "$RepoRoot\prompts\sdd-orchestrator.md" -Pattern "_shared/skill-resolver.md" -SimpleMatch
$sharedFile = Test-Path "$RepoRoot\skills\_shared\skill-resolver.md"
if ($sharedRefs -and $sharedFile) { Write-Host " ✅" } else { Write-Host " ❌"; if (-not $sharedRefs) { $errors += "prompts/sdd-orchestrator.md: missing _shared ref" }; if (-not $sharedFile) { $errors += "skills/_shared/skill-resolver.md: file not found" } }

# 2. Check commands match skills
Write-Host "[2/5] Commands vs skills..." -NoNewline
$cmdPhases = @()
Get-ChildItem "$RepoRoot\commands\sdd-*.md" | ForEach-Object { $cmdPhases += $_.BaseName -replace 'sdd-', '' }
$skillPhases = @()
Get-ChildItem "$RepoRoot\skills\sdd-*" -Directory | ForEach-Object { $skillPhases += $_.Name -replace 'sdd-', '' }
$missingCmds = $skillPhases | Where-Object { $_ -notin $cmdPhases -and $_ -ne 'contracts' }
$extraCmds = $cmdPhases | Where-Object { $_ -notin $skillPhases }
$ok = $true
if ($missingCmds) { $warnings += "commands/ missing for: sdd-$($missingCmds -join ', sdd-')"; $ok = $false }
if ($extraCmds) { $warnings += "commands/ without skill: sdd-$($extraCmds -join ', sdd-')"; $ok = $false }
if ($ok) { Write-Host " ✅ (all ${skillPhases.Count} skills have commands)" } else { Write-Host " ⚠️" }

# 3. Check ANTI-PATTERN-CATALOG resolves
Write-Host "[3/5] ANTI-PATTERN-CATALOG..." -NoNewline
$apc = Test-Path "$RepoRoot\ANTI-PATTERN-CATALOG.md"
if ($apc) { Write-Host " ✅" } else { $errors += "ANTI-PATTERN-CATALOG.md not found at repo root"; Write-Host " ❌" }

# 4. Check all referenced SKILL.md exist
Write-Host "[4/5] Skill files referenced in commands..." -NoNewline
$missingSkills = @()
Get-ChildItem "$RepoRoot\commands\*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match 'skills/([^/]+)/SKILL\.md') {
        $skillDir = "$RepoRoot\skills\$($Matches[1])"
        if (-not (Test-Path $skillDir)) { $missingSkills += $Matches[1] }
    }
}
if (-not $missingSkills) { Write-Host " ✅" } else { $warnings += "Missing skill dirs: $($missingSkills -join ', ')"; Write-Host " ⚠️" }

# 5. Check SKILLS-INDEX count matches reality
Write-Host "[5/5] SKILLS-INDEX count..." -NoNewline
# Exclude _shared (infrastructure dir, not a skill)
$actualCount = (Get-ChildItem "$RepoRoot\skills" -Directory | Where-Object { $_.Name -ne '_shared' }).Count
$headerLine = Select-String -Path "$RepoRoot\SKILLS-INDEX.md" -Pattern "all \d+ skills"
if ($headerLine -match "all (\d+) skills") {
    $declared = [int]$Matches[1]
    if ($declared -eq $actualCount) { Write-Host " ✅ ($actualCount)" } else { $errors += "SKILLS-INDEX says $declared but actual is $actualCount"; Write-Host " ❌ (says $declared, actual $actualCount)" }
} else { $warnings += "SKILLS-INDEX header format unexpected"; Write-Host " ⚠️" }

# Summary
Write-Host "`n=== Results ===" -ForegroundColor Cyan
if (-not $errors -and -not $warnings) {
    Write-Host "✅ ALL CHECKS PASSED" -ForegroundColor Green
    exit 0
}
if ($errors) { Write-Host "❌ ERRORS ($($errors.Count)):" -ForegroundColor Red; $errors | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red } }
if ($warnings) { Write-Host "⚠️ WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow; $warnings | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow } }
if ($errors) { exit 1 } else { exit 0 }
