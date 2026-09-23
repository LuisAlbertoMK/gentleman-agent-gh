#requires -Version 7
BeforeAll {
  $script:ScriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'skills-audit-check.ps1'
  $script:GoodSkill = @'
---
name: fixture-good
description: "Fixture skill that passes every audit rule for testing."
triggers: "fixture, test audit"
changelog: "2026-09-23 test fixture"
token_budget: 2000
---
## Workflow
Do fixture things in order.
## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "skip the check" | No output at all | Run check, STOP if empty |
| "eyeball it" | No file:line cite | Cite file:line per finding |
## Red Flags
- Empty output with no error → STOP, re-run with -Verbose
## Verification
- `skills-audit-check.ps1 -SkillName fixture-good` exits 0
→ docs/skills/fixture-good/reference.md · Cross-Refs: fixture-other
'@
  function New-FixtureSkill {
    param([string]$Root, [string]$Name, [string]$Content, [switch]$WithRefs)
    $dir = Join-Path $Root $Name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dir 'SKILL.md') -Value $Content -Encoding UTF8
    if ($WithRefs) { New-Item -ItemType Directory -Path (Join-Path $dir 'references') -Force | Out-Null }
    return $dir
  }
  function Invoke-Audit {
    param([string]$Root, [string]$Name)
    $expected = Join-Path (Split-Path $PSScriptRoot -Parent) 'skills-audit-check.ps1'
    if ($script:ScriptPath -ne $expected) { throw "Blocked: ScriptPath outside allowlist: $script:ScriptPath" }
    $out = & $script:ScriptPath -SkillName $Name -SkillsRoot $Root -Json | Out-String
    return ($out | ConvertFrom-Json)
  }
}

