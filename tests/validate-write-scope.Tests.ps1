#requires -Version 7
Describe "validate-write-scope.ps1" {
  BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot "..\scripts\validate-write-scope.ps1"
    # Clean untracked files so scope validation tests get a predictable baseline
    git clean -fd -q 2>$null
    # T1/T3 assert CLEAN "on no changes" — a dirty live worktree (WIP files outside the
    # allowed patterns, e.g. .agents/skills/*, README.md) makes them exit 1 spuriously.
    # Isolate them in a throwaway temp repo (same pattern as
    # scripts/tests/validate-write-scope.Integration.Tests.ps1).
    $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "vws-tests-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:tempRoot -Force -ErrorAction Stop | Out-Null
    git -C $script:tempRoot init -q
    git -C $script:tempRoot config core.autocrlf false
    git -C $script:tempRoot config user.email "test@gentleman.test"
    git -C $script:tempRoot config user.name "Gentleman Test"
    New-Item -ItemType File -Path (Join-Path $script:tempRoot "dummy.txt") -Force | Out-Null
    git -C $script:tempRoot add -A
    git -C $script:tempRoot commit -m "initial" -q
  }

  AfterAll {
    if (Test-Path $script:tempRoot) {
      Remove-Item -Path $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
  }

  It "T1 accepts string[] form, CLEAN on no changes" {
    $r = & $scriptPath -AllowedPaths @("mejora-log.md","adr/*","scripts/*.ps1","tests/*") -BaseRef HEAD -RepoRoot $script:tempRoot 2>&1
    $LASTEXITCODE | Should -Be 0
    ($r -join "`n") | Should -Match '\[CLEAN\]'
  }

  It "T2 staged VIOLATION (file outside allowed patterns)" {
    $scratch = "tests/_scratch_vws.txt"
    "x" | Set-Content -Path $scratch
    try {
      git add $scratch 2>$null
      $o = & $scriptPath -AllowedPaths @("zzz/nonexistent/*") -Staged -BaseRef HEAD 2>&1
      $LASTEXITCODE | Should -Be 1
      ($o -join "`n") | Should -Match '\[VIOLATION\]'
    } finally {
      git reset --quiet -- $scratch 2>$null
      if (Test-Path $scratch) { Remove-Item -LiteralPath $scratch -Force }
    }
  }

  It "T3 comma-separated string back-compat CLEAN" {
    $r = & $scriptPath -AllowedPaths "mejora-log.md,adr/*,scripts/*.ps1,tests/*" -BaseRef HEAD -RepoRoot $script:tempRoot 2>&1
    $LASTEXITCODE | Should -Be 0
    ($r -join "`n") | Should -Match '\[CLEAN\]'
  }

  It "T4 empty allowed-paths fails CLOSED (exit 1)" {
    $r = & $scriptPath -AllowedPaths @() -BaseRef HEAD 2>&1
    $LASTEXITCODE | Should -Be 1
    ($r -join "`n") | Should -Match 'ERROR'
  }

  It "T5 untracked file violation shows type label and suggestion" {
    $scratch = "tests/_scratch_vws_untracked.txt"
    "x" | Set-Content -Path $scratch
    try {
      $o = & $scriptPath -AllowedPaths @("zzz/nonexistent/*") -BaseRef HEAD 2>&1
      $LASTEXITCODE | Should -Be 1
      $out = ($o -join "`n")
      $out | Should -Match 'untracked \(new\)'
      $out | Should -Match 'Suggestion:'
    } finally {
      if (Test-Path $scratch) { Remove-Item -LiteralPath $scratch -Force }
    }
  }

  It "T6 JSON violation includes enriched fields (type, reason, suggestion)" {
    $scratch = "tests/_scratch_vws_json.txt"
    "x" | Set-Content -Path $scratch
    try {
      $o = & $scriptPath -AllowedPaths @("zzz/nonexistent/*") -BaseRef HEAD -Json 2>&1
      $LASTEXITCODE | Should -Be 1
      $json = $o -join "`n" | ConvertFrom-Json
      $json.status | Should -Be "VIOLATION"
      $json.violations[0].type | Should -BeIn @("untracked", "modified")
      $json.violations[0].reason | Should -Match 'No AllowedPaths pattern matched'
      $json.violations[0].suggestion | Should -Match 'Add pattern'
    } finally {
      if (Test-Path $scratch) { Remove-Item -LiteralPath $scratch -Force }
    }
  }
}
