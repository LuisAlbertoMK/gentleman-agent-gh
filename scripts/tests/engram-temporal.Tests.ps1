#requires -Version 5.1
# Pester tests for scripts/engram-temporal.ps1 — P1-3 temporal edges (Zep)
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'engram-temporal.ps1' {
    BeforeAll {
        $script:Path = Join-Path (Split-Path $PSScriptRoot -Parent) 'engram-temporal.ps1'
    }
    It 'parses without errors' {
        $errs=$null; [void][System.Management.Automation.Language.Parser]::ParseFile($script:Path,[ref]$null,[ref]$errs)
        $errs | Should -BeNullOrEmpty
    }
    It 'PESTER_TEST=1 skips CLI and returns empty chain (read-only)' {
        $env:PESTER_TEST='1'
        $out = & $script:Path -TopicKey "decision/test" -Limit 3 -Json 2>&1 | Out-String
        $json = ($out | Select-String -Pattern '\{[\s\S]*\}' -AllMatches).Matches[0].Value | ConvertFrom-Json
        $json.count | Should -Be 0
        $json.edges.Count | Should -Be 0
    }
    It 'Json output has chain + edges + generatedAt' {
        $env:PESTER_TEST='1'
        $out = & $script:Path -Query "test" -Limit 2 -Json 2>&1 | Out-String
        $json = ($out | Select-String -Pattern '\{[\s\S]*\}' -AllMatches).Matches[0].Value | ConvertFrom-Json
        $json.PSObject.Properties.Name | Should -Contain 'chain'
        $json.PSObject.Properties.Name | Should -Contain 'edges'
        $json.PSObject.Properties.Name | Should -Contain 'generatedAt'
    }
}
