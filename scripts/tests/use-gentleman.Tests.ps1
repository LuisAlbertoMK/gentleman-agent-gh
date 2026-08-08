#requires -Version 7
<#
.SYNOPSIS
    Contract tests for scripts/use-gentleman.ps1 — Detect-Template() auto-registration,
    TEMPLATE_MAP parity, and fail-closed behavior.

    This is the PowerShell mirror of the R10 describe block in generate-config.Tests.ps1.
    Validates that Detect-Template() produces identical results to the explicit
    $templateMap for all known agents, auto-registers new agents via naming
    conventions, and fail-closed on truly unknown agents.

    Never touches production config — runs entirely in-memory.
#>
BeforeAll {
    # Dot-source the function definitions from use-gentleman.ps1
    $script:gentlemanRoot = Join-Path $PSScriptRoot '..\use-gentleman.ps1'
    . $script:gentlemanRoot
}

Describe 'use-gentleman.ps1 — Detect-Template parity with $templateMap' {
    It 'Detect-Template() returns the same template as $templateMap for every explicit entry' {
        # Guards against the function drifting from the map it's supposed to mirror.
        $drift = @()
        foreach ($entry in $templateMap.GetEnumerator()) {
            $agent = $entry.Key
            $expected = $entry.Value
            $actual = Detect-Template -AgentName $agent
            if ($actual -ne $expected) {
                $drift += "$($agent): map=$expected vs detect=$actual"
            }
        }
        $drift.Count | Should -Be 0
        if ($drift.Count -gt 0) { $drift | Write-Host }
    }

    It 'fixes the -sub-auto drift: gentleman-deep-sub-auto maps to auto-sub (not auto)' {
        Detect-Template -AgentName 'gentleman-deep-sub-auto' | Should -Be 'auto-sub'
        Detect-Template -AgentName 'gentleman-quick-sub-auto' | Should -Be 'auto-sub'
        Detect-Template -AgentName 'gentleman-codex-sub-auto' | Should -Be 'auto-sub'
        Detect-Template -AgentName 'gentleman-implementer-sub-auto' | Should -Be 'auto-sub'
    }

    It 'includes previously-missing -sub entries' {
        Detect-Template -AgentName 'gentleman-codex-sub' | Should -Be 'readwrite'
        Detect-Template -AgentName 'gentleman-reviewer-sub' | Should -Be 'reviewer'
    }
}

Describe 'use-gentleman.ps1 — auto-registration (Gap A)' {
    It 'auto-registers gentleman-security-sub-auto via -sub-auto suffix (not in explicit map)' {
        # gentleman-security-sub-auto is NOT in $templateMap — auto-detected via suffix rule.
        $result = Detect-Template -AgentName 'gentleman-security-sub-auto'
        $result | Should -Be 'auto-sub'
    }

    It 'auto-registers gentleman-infra-auto via -auto suffix (not in explicit map)' {
        $result = Detect-Template -AgentName 'gentleman-infra-auto'
        $result | Should -Be 'auto'
    }

    It 'auto-registers gentleman-custom-sub via -sub suffix (recurses to parent + role keyword)' {
        # gentleman-custom is not in map, but 'docs' role keyword → 'readonly'
        # Wait — 'custom' doesn't contain any keyword. This should fail-closed.
        # Let's use a name that DOES match a role keyword for the -sub recursion test.
        # gentleman-security-analyst-sub → ends with -sub → strip → gentleman-security-analyst
        # → contains 'security' → 'readonly'
        $result = Detect-Template -AgentName 'gentleman-security-analyst-sub'
        $result | Should -Be 'readonly'
    }

    It 'fail-closed: gentleman-biz throws (no suffix, no role keyword)' {
        { Detect-Template -AgentName 'gentleman-biz' } | Should -Throw
    }
}
