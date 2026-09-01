#requires -Version 5.1
# Pester tests for scripts/context-watchdog-check.ps1 — P0-1 parte 3/3 wiring
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'context-watchdog-check.ps1' {
    BeforeAll {
        $script:ScriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'context-watchdog-check.ps1'
    }

    It 'parses without errors' {
        $errs = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errs)
        $errs | Should -BeNullOrEmpty
    }

    It 'NONE below 40% — no node' {
        $env:PESTER_TEST = '1'
        $out = & $script:ScriptPath -CurrentTokens 60000 -Budget 200000 -Reason periodic *>&1 | Out-String
        $out | Should -Match 'no escalation'
        $out | Should -Match 'NONE'
    }

    It 'L2 at 72% dry-runs without DAG persistence' {
        $env:PESTER_TEST = '1'
        $out = & $script:ScriptPath -CurrentTokens 145000 -Budget 200000 -Reason pre-output -Content 'test summary L2' *>&1 | Out-String
        $out | Should -Match 'L2'
        $out | Should -Match 'dry run'
    }

    It 'L3 escalates with default pointer' {
        $env:PESTER_TEST = '1'
        $out = & $script:ScriptPath -CurrentTokens 170000 -Budget 200000 -Reason pre-tool -Content 'red zone summary' *>&1 | Out-String
        $out | Should -Match 'L3'
    }
}
