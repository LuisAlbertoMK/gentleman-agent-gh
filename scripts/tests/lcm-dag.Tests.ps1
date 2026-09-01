#requires -Version 5.1
# Pester tests for scripts/lcm-dag.ps1 — P0-1 parte 2/3 (DAG + escalation + PESTER_TEST isolation)
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'lcm-dag.ps1' {
    BeforeAll {
        $script:ScriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'lcm-dag.ps1'
        $script:TmpDag = Join-Path ([System.IO.Path]::GetTempPath()) ("lcm-dag-test-{0}.json" -f [guid]::NewGuid().ToString('N').Substring(0,8))
    }
    AfterAll { if (Test-Path $script:TmpDag) { Remove-Item $script:TmpDag -Force -ErrorAction SilentlyContinue } }

    It 'parses without errors' {
        $errs = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errs)
        $errs | Should -BeNullOrEmpty
    }

    It 'escalation thresholds match watchdog zones' {
        $env:PESTER_TEST = '1'
        . $script:ScriptPath
        Invoke-LcmEscalation -CurrentTokens 70000 -Budget 200000 | Should -Be 'NONE'   # 35%
        Invoke-LcmEscalation -CurrentTokens 90000 -Budget 200000 | Should -Be 'L1'     # 45%
        Invoke-LcmEscalation -CurrentTokens 130000 -Budget 200000 | Should -Be 'L2'    # 65%
        Invoke-LcmEscalation -CurrentTokens 170000 -Budget 200000 | Should -Be 'L3'    # 85%
    }

    It 'PESTER_TEST=1 skips persistence (in-memory only)' {
        $env:PESTER_TEST = '1'
        . $script:ScriptPath
        $n = Add-LcmNode -Level L1 -Content 'summary for pester' -Path $script:TmpDag
        $n.level | Should -Be 'L1'
        Test-Path $script:TmpDag | Should -BeFalse
    }

    It 'L3 without pointer warns' {
        $env:PESTER_TEST = '1'
        . $script:ScriptPath
        $warnVar = $null
        Add-LcmNode -Level L3 -Content 'lossless but missing pointer' -Path $script:TmpDag -WarningVariable warnVar -WarningAction SilentlyContinue | Out-Null
        $warnVar | Should -Not -BeNullOrEmpty
    }

    It 'L3 with pointer is lossless' {
        $env:PESTER_TEST = '1'
        . $script:ScriptPath
        $n = Add-LcmNode -Level L3 -Content 'full file ref' -Pointer '.agents/skills/context-watchdog/SKILL.md' -Path $script:TmpDag -WarningAction SilentlyContinue
        $n.pointer | Should -Be '.agents/skills/context-watchdog/SKILL.md'
    }
}
