#requires -Version 5.1
Describe "delegation-fit-gate.ps1" {
  BeforeAll {
  }

  It "T1 quick + 1 file + 10 lines + low risk is PASS" {
    $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName gentleman-quick -FileCount 1 -LineCount 10 -RiskLevel low 2>&1
    $LASTEXITCODE | Should -Be 0
    ($r -join "`n") | Should -Match 'VERDICT: PASS'
  }

  It "T2 quick + 2 files is FAIL (quick-too-big)" {
    $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName gentleman-quick -FileCount 2 -LineCount 10 -RiskLevel low 2>&1
    $LASTEXITCODE | Should -Be 2
    ($r -join "`n") | Should -Match 'FAIL'
  }

  It "T3 quick-sub-auto + 1 file + 30 lines is FAIL (quick-too-big)" {
    $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName gentleman-quick-sub-auto -FileCount 1 -LineCount 30 -RiskLevel low -Json 2>&1
    $LASTEXITCODE | Should -Be 2
    $obj = ($r | Where-Object { $_ -match '^\{' } | Select-Object -First 1) | ConvertFrom-Json
    $obj.verdict | Should -Be 'FAIL'
    $obj.patterns | Should -Contain 'quick-too-big'
  }

  It "T4 15 files + codex-sub is FAIL (cluster-over-10)" {
    $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName gentleman-codex-sub -FileCount 15 -LineCount 200 -RiskLevel low -Json 2>&1
    $LASTEXITCODE | Should -Be 2
    $obj = ($r | Where-Object { $_ -match '^\{' } | Select-Object -First 1) | ConvertFrom-Json
    $obj.verdict | Should -Be 'FAIL'
    $obj.patterns | Should -Contain 'cluster-over-10'
  }

  It "T5 codex-sub + 3 files + 80 lines + low risk is PASS" {
    $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName gentleman-codex-sub -FileCount 3 -LineCount 80 -RiskLevel low 2>&1
    $LASTEXITCODE | Should -Be 0
    ($r -join "`n") | Should -Match 'VERDICT: PASS'
  }

  It "T6 Domain=security + codex-sub is WARN (domain-reroute)" {
    $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName gentleman-codex-sub -FileCount 3 -LineCount 80 -Domain security -Json 2>&1
    $LASTEXITCODE | Should -Be 0
    $obj = ($r | Where-Object { $_ -match '^\{' } | Select-Object -First 1) | ConvertFrom-Json
    $obj.verdict | Should -Be 'WARN'
    $obj.patterns | Should -Contain 'domain-reroute'
  }

  It "T7 Domain=security + security-sub is PASS" {
    $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName gentleman-security-sub -FileCount 3 -LineCount 80 -Domain security 2>&1
    $LASTEXITCODE | Should -Be 0
    ($r -join "`n") | Should -Match 'VERDICT: PASS'
  }

  It "T8 quick + 1 file + 10 lines + high risk is WARN (quick-high-risk)" {
    $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName gentleman-quick -FileCount 1 -LineCount 10 -RiskLevel high -Json 2>&1
    $LASTEXITCODE | Should -Be 0
    $obj = ($r | Where-Object { $_ -match '^\{' } | Select-Object -First 1) | ConvertFrom-Json
    $obj.verdict | Should -Be 'WARN'
    $obj.patterns | Should -Contain 'quick-high-risk'
  }

  It "T9 codex-sub + 6 files is WARN (over-5-files)" {
    $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName gentleman-codex-sub -FileCount 6 -LineCount 120 -RiskLevel low -Json 2>&1
    $LASTEXITCODE | Should -Be 0
    $obj = ($r | Where-Object { $_ -match '^\{' } | Select-Object -First 1) | ConvertFrom-Json
    $obj.verdict | Should -Be 'WARN'
    $obj.patterns | Should -Contain 'over-5-files'
  }

  It "T10 FAIL case exits 2" {
    $null = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName gentleman-quick -FileCount 93 -LineCount 500 2>&1
    $LASTEXITCODE | Should -Be 2
  }

  It "T11 PASS case exits 0" {
    $null = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName gentleman-codex-sub -FileCount 3 -LineCount 120 2>&1
    $LASTEXITCODE | Should -Be 0
  }

  It "T12 -Json output is valid JSON with verdict field" {
    $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName gentleman-quick -FileCount 1 -LineCount 10 -Json 2>&1
    $LASTEXITCODE | Should -Be 0
    $obj = ($r -join "`n") | ConvertFrom-Json
    $obj.verdict | Should -Be 'PASS'
  }
}

Describe "delegation-fit-gate.ps1 — cluster-path-overlap" {
  BeforeAll {
  }

  Context "PlannedPaths with duplicates → FAIL (P1 regression)" {
    It "detects duplicate path and exits 2" {
      $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName "gentleman-codex-sub" -PlannedPaths @("a/b/file1.txt", "c/d/file2.txt", "a/b/file1.txt") 2>&1
      $LASTEXITCODE | Should -Be 2
      $out = ($r -join "`n")
      $out | Should -Match 'FAIL'
      $out | Should -Match 'overlap'
      $out | Should -Match 'a/b/file1.txt'
    }

    It "reports cluster-path-overlap in JSON patterns" {
      $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName "gentleman-codex-sub" -PlannedPaths @("a/b/file1.txt", "c/d/file2.txt", "a/b/file1.txt") -Json 2>&1
      $LASTEXITCODE | Should -Be 2
      $json = ($r -join "`n") | ConvertFrom-Json
      $json.verdict | Should -Be 'FAIL'
      $json.patterns | Should -Contain 'cluster-path-overlap'
      $json.reasons[0] | Should -Match 'overlap'
    }
  }

  Context "PlannedPaths with no duplicates → PASS" {
    It "passes when all paths are unique" {
      $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName "gentleman-codex-sub" -PlannedPaths @("a/b/file1.txt", "c/d/file2.txt", "e/f/file3.txt") 2>&1
      $LASTEXITCODE | Should -Be 0
      $out = ($r -join "`n")
      $out | Should -Match 'PASS'
    }
  }

  Context "PlannedPaths empty → PASS (no throw)" {
    It "passes with empty array" {
      $r = & (Join-Path $PSScriptRoot '..' 'scripts' 'delegation-fit-gate.ps1') -AgentName "gentleman-codex-sub" -PlannedPaths @() 2>&1
      $LASTEXITCODE | Should -Be 0
    }
  }
}
