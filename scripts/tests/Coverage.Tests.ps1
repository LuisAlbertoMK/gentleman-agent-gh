#requires -Version 5.1
<#
.SYNOPSIS
    Tests for scripts/tests/Coverage.ps1 (auto-mejora v3 Ciclo 2, G2).

.DESCRIPTION
    Verifies the coverage runner contract:
      - Pins Pester 5.5.0 (same as run-ci-tests.ps1 — API shape is v5-specific)
      - -ExcludePattern filters unstable/pre-broken suites out of the run
      - -Strict + -MinimumCoverage promotes the floor to a hard gate
      - Emits JaCoCo coverage.xml + summary.json + NUnit testResults.xml

    Does NOT run the full coverage suite (slow) — validates the mechanism
    with the mutation-smoke file only.
#>

BeforeAll {
    $script:cov = Join-Path (Get-Location) 'scripts/tests/Coverage.ps1'
    if (-not (Test-Path -LiteralPath $script:cov)) {
        throw "Coverage.ps1 not found at $script:cov"
    }
    $script:testRoot = Join-Path (Get-Location) 'scripts/tests'
    $script:libRoot  = Join-Path (Get-Location) 'scripts/lib'
}

Describe 'Coverage.ps1 contract' {
    It 'pins Pester 5.5.0 (API compatibility)' {
        $content = Get-Content -LiteralPath $script:cov -Raw
        $content | Should -Match "PesterVersion = '5\.5\.0'"
    }

    It 'excludes unstable suites via -ExcludePattern (no e2e time bombs)' {
        $content = Get-Content -LiteralPath $script:cov -Raw
        $content | Should -Match "ExcludePattern"
        $content | Should -Match "e2e"
    }

    It 'supports -Strict floor enforcement' {
        $content = Get-Content -LiteralPath $script:cov -Raw
        $content | Should -Match "-Strict"
        $content | Should -Match "MinimumCoverage"
    }

    It 'emits JaCoCo coverage.xml + summary.json + NUnit XML' {
        $content = Get-Content -LiteralPath $script:cov -Raw
        $content | Should -Match "OutputFormat = 'JaCoCo'"
        $content | Should -Match "coverage\.xml"
        $content | Should -Match "summary\.json"
        $content | Should -Match "testResults\.xml"
    }
}

Describe 'Coverage.ps1 runs (smoke, mutation-smoke file only)' {
    It 'runs 4/4 pass with Strict threshold 0 on the mutation-smoke file' {
        # Child process: Coverage.ps1 invokes Invoke-Pester internally — running
        # it inside a live Pester session would collide with the active runtime
        # (Pester.Factory shared state). A child pwsh keeps runtimes isolated.
        $pwshPath = (Get-Process -Id $PID).Path
        $reportDir = Join-Path $env:TEMP ('cov-contract-test-' + [guid]::NewGuid().ToString('N'))
        $args = @(
            '-NoProfile', '-File', $script:cov,
            '-TestPath', (Join-Path $script:testRoot 'mutation-smoke.Tests.ps1'),
            '-CoverageRootPath', $script:libRoot,
            '-Strict', '-MinimumCoverage', '0',
            '-ReportDir', $reportDir
        )
        $proc = Start-Process -FilePath $pwshPath -ArgumentList $args -Wait -PassThru -NoNewWindow
        $proc.ExitCode | Should -Be 0
        # Sanity: report artifacts were emitted
        (Test-Path -LiteralPath (Join-Path $reportDir 'summary.json')) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $reportDir 'coverage.xml')) | Should -BeTrue
    }
}
