#requires -Version 5.1
# Pester tests for security-audit-mcp.ps1 — Critical: ensures audit runs without StrictMode errors (GAP-1's strict checks) and that the actual repo is PASS
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Describe 'security-audit-mcp.ps1' {
    BeforeAll {
        $script:ScriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'security-audit-mcp.ps1'
        $script:RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    }
    It 'exists' {
        Test-Path -LiteralPath $script:ScriptPath | Should -BeTrue
    }
    It 'parses without errors' {
        $errs = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errs)
        $errs | Should -BeNullOrEmpty
    }
    It 'audit PASS on current repo (FAIL=0)' {
        $out = & $script:ScriptPath *>&1 | Out-String
        $out | Should -Match 'Result: PASS'
        $out | Should -Not -Match '\[FAIL\]'
    }
    It 'remote allowlist has exactly context7' {
        $out = & $script:ScriptPath *>&1 | Out-String
        $out -match 'context7 url allowlisted' | Should -BeTrue
    }
    It 'disabled hygiene: headroom + chrome-devtools both disabled in repo' {
        $json = Get-Content (Join-Path $script:RepoRoot 'opencode.json') -Raw | ConvertFrom-Json
        $json.mcp.headroom.enabled | Should -BeFalse
        $json.mcp.'chrome-devtools-mcp'.enabled | Should -BeFalse
    }
}
