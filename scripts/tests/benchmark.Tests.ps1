#requires -Version 7

<#
.SYNOPSIS
    Pester tests for benchmark.ps1 — DEPRECATED.
    benchmark.ps1 has been replaced by benchmark-core.ps1 + benchmark-regression.ps1.
    All tests skipped with reason.
.NOTES
    See benchmark-regression.Tests.ps1 and benchmark-core.Tests.ps1 for active tests.
#>

Describe 'benchmark.ps1 (DEPRECATED)' {

    It 'fails the gate when no pinned baseline exists' -Skip:$true {
        # benchmark.ps1 deprecated, replaced by benchmark-core.ps1 + benchmark-regression.ps1
        $true | Should -BeTrue
    }

    It 'passes the gate when current metrics are at or above the baseline' -Skip:$true {
        # benchmark.ps1 deprecated, replaced by benchmark-core.ps1 + benchmark-regression.ps1
        $true | Should -BeTrue
    }

    It 'pins the baseline with -SetBaseline' -Skip:$true {
        # benchmark.ps1 deprecated, replaced by benchmark-core.ps1 + benchmark-regression.ps1
        $true | Should -BeTrue
    }

    It 'writes a dated benchmark snapshot plus LATEST' -Skip:$true {
        # benchmark.ps1 deprecated, replaced by benchmark-core.ps1 + benchmark-regression.ps1
        $true | Should -BeTrue
    }

    It 'counts a dead junction and fails the gate' -Skip:$true {
        # benchmark.ps1 deprecated, replaced by benchmark-core.ps1 + benchmark-regression.ps1
        $true | Should -BeTrue
    }

    It 'fails on junction-coverage regression when not in CI' -Skip:$true {
        # benchmark.ps1 deprecated, replaced by benchmark-core.ps1 + benchmark-regression.ps1
        $true | Should -BeTrue
    }

    It 'skips the junction-coverage regression when CI=1' -Skip:$true {
        # benchmark.ps1 deprecated, replaced by benchmark-core.ps1 + benchmark-regression.ps1
        $true | Should -BeTrue
    }
}
