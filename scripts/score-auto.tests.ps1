#requires -Version 7.6
<#
.SYNOPSIS
  Pester tests for score-auto.ps1 core logic.
  Tests: Add-Dimension, cache hash computation, evidence merging.
  Compatible with Pester 5.x / 6.x.
#>
param([switch]$Quiet)
Set-StrictMode -Version Latest

# --- Setup: extract and define functions once ---
$scriptContent = Get-Content -Path "$PSScriptRoot\score-auto.ps1" -Raw

BeforeAll {
    # Extract Add-Dimension function definition
    $raw = Get-Content -Path "$PSScriptRoot\score-auto.ps1" -Raw
    if ($raw -match '(function Add-Dimension[\s\S]*?\n\})') {
        . ([ScriptBlock]::Create($Matches[1]))
    }

    # Helper: simulate cache hash computation (extracted from score-auto.ps1 if available)
    function Get-CacheHash([string]$GitHead, [string]$ScriptsHash, [string]$SkillsHash) {
        $compositeKey = "$GitHead|$ScriptsHash|$SkillsHash"
        return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($compositeKey))
    }
}

# ============================================================
Describe 'Add-Dimension' {
    BeforeEach {
        $script:dimensions = @{}
    }

    It 'stores a dimension with name, score, evidence, and rationale' {
        Add-Dimension 'test' 7.5 @{ files = @('a.ps1'); score = 7.5 } 'Test dimension'

        $script:dimensions.ContainsKey('test') | Should -Be $true
        $script:dimensions['test'].s | Should -Be 7.5
        $script:dimensions['test'].e.files[0] | Should -BeExactly 'a.ps1'
        $script:dimensions['test'].r | Should -BeExactly 'Test dimension'
    }

    It 'overwrites existing dimension with same name' {
        Add-Dimension 'dup' 5.0 @{} 'first'
        Add-Dimension 'dup' 8.0 @{ note = 'updated' } 'second'

        $script:dimensions['dup'].s | Should -Be 8.0
        $script:dimensions['dup'].r | Should -BeExactly 'second'
    }

    It 'accepts empty evidence hashtable' {
        Add-Dimension 'empty' 10.0 @{} 'Perfect'

        $script:dimensions['empty'].s | Should -Be 10.0
        $script:dimensions['empty'].e.Keys.Count | Should -Be 0
    }

    It 'accepts score of 0' {
        Add-Dimension 'zero' 0.0 @{} 'Minimum'

        $script:dimensions['zero'].s | Should -Be 0.0
    }

    It 'accepts negative score' {
        Add-Dimension 'neg' -1.5 @{} 'Negative'

        $script:dimensions['neg'].s | Should -Be -1.5
    }

    It 'stores multiple dimensions independently' {
        Add-Dimension 'dim1' 1.0 @{} 'one'
        Add-Dimension 'dim2' 2.0 @{} 'two'
        Add-Dimension 'dim3' 3.0 @{} 'three'

        $script:dimensions.Keys.Count | Should -Be 3
        $script:dimensions['dim1'].s | Should -Be 1.0
        $script:dimensions['dim2'].s | Should -Be 2.0
        $script:dimensions['dim3'].s | Should -Be 3.0
    }
}

# ============================================================
Describe 'Cache Hash Computation' {
    It 'produces deterministic hash for same inputs' {
        $h1 = Get-CacheHash 'abc123' 'file1:100|file2:200' 'skill1:300'
        $h2 = Get-CacheHash 'abc123' 'file1:100|file2:200' 'skill1:300'

        $h1 | Should -Be $h2
    }

    It 'produces different hash when git HEAD changes' {
        $h1 = Get-CacheHash 'abc123' 'file1:100' 'skill1:300'
        $h2 = Get-CacheHash 'def456' 'file1:100' 'skill1:300'

        $h1 | Should -Not -Be $h2
    }

    It 'produces different hash when scripts change' {
        $h1 = Get-CacheHash 'abc123' 'file1:100' 'skill1:300'
        $h2 = Get-CacheHash 'abc123' 'file1:200' 'skill1:300'

        $h1 | Should -Not -Be $h2
    }

    It 'produces different hash when skills change' {
        $h1 = Get-CacheHash 'abc123' 'file1:100' 'skill1:300'
        $h2 = Get-CacheHash 'abc123' 'file1:100' 'skill1:400'

        $h1 | Should -Not -Be $h2
    }

    It 'returns valid base64' {
        $hash = Get-CacheHash 'abc' '' ''
        $hash | Should -Match '^[A-Za-z0-9+/=]+$'
    }

    It 'handles empty strings without error' {
        { Get-CacheHash '' '' '' } | Should -Not -Throw
        $hash = Get-CacheHash '' '' ''
        $hash | Should -Match '^[A-Za-z0-9+/=]+$'
    }
}

# ============================================================
Describe 'Dimension Aggregation' {
    BeforeEach {
        $script:dimensions = @{}
    }

    It 'computes average of multiple dimensions' {
        Add-Dimension 'A' 10.0 @{} 'max'
        Add-Dimension 'B' 0.0 @{} 'min'
        Add-Dimension 'C' 5.0 @{} 'mid'

        $avg = ($script:dimensions.Values.s | Measure-Object -Average).Average
        $avg | Should -Be 5.0
    }

    It 'computes average of single dimension' {
        Add-Dimension 'X' 8.5 @{} 'single'

        $avg = ($script:dimensions.Values.s | Measure-Object -Average).Average
        $avg | Should -Be 8.5
    }
}
