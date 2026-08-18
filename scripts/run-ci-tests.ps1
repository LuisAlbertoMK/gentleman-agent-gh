#requires -Version 5.1
<#
.SYNOPSIS
    Central CI test runner — robust Pester invocation for pipelines (pattern R3).

.DESCRIPTION
    Runs the Pester suite with:
      - Run.Exit = $true  (non-zero exit on ANY failure — CI reads the exit code)
      - NUnit XML test results for pipeline publishing (actions/upload-artifact)
      - CodeCoverage output (JaCoCo-compatible XML) when requested
    Thin CI pipeline: workflows call THIS script instead of inlining Pester config.
    Reusable locally: `./scripts/run-ci-tests.ps1 -Path ./scripts/tests`

.PARAMETER Path
    Test root to run (default: ./scripts/tests).

.PARAMETER OutputDir
    Where to write testResults.xml / coverage.xml (default: ./test-results).

.PARAMETER WithCoverage
    Enable CodeCoverage collection and emit coverage.xml.

.EXAMPLE
    ./scripts/run-ci-tests.ps1
    ./scripts/run-ci-tests.ps1 -Path ./scripts/tests -WithCoverage
#>
[CmdletBinding()]
param(
    [string]$Path = (Join-Path $PSScriptRoot 'tests'),
    [string]$OutputDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'test-results'),
    [switch]$WithCoverage
)

$ErrorActionPreference = 'Stop'

# Pinned Pester — a new Pester release must never silently change CI behavior (R3).
$PesterVersion = '5.5.0'
if (-not (Get-Module -ListAvailable -Name Pester | Where-Object Version -eq $PesterVersion)) {
    Write-Warning "Pester $PesterVersion not found — installing (pinned)."
    Install-Module -Name Pester -RequiredVersion $PesterVersion -Force -SkipPublisherCheck -Scope CurrentUser
}
Import-Module Pester -RequiredVersion $PesterVersion -Force

if (-not (Test-Path $Path)) {
    Write-Error "Test path not found: $Path"
    exit 2
}
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

$config = New-PesterConfiguration
$config.Run.Path       = (Resolve-Path $Path).Path
$config.Run.Exit       = $true              # non-zero exit on failure — CI depends on this
$config.Run.PassThru   = $true
$config.Output.Verbosity = 'Normal'

$config.TestResult.Enabled      = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath   = (Join-Path $OutputDir 'testResults.xml')

if ($WithCoverage) {
    $config.CodeCoverage.Enabled    = $true
    $config.CodeCoverage.OutputPath = (Join-Path $OutputDir 'coverage.xml')
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
}

$results = Invoke-Pester -Configuration $config

# Run.Exit guarantees non-zero exit on failure; explicit guard reinforces contract.
if ($results.FailedCount -gt 0) {
    Write-Error "Pester: $($results.FailedCount) failed / $($results.TotalCount) total"
    exit 1
}
Write-Output "OK: $($results.PassedCount)/$($results.TotalCount) Pester tests passed (exit 0)"
exit 0