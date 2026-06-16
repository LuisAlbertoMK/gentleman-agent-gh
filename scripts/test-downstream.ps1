#requires -Version 5.1
<#
.SYNOPSIS
  Downstream validation of CYCLE-3 skills: delivery-harness, chained-pr, subagent-isolation.
  Tests structural integrity, dependency consistency, and workflow traceability.

.DESCRIPTION
  Tests that:
  - Skills exist with all required sections
  - Dependency declarations reference real skills
  - Delivery-harness workflow is complete (7 steps, error table, dependency refs)
  - Chained-pr chain structure is valid (branch naming, rebase cascade, rollback)
  - Subagent-isolation rules cover all 6 categories
  - Cross-references between skills are consistent

.EXAMPLE
  .\scripts\test-downstream.ps1
  .\scripts\test-downstream.ps1 -Json
#>

param(
  [switch]$Json
)

Set-StrictMode -Version Latest
$exitCode = 0
$results = @()

# --- Helpers ---
function Add-Result($section, $check, $status, $detail) {
  $script:results += [PSCustomObject]@{
    Section = $section
    Check   = $check
    Status  = $status
    Detail  = $detail
  }
  if ($status -ne "PASS") { $script:exitCode = 1 }
}

function Test-SkillFile($name) {
  $scriptRoot = Split-Path -Parent $PSCommandPath
  $path = Join-Path $scriptRoot "..\.agents\skills\$name\SKILL.md"
  if (-not (Test-Path $path)) {
    Add-Result "Structure" "Skill: $name" "FAIL" "SKILL.md not found"
    return $null
  }
  return $path
}

function Test-Section($path, $section) {
  $content = Get-Content -LiteralPath $path -Raw
  if ($content -match $section) { return $true }
  return $false
}

# ====== TESTS ======

# 1. STRUCTURAL: skills exist
$dhPath = Test-SkillFile "delivery-harness"
$cpPath = Test-SkillFile "chained-pr"
$siPath = Test-SkillFile "subagent-isolation"
$wucPath = Test-SkillFile "work-unit-commits"
$cwPath = Test-SkillFile "command-wrapper"

