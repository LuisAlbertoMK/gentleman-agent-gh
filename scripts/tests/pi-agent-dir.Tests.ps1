#requires -Version 5.1
<#
.SYNOPSIS
    Pester tests for Get-PiAgentDir (PI_CODING_AGENT_DIR override, upstream v3.6.0 #4892 style).
.DESCRIPTION
    Covers: absolute override, ~ expansion, relative resolution, unset fallback,
    and Pi override never changing the opencode global config root.
    Pattern reused from scripts/tests/ps5-compat.Tests.ps1 (Describe/It/Should).
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'Get-PiAgentDir — PI_CODING_AGENT_DIR override' {
    BeforeAll {
        $repoRoot = Split-Path $PSScriptRoot -Parent
        . (Join-Path (Join-Path $repoRoot 'lib') 'platform.ps1')
        $script:savedPiDir = $env:PI_CODING_AGENT_DIR
    }

    AfterAll {
        if ($null -eq $script:savedPiDir) {
            Remove-Item Env:PI_CODING_AGENT_DIR -ErrorAction SilentlyContinue
        } else {
            $env:PI_CODING_AGENT_DIR = $script:savedPiDir
        }
    }

    It 'T1: absolute override is returned as-is' {
        $abs = Join-Path ([System.IO.Path]::GetTempPath()) 'pi-agent-abs'
        $env:PI_CODING_AGENT_DIR = $abs
        Get-PiAgentDir | Should -Be $abs
    }

    It 'T2: leading ~ expands against $HOME' {
        $env:PI_CODING_AGENT_DIR = '~/pi-custom'
        $expected = Join-Path $HOME 'pi-custom'
        Get-PiAgentDir | Should -Be $expected
    }

    It 'T3: relative override is rejected with fallback + warning' {
        $env:PI_CODING_AGENT_DIR = 'rel-pi-agent'
        $expected = Join-Path (Join-Path $HOME '.pi') 'agent'
        Get-PiAgentDir | Should -Be $expected
    }

    It 'T4: unset override falls back to ~/.pi/agent' {
        Remove-Item Env:PI_CODING_AGENT_DIR -ErrorAction SilentlyContinue
        $expected = Join-Path (Join-Path $HOME '.pi') 'agent'
        Get-PiAgentDir | Should -Be $expected
    }

    It 'T5: Pi override never changes the opencode global config root' {
        Remove-Item Env:PI_CODING_AGENT_DIR -ErrorAction SilentlyContinue
        $before = Get-GlobalConfigDir
        $env:PI_CODING_AGENT_DIR = '~/pi-custom'
        $after = Get-GlobalConfigDir
        $after | Should -Be $before
        $after | Should -Match 'opencode'
    }
}
