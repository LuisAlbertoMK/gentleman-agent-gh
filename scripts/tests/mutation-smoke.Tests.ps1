#requires -Version 7
<#
.SYNOPSIS
    Mutation smoke test (delta-first, pattern R4 from auto-mejora v3 research).

.DESCRIPTION
    Verifies the mutation-testing MECHANISM works end-to-end without running a
    full mutation suite: mutates a single operator (-eq -> -ne) in a real
    target function (Get-DeepClone null-guard in json-utils.ps1), re-executes
    it in an isolated module, and asserts the baseline test would catch the
    mutant (mutant killed). Baseline behavior is asserted first.

    Why delta-first (Mercado Libre R4): measure test SUITE STRENGTH, not just
    line coverage — a mutant that survives means the tests pass but prove
    nothing about that line.
#>

BeforeAll {
    $lib = Join-Path (Get-Location) 'scripts/lib/json-utils.ps1'
    if (-not (Test-Path -LiteralPath $lib)) {
        throw "json-utils.ps1 not found at $lib"
    }
}

Describe 'mutation-smoke: baseline behavior (original operator)' {
    It 'Get-DeepClone returns $null for $null input (original -eq)' {
        . $lib
        $result = Get-DeepClone $null
        $result | Should -BeNullOrEmpty
    }

    It 'Get-DeepClone deep-copies a hashtable (original semantics)' {
        . $lib
        $src = @{ a = 1; b = @(1, 2, 3) }
        $clone = Get-DeepClone $src
        $clone.a | Should -Be 1
        $clone.b.Count | Should -Be 3
        # Mutating the original must NOT affect the clone (deep copy proof)
        $src.a = 99
        $clone.a | Should -Be 1
    }
}

Describe 'mutation-smoke: mutant killed (delta-first, R4)' {
    It 'mutating -eq to -ne in the null-guard changes observable behavior for non-null input' {
        # Read the REAL source and apply a single operator mutation in memory
        $source = Get-Content -LiteralPath $lib -Raw
        $mutated = $source.Replace('if ($null -eq $InputObject) { return $null }',
                                   'if ($null -ne $InputObject) { return $null }')
        if ($mutated -eq $source) {
            throw 'mutation did not apply - source pattern changed'
        }

        # Parse-proof the mutation is syntactically valid
        $null = [System.Management.Automation.Language.Parser]::ParseInput($mutated, [ref]$null, [ref]$null)

        # Behavioral proof: with -ne, Get-DeepClone(@{a=1}) hits the guard and
        # returns $null (original returns a deep copy) — observable difference.
        $probe = New-Module -ScriptBlock ([scriptblock]::Create($mutated))
        try {
            $mutatedResult = & $probe Get-DeepClone @{ a = 1 }
            $mutatedResult | Should -BeNullOrEmpty
        }
        finally {
            Remove-Module $probe
        }
    }

    It 'baseline test would fail against the mutant (killed proof)' {
        $source = Get-Content -LiteralPath $lib -Raw
        $mutated = $source.Replace('if ($null -eq $InputObject) { return $null }',
                                   'if ($null -ne $InputObject) { return $null }')
        $probe = New-Module -ScriptBlock ([scriptblock]::Create($mutated))
        try {
            $mutatedResult = & $probe Get-DeepClone @{ a = 1 }
            # Replicate the baseline deep-copy assertion: it must FAIL
            # (clone.a would be $null, so "Should -Be 1" throws) => mutant killed.
            { $mutatedResult.a | Should -Be 1 } | Should -Throw
        }
        finally {
            Remove-Module $probe
        }
    }
}
