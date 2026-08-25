#requires -Version 7
<#
.SYNOPSIS
    Tests for scripts/adversarial-review.ps1 (auto-mejora v3 Ciclo 3, G3).

.DESCRIPTION
    Verifies the structured-severity review wrapper contract:
      - Emits JSON findings with R1 taxonomy (critical/warning/suggestion)
      - Maps breaker block -> critical, warn -> warning
      - Deduplicates by (rule, file)
      - Exit 0 without criticals, 1 with criticals
      - -SeverityFilter narrows output

    Uses a fixture staged ONCE in BeforeAll so the breaker's `git diff --cached`
    scan sees a real violation. Staging is restored in AfterAll. Pester runs
    tests in parallel by default — staging once avoids add/restore races.
#>

BeforeAll {
    $script:review = Join-Path (Get-Location) 'scripts/adversarial-review.ps1'
    if (-not (Test-Path -LiteralPath $script:review)) {
        throw "adversarial-review.ps1 not found at $script:review"
    }
    $script:fixture = Join-Path (Get-Location) 'scripts/tests/fixtures/adversarial-fixture.ps1'
    if (-not (Test-Path -LiteralPath $script:fixture)) {
        throw "fixture not found: $script:fixture"
    }
    # Snapshot original content so AfterAll can restore it byte-for-byte.
    $script:fixtureBackup = Get-Content -LiteralPath $script:fixture -Raw
    # The breaker scans `git diff --cached --diff-filter=ACM`. A cleanly committed,
    # unchanged fixture does NOT appear in that diff -> breaker misses it. Force the
    # fixture into the staged diff by applying a no-op timestamp line and re-adding,
    # so the breaker reliably sees the iex violation and reports a critical finding.
    # (Pester runs tests in parallel -> stage ONCE here to avoid add/restore races.)
    $ts = '# test-run:' + (Get-Date -Format o)
    $patched = "$ts`n" + $script:fixtureBackup
    Set-Content -LiteralPath $script:fixture -Value $patched -Encoding UTF8
    git add -- $script:fixture
    if ($LASTEXITCODE -ne 0) { throw "could not stage fixture: $script:fixture" }
}

AfterAll {
    # Restore the fixture to its committed content and unstage it so it never
    # leaks into a commit (the fixture is test-only scaffolding).
    try { git reset -q HEAD -- $script:fixture 2>$null } catch {}
    try { git restore --staged -- $script:fixture 2>$null } catch {}
    try { git checkout -- $script:fixture 2>$null } catch {}
    # If checkout failed (no staged change), rewrite from backup to be safe.
    if ((Get-Content -LiteralPath $script:fixture -Raw) -ne $script:fixtureBackup) {
        Set-Content -LiteralPath $script:fixture -Value $script:fixtureBackup -Encoding UTF8
    }
}

Describe 'adversarial-review: severity taxonomy (R1)' {
    It 'emits JSON findings with uniform severity field' {
        $out = & $script:review -Quiet 2>&1 | Out-String
        $findings = @($out | ConvertFrom-Json)
        $findings | Should -Not -BeNullOrEmpty
        foreach ($f in $findings) {
            $f.severity | Should -BeIn 'critical', 'warning', 'suggestion'
            $f.rule | Should -Not -BeNullOrEmpty
            $f.file | Should -Not -BeNullOrEmpty
        }
    }

    It 'maps breaker block severity to critical' {
        $out = & $script:review -Quiet -SeverityFilter critical 2>&1 | Out-String
        $findings = @($out | ConvertFrom-Json)
        $findings | Should -Not -BeNullOrEmpty
        foreach ($f in $findings) {
            $f.severity | Should -Be 'critical'
            $f.rule | Should -Match 'PS-(CI|CE)-'
        }
    }
}

Describe 'adversarial-review: dedup and exit code' {
    It 'deduplicates findings by (rule, file)' {
        $out = & $script:review -Quiet 2>&1 | Out-String
        $findings = @($out | ConvertFrom-Json)
        $keys = @($findings | ForEach-Object { "$($_.rule)|$($_.file)" })
        $keys.Count | Should -Be @($keys | Sort-Object -Unique).Count
    }

    It 'exits 1 when criticals present, 0 when filtered out' {
        & $script:review -Quiet 2>$null | Out-Null
        $exitAll = $LASTEXITCODE
        & $script:review -Quiet -SeverityFilter suggestion 2>$null | Out-Null
        $exitSuggestions = $LASTEXITCODE
        $exitAll | Should -Be 1
        $exitSuggestions | Should -Be 0
    }
}