Describe 'skills-audit-check.ps1' {
  It 'parses without errors' {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$tokens, [ref]$errors) | Out-Null
    $errors.Count | Should -Be 0
  }

  It 'PASS: conforme skill passes 10/10' {
    $root = Join-Path $TestDrive 'pass'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    New-FixtureSkill -Root $root -Name 'fixture-good' -Content $script:GoodSkill -WithRefs
    $r = Invoke-Audit -Root $root -Name 'fixture-good'
    $r.AllPass | Should -BeTrue
    $r.Passed | Should -Be 10
  }

  It 'FAIL A1: name mismatch' {
    $root = Join-Path $TestDrive 'a1'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    New-FixtureSkill -Root $root -Name 'fixture-good' -Content ($script:GoodSkill -replace 'name: fixture-good','name: wrong-name') -WithRefs
    $r = Invoke-Audit -Root $root -Name 'fixture-good'
    $r.AllPass | Should -BeFalse
    ($r.Rules | Where-Object { $_.Rule -eq 'A1-name' }).Pass | Should -BeFalse
  }

  It 'FAIL A2: empty description' {
    $root = Join-Path $TestDrive 'a2'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    New-FixtureSkill -Root $root -Name 'fixture-good' -Content ($script:GoodSkill -replace 'description: "Fixture skill that passes every audit rule for testing\."','description: "x"') -WithRefs
    $r = Invoke-Audit -Root $root -Name 'fixture-good'
    ($r.Rules | Where-Object { $_.Rule -eq 'A2-description' }).Pass | Should -BeFalse
  }

  It 'FAIL A3: triggers missing' {
    $root = Join-Path $TestDrive 'a3'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $noTrig = ($script:GoodSkill -split "`n" | Where-Object { $_ -notmatch '^triggers:' }) -join "`n"
    New-FixtureSkill -Root $root -Name 'fixture-good' -Content $noTrig -WithRefs
    $r = Invoke-Audit -Root $root -Name 'fixture-good'
    ($r.Rules | Where-Object { $_.Rule -eq 'A3-triggers' }).Pass | Should -BeFalse
  }

  It 'FAIL B1: no anti-rationalization table' {
    $root = Join-Path $TestDrive 'b1'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $noB1 = ($script:GoodSkill -split "`n" | Where-Object { $_ -notmatch '^\|' -and $_ -notmatch '^## Anti-Rationalization' }) -join "`n"
    New-FixtureSkill -Root $root -Name 'fixture-good' -Content $noB1 -WithRefs
    $r = Invoke-Audit -Root $root -Name 'fixture-good'
    ($r.Rules | Where-Object { $_.Rule -eq 'B1-anti-rat' }).Pass | Should -BeFalse
  }

  It 'FAIL B2: no red flags section' {
    $root = Join-Path $TestDrive 'b2'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $noB2 = $script:GoodSkill -replace '## Red Flags\r?\n- Empty output.*\r?\n', ''
    New-FixtureSkill -Root $root -Name 'fixture-good' -Content $noB2 -WithRefs
    $r = Invoke-Audit -Root $root -Name 'fixture-good'
    ($r.Rules | Where-Object { $_.Rule -eq 'B2-red-flags' }).Pass | Should -BeFalse
  }

  It 'FAIL B3: no verification section' {
    $root = Join-Path $TestDrive 'b3'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $noB3 = $script:GoodSkill -replace '## Verification\r?\n.*\r?\n', ''
    New-FixtureSkill -Root $root -Name 'fixture-good' -Content $noB3 -WithRefs
    $r = Invoke-Audit -Root $root -Name 'fixture-good'
    ($r.Rules | Where-Object { $_.Rule -eq 'B3-verification' }).Pass | Should -BeFalse
  }

  It 'FAIL C1: token_budget missing' {
    $root = Join-Path $TestDrive 'c1'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $noC1 = ($script:GoodSkill -split "`n" | Where-Object { $_ -notmatch '^token_budget:' }) -join "`n"
    New-FixtureSkill -Root $root -Name 'fixture-good' -Content $noC1 -WithRefs
    $r = Invoke-Audit -Root $root -Name 'fixture-good'
    ($r.Rules | Where-Object { $_.Rule -eq 'C1-token-budget' }).Pass | Should -BeFalse
  }

  It 'FAIL C2: changelog missing' {
    $root = Join-Path $TestDrive 'c2'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $noC2 = ($script:GoodSkill -split "`n" | Where-Object { $_ -notmatch '^changelog:' }) -join "`n"
    New-FixtureSkill -Root $root -Name 'fixture-good' -Content $noC2 -WithRefs
    $r = Invoke-Audit -Root $root -Name 'fixture-good'
    ($r.Rules | Where-Object { $_.Rule -eq 'C2-changelog' }).Pass | Should -BeFalse
  }

  It 'FAIL C3: bloated SKILL.md over 6KB' {
    $root = Join-Path $TestDrive 'c3'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $bloat = $script:GoodSkill + ("`nLorem ipsum dolor sit amet. " * 400)
    New-FixtureSkill -Root $root -Name 'fixture-good' -Content $bloat -WithRefs
    $r = Invoke-Audit -Root $root -Name 'fixture-good'
    ($r.Rules | Where-Object { $_.Rule -eq 'C3-no-bloat' }).Pass | Should -BeFalse
  }

  It 'PASS A4: alias headings satisfy recalibrated structure' {
    $root = Join-Path $TestDrive 'a4pass'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $aliasSkill = @'
---
name: fixture-a4-pass
description: "Fixture skill proving alias headings satisfy recalibrated A4."
triggers: "fixture, alias headings"
changelog: "2026-09-23 test fixture"
token_budget: 2000
---
## Hard Rules
Never invent heading names to satisfy a checklist.
## Process
Do fixture things in order.
## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "skip the check" | No output at all | Run check, STOP if empty |
| "eyeball it" | No file:line cite | Cite file:line per finding |
## Red Flags
- Empty output with no error → STOP, re-run with -Verbose
## Verification
- `skills-audit-check.ps1 -SkillName fixture-a4-pass` exits 0
→ docs/skills/fixture-a4-pass/reference.md · Cross-Refs: fixture-other
'@
    New-FixtureSkill -Root $root -Name 'fixture-a4-pass' -Content $aliasSkill -WithRefs
    $r = Invoke-Audit -Root $root -Name 'fixture-a4-pass'
    ($r.Rules | Where-Object { $_.Rule -eq 'A4-structure' }).Pass | Should -BeTrue
    $r.AllPass | Should -BeTrue
  }

  It 'FAIL A4: thin skill without substantive sections' {
    $root = Join-Path $TestDrive 'a4fail'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $thinSkill = @'
---
name: fixture-a4-thin
description: "Fixture thin skill with only meta headings, must fail A4."
triggers: "fixture, thin skill"
changelog: "2026-09-23 test fixture"
token_budget: 2000
---
A thin skill with no substantive sections, only scaffolding.
## Red Flags
- Empty output with no error → STOP, re-run with -Verbose
## Verification
- `skills-audit-check.ps1 -SkillName fixture-a4-thin` exits 0
→ docs/skills/fixture-a4-thin/reference.md · Cross-Refs: fixture-other
'@
    New-FixtureSkill -Root $root -Name 'fixture-a4-thin' -Content $thinSkill -WithRefs
    $r = Invoke-Audit -Root $root -Name 'fixture-a4-thin'
    ($r.Rules | Where-Object { $_.Rule -eq 'A4-structure' }).Pass | Should -BeFalse
    $r.AllPass | Should -BeFalse
  }

  It 'FAIL: missing SKILL.md fails all rules' {
    $root = Join-Path $TestDrive 'missing'
    New-Item -ItemType Directory -Path (Join-Path $root 'fixture-gone') -Force | Out-Null
    $r = Invoke-Audit -Root $root -Name 'fixture-gone'
    $r.AllPass | Should -BeFalse
    $r.Passed | Should -Be 0
  }
}
