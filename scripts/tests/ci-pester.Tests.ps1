#requires -Version 5.1
<#
.SYNOPSIS
    Verifies run-ci-tests.ps1 contract (Ciclo 1 — G1, pattern R3):
      1. Run.Exit is enabled (CI exit-code contract)
      2. Pester version is pinned (5.5.0)
      3. NUnit XML results are emitted
#>
param()

$ErrorActionPreference = 'Stop'

Describe 'run-ci-tests.ps1 contract' {
    It 'exists and parses' {
        # Literal repo-relative path: CI cwd = repo root (actions/checkout), local = repo root.
        $scriptPath = (Join-Path (Get-Location) 'scripts\run-ci-tests.ps1')
        Test-Path $scriptPath | Should -Be $true
        $tokens = $null; $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It 'pins Pester version (5.5.0)' {
        $scriptPath = (Join-Path (Get-Location) 'scripts\run-ci-tests.ps1')
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match "PesterVersion = '5\.5\.0'"
        $content | Should -Match 'RequiredVersion'
    }

    It 'enables Run.Exit and NUnit XML output' {
        $scriptPath = (Join-Path (Get-Location) 'scripts\run-ci-tests.ps1')
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'Run\.Exit\s*=\s*\$true'
        $content | Should -Match "OutputFormat\s*=\s*'NUnitXml'"
    }

    It 'returns non-zero exit on failure (belt-and-suspenders)' {
        $scriptPath = (Join-Path (Get-Location) 'scripts\run-ci-tests.ps1')
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'exit 1'
        $content | Should -Match 'FailedCount -gt 0'
    }
}
