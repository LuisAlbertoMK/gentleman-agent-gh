#requires -Version 7
<#
.SYNOPSIS
    Tests for route-agent.ps1 — single-mode routing (Refactor-AP S2/S5).

    Single-mode (gentle-ai style): every base agent resolves to itself with
    NO suffix. The retired `-auto` / `-semi` suffixes and `.gentleman-mode` /
    `-Mode` values are compat-alias no-ops (warning + strip, effective manual).

    Run: Invoke-Pester .\scripts\tests\route-agent.Tests.ps1
#>

BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'route-agent.ps1'
    function Invoke-Route {
        param([string]$BaseAgent, [string]$Mode = 'manual')
        # 2>$null + JSON-line filter: compat-alias warnings go to stderr and
        # must never break ConvertFrom-Json (S5 fix for the :31 warning bug).
        $r = & "pwsh" -NoProfile -Command "& '$scriptPath' -BaseAgent $BaseAgent -Mode $Mode -Json" 2>$null
        $jsonLine = @($r | Where-Object { $_ -match '^\s*\{' }) | Select-Object -First 1
        return ($jsonLine | ConvertFrom-Json)
    }
}

Describe "route-agent.ps1 — single-mode routing (no -auto suffix)" {
    It "manual mode resolves the base agent with no suffix" {
        $json = Invoke-Route -BaseAgent 'gentleman-quick' -Mode 'manual'
        $json.targetAgent | Should -Be "gentleman-quick"
        $json.suffix      | Should -Be ""
        $json.mode        | Should -Be "manual"
    }

    It "auto mode is a no-op compat alias — no suffix, effective manual" {
        $json = Invoke-Route -BaseAgent 'gentleman-quick' -Mode 'auto'
        $json.targetAgent | Should -Be "gentleman-quick"
        $json.suffix      | Should -Be ""
        $json.mode        | Should -Be "manual"
    }

    It "semi mode is a no-op compat alias — no suffix, effective manual" {
        $json = Invoke-Route -BaseAgent 'gentleman-deep' -Mode 'semi'
        $json.targetAgent | Should -Be "gentleman-deep"
        $json.suffix      | Should -Be ""
        $json.mode        | Should -Be "manual"
        $json.note        | Should -Match "no-op|compat|single-mode"
    }

    It "retired -auto suffix on input is stripped as compat alias" {
        $json = Invoke-Route -BaseAgent 'gentleman-quick-auto' -Mode 'manual'
        $json.targetAgent | Should -Be "gentleman-quick"
        $json.suffix      | Should -Be ""
        $json.note        | Should -Match "compat alias"
    }

    It "retired -semi suffix on input is stripped as compat alias" {
        $json = Invoke-Route -BaseAgent 'gentleman-deep-semi' -Mode 'manual'
        $json.targetAgent | Should -Be "gentleman-deep"
        $json.suffix      | Should -Be ""
        $json.note        | Should -Match "compat alias"
    }

    It "read-only specialist gets no suffix" {
        $json = Invoke-Route -BaseAgent 'gentleman-security-sub' -Mode 'auto'
        $json.targetAgent | Should -Be "gentleman-security-sub"
        $json.suffix      | Should -Be ""
    }

    It "sdd phase agent gets no suffix regardless of mode" {
        $json = Invoke-Route -BaseAgent 'sdd-apply' -Mode 'auto'
        $json.targetAgent | Should -Be "sdd-apply"
        $json.suffix      | Should -Be ""
    }

    It "all 5 mode-aware core agents resolve to themselves (auto is no-op)" {
        $cores = @('gentle-MK', 'gentleman-deep', 'gentleman-quick', 'gentleman-codex', 'gentleman-implementer')
        foreach ($c in $cores) {
            $json = Invoke-Route -BaseAgent $c -Mode 'auto'
            $json.targetAgent | Should -Be $c
            $json.suffix      | Should -Be ""
        }
    }

    It "unknown agent warns but still resolves with no suffix" {
        $json = Invoke-Route -BaseAgent 'gentleman-unknown-xyz' -Mode 'manual'
        $json.targetAgent | Should -Be "gentleman-unknown-xyz"
        $json.suffix      | Should -Be ""
        $json.note        | Should -Match "WARNING"
    }
}
