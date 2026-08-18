#requires -Version 5.1
<#
.SYNOPSIS
    Coverage-aware Pester runner for the gentleman-agent-gh repo (auto-mejora v3 Ciclo 2).

.DESCRIPTION
    Pins Pester 5.5.0 (same as run-ci-tests.ps1, pattern R3) and runs the
    Pester suite with CodeCoverage over scripts/**/*.ps1 (excluding tests),
    emitting JaCoCo-compatible coverage.xml + a summary JSON + console report.

    Coverage is MEASURE-ONLY by default: a low baseline never breaks CI.
    Pass -Strict to promote the floor to a hard gate (ratcheting upward,
    mirroring the deadcode-ratchet philosophy).

    Addresses G2 (auto-mejora v3): no coverage gate nor mutation score in
    pipeline. Job coverage in ci.yml publishes coverage.xml and fails when
    coverage < -MinimumCoverage with -Strict.

    Usage in CI (unit-only subset, avoids e2e time bombs):
      ./scripts/tests/Coverage.ps1 -TestPath ./scripts/tests/unit-coverage.txt `
        -Strict -MinimumCoverage 40 -ReportDir ./test-results
#>
[CmdletBinding()]
param(
    [string]$TestPath = './scripts/tests/*.Tests.ps1',
    [string]$CoverageRootPath = './scripts',
    [string]$ReportDir = './scripts/tests/_coverage',
    [int]$MinimumCoverage = 0,
    [string]$ExcludePattern = 'e2e|Integration|session-checkpoint|skill-coverage|ui-specialist|subagent',
    [switch]$Strict
)
$ErrorActionPreference = 'Stop'

# Pinned Pester — API shape (CodeCoverage.Path) is v5-specific; never let a
# system Pester 6 silently change measurement semantics (R3).
$PesterVersion = '5.5.0'
if (-not (Get-Module -ListAvailable -Name Pester | Where-Object Version -eq $PesterVersion)) {
    Write-Warning "Pester $PesterVersion not found — installing (pinned)."
    Install-Module -Name Pester -RequiredVersion $PesterVersion -Force -SkipPublisherCheck -Scope CurrentUser
}
Import-Module Pester -RequiredVersion $PesterVersion -Force

# Scripts to instrument: root + lib, excluding tests and the coverage output.
$coverageFiles = Get-ChildItem -Path $CoverageRootPath -Filter '*.ps1' -Recurse -File |
    Where-Object { $_.FullName -notmatch 'tests' -and $_.FullName -notmatch '_coverage' }

$config = New-PesterConfiguration

# Resolve test paths: a directory runs its *.Tests.ps1 minus excluded files;
# a file/glob runs as-is. Keeps the CI job stable (no e2e time bombs).
if (Test-Path -LiteralPath $TestPath -PathType Container) {
    $testFiles = Get-ChildItem -LiteralPath $TestPath -Filter '*.Tests.ps1' -File |
        Where-Object { $_.Name -notmatch $ExcludePattern } |
        ForEach-Object { $_.FullName }
    if (-not $testFiles) { Write-Error "No test files matched in $TestPath (exclude: $ExcludePattern)"; exit 2 }
    $config.Run.Path = $testFiles
} else {
    $config.Run.Path = (Resolve-Path $TestPath).Path
}
$config.Run.Exit       = $true
$config.Run.PassThru   = $true
$config.Output.Verbosity = 'Normal'
$config.CodeCoverage.Enabled    = $true
$config.CodeCoverage.Path       = @($coverageFiles.FullName)
$config.CodeCoverage.OutputPath = (Join-Path $ReportDir 'coverage.xml')
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.TestResult.Enabled      = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath   = (Join-Path $ReportDir 'testResults.xml')

# Ensure report dir exists
$null = New-Item -ItemType Directory -Path $ReportDir -Force -ErrorAction SilentlyContinue

Write-Output "`n=== Running Pester with code-coverage (Pester $PesterVersion) ==="
$results = Invoke-Pester -Configuration $config

# Test failures are a hard break (preserves existing CI behavior)
if ($results.FailedCount -gt 0) {
    Write-Error "Pester: $($results.FailedCount) test(s) failed"
    exit 1
}

# Coverage summary (measure-only unless -Strict)
$coveragePct = $null
if ($results.CodeCoverage -and $null -ne $results.CodeCoverage.CoveragePercent) {
    $coveragePct = [math]::Round($results.CodeCoverage.CoveragePercent, 2)
}

$summary = [ordered]@{
    timestamp    = (Get-Date).ToString('o')
    tests_passed = $results.PassedCount
    tests_failed = $results.FailedCount
    tests_total  = $results.TotalCount
    coverage_pct = $coveragePct
    threshold    = $MinimumCoverage
    strict       = [bool]$Strict
}
$summary | ConvertTo-Json -Compress |
    Set-Content -Path "$ReportDir/summary.json" -Encoding UTF8

if ($null -ne $coveragePct) {
    if ($coveragePct -lt $MinimumCoverage) {
        $msg = "COVERAGE: $($coveragePct)% is below the $MinimumCoverage% floor"
        if ($Strict) { Write-Error $msg; exit 1 }
        Write-Warning "$msg -- measure-only (pass -Strict to enforce)"
    }
    Write-Output "OK: $($results.PassedCount)/$($results.TotalCount) tests passed -- coverage $($coveragePct)%"
} else {
    Write-Output "OK: $($results.PassedCount)/$($results.TotalCount) tests passed -- coverage N/A (no instrumented files hit)"
}

exit 0