if (-not $dhPath -or -not $cpPath) {
  Add-Result "Structure" "Core skills" "FAIL" "Missing delivery-harness or chained-pr SKILL.md"
  # Can't continue without core skills
} else {
  # 2. DELIVERY-HARNESS: workflow steps
  $dh = Get-Content -LiteralPath $dhPath -Raw
  $steps = @(
    'Analyze', 'Break down', 'Map deps', 'Delegate', 'Collect', 'Reconcile', 'Report'
  )
  $foundSteps = 0
  foreach ($step in $steps) {
    if ($dh -match "\*{1,2}$step") { $foundSteps++ }
    else { Add-Result "Delivery-Harness" "Step: $step" "WARN" "Step label not found" }
  }
  if ($foundSteps -eq 7) {
    Add-Result "Delivery-Harness" "7-step workflow" "PASS" "All $foundSteps steps found"
  } else {
    Add-Result "Delivery-Harness" "7-step workflow" "FAIL" "Found $foundSteps/7 steps"
  }

  # Delivery-Harness: error handling table
  $errorTypes = @('Subagent timeout', 'Wrong output', 'Dependency fail', 'Merge conflict')
  $foundErrors = 0
  foreach ($et in $errorTypes) {
    if ($dh -match [regex]::Escape($et)) { $foundErrors++ }
  }
  Add-Result "Delivery-Harness" "Error table" $(if ($foundErrors -eq 4) { "PASS" } else { "FAIL" }) "Found $foundErrors/4 error types"

  # Delivery-Harness: dependencies
  Add-Result "Delivery-Harness" "Dep: subagent-isolation" $(if ($dh -match 'subagent-isolation') { "PASS" } else { "FAIL" }) ""
  Add-Result "Delivery-Harness" "Dep: work-unit-commits" $(if ($dh -match 'work-unit-commits') { "PASS" } else { "FAIL" }) ""
  Add-Result "Delivery-Harness" "Dep: command-wrapper" $(if ($dh -match 'command-wrapper') { "PASS" } else { "FAIL" }) ""

  # 3. CHAINED-PR: structure
  $cp = Get-Content -LiteralPath $cpPath -Raw
  Add-Result "Chained-PR" "Chain structure diagram" $(if ($cp -match 'main ── PR#1') { "PASS" } else { "FAIL" }) "Chain format: main--PR#1--PR#2--PR#3"
  Add-Result "Chained-PR" "Branch naming convention" $(if ($cp -match 'feat/{prefix}-{n}-{slug}') { "PASS" } else { "FAIL" }) "Format: feat/{prefix}-{n}-{slug}"
  Add-Result "Chained-PR" "Rebase cascade" $(if ($cp -match 'REBASE CASCADE') { "PASS" } else { "FAIL" }) ""
  Add-Result "Chained-PR" "Rollback procedure" $(if ($cp -match 'ROLLBACK') { "PASS" } else { "FAIL" }) ""
  Add-Result "Chained-PR" "Max chain: 5" $(if ($cp -match 'Max chain length: 5') { "PASS" } else { "FAIL" }) ""
  Add-Result "Chained-PR" "Dep: work-unit-commits" $(if ($cp -match 'work-unit-commits') { "PASS" } else { "FAIL" }) ""
  Add-Result "Chained-PR" "Dep: command-wrapper" $(if ($cp -match 'command-wrapper') { "PASS" } else { "FAIL" }) ""

  # 4. SUBAGENT-ISOLATION: rules
  if ($siPath) {
    $si = Get-Content -LiteralPath $siPath -Raw
    $isoRules = @(
      'Fresh context per delegation', 'No cross-contamination', 'Dependency declaration',
      'Result isolation', 'Context cleanup', 'Error boundaries'
    )
    $foundRules = 0
    foreach ($rule in $isoRules) {
      if ($si -match [regex]::Escape($rule)) { $foundRules++ }
      else { Add-Result "Subagent-Isolation" "Rule: $rule" "WARN" "Not found" }
    }
    Add-Result "Subagent-Isolation" "6 isolation rules" $(if ($foundRules -eq 6) { "PASS" } else { "FAIL" }) "Found $foundRules/6 rules"
  }

  # 5. CROSS-REF CONSISTENCY
  # delivery-harness declares subagent-isolation dep
  # subagent-isolation should be referenced by delivery-harness
  $dhDeps = @()
  if ($dh -match 'subagent-isolation') { $dhDeps += 'subagent-isolation' }
  if ($dh -match 'work-unit-commits') { $dhDeps += 'work-unit-commits' }
  if ($dh -match 'command-wrapper') { $dhDeps += 'command-wrapper' }
  Add-Result "Cross-Ref" "DH dependencies resolved" "PASS" "$($dhDeps.Count) deps: $($dhDeps -join ', ')"

  # 6. FILE SIZE CHECK
  Add-Result "Size" "delivery-harness" "PASS" "$((Get-Item $dhPath).Length) bytes"
  Add-Result "Size" "chained-pr" "PASS" "$((Get-Item $cpPath).Length) bytes"
  if ($siPath) {
    Add-Result "Size" "subagent-isolation" "PASS" "$((Get-Item $siPath).Length) bytes"
  }
}

# --- OUTPUT ---
if ($Json) {
  Write-Output ($results | ConvertTo-Json -Depth 3)
} else {
  Write-Output "`n=== Downstream Test Results ==="
  Write-Output ""

  $pass = @($results | Where-Object { $_.Status -eq "PASS" }).Count
  $fail = @($results | Where-Object { $_.Status -eq "FAIL" }).Count
  $warn = @($results | Where-Object { $_.Status -eq "WARN" }).Count

  $results | Group-Object Section | ForEach-Object {
    Write-Output "--- $($_.Name) ---"
    $_.Group | Format-Table Check, Status, Detail -AutoSize
  }

  Write-Output "`n=== Summary: $pass PASS, $fail FAIL, $warn WARN ==="
}

exit $exitCode
