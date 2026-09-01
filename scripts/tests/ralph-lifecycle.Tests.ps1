#requires -Version 5.1
# Pester tests for scripts/ralph-lifecycle.ps1 — R2-6 lifecycle hooks + COMPLETE detection
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'ralph-lifecycle.ps1' {
    BeforeAll { $script:Path = Join-Path (Split-Path $PSScriptRoot -Parent) 'ralph-lifecycle.ps1' }
    It 'parses without errors' {
        $errs=$null; [void][System.Management.Automation.Language.Parser]::ParseFile($script:Path,[ref]$null,[ref]$errs)
        $errs | Should -BeNullOrEmpty
    }
    It 'PESTER_TEST=1 dry run returns not complete when no promise' {
        $env:PESTER_TEST='1'
        $out = & $script:Path -Hook check-complete -Json 2>&1 | Out-String
        $json = ($out | Select-String -Pattern '\{[\s\S]*\}' -AllMatches).Matches[0].Value | ConvertFrom-Json
        $json.complete | Should -BeFalse
    }
    It 'Json output has complete + source' {
        $env:PESTER_TEST='1'
        $out = & $script:Path -Hook post-close -Json 2>&1 | Out-String
        $json = ($out | Select-String -Pattern '\{[\s\S]*\}' -AllMatches).Matches[0].Value | ConvertFrom-Json
        $json.PSObject.Properties.Name | Should -Contain 'complete'
        $json.PSObject.Properties.Name | Should -Contain 'source'
    }
}
