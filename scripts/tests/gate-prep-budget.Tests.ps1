#requires -Version 7

<#
.SYNOPSIS
    Tests for Test-CandidateBudget in gate-prep.ps1 (upstream v3.4.0 adapted).
#>

BeforeAll {
    $gatePrep = Join-Path (Split-Path $PSScriptRoot -Parent) 'gate-prep.ps1'
    $tokens = $null; $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($gatePrep, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) { throw "gate-prep.ps1 has parse errors: $($parseErrors[0].Message)" }
    $fn = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Test-CandidateBudget' }, $true)
    if ($null -eq $fn) { throw "Test-CandidateBudget not found in gate-prep.ps1" }
    # PS-CE-01 remediation: use the parser-produced pre-compiled block (no dynamic string compile).
    $bodySb = $fn.Body.GetScriptBlock()
    New-Item -Path 'function:\Test-CandidateBudget' -Value $bodySb -Force | Out-Null
    $script:repoRootForBudget = Split-Path (Split-Path $gatePrep -Parent) -Parent
}

Describe "gate-prep.ps1 Test-CandidateBudget — 200 KiB per-runtime budget" {
    It "under-budget passes" {
        $entries = @(
            @{ Path = "src/a.ps1"; Bytes = 50000 },
            @{ Path = "src/b.ps1"; Bytes = 60000 }
        )
        $r = Test-CandidateBudget -FileEntries $entries
        $r.TotalBytes | Should -Be 110000
    }

    It "over-budget fails with top-5" {
        $entries = @(
            @{ Path = "src/big1.ps1"; Bytes = 90000 },
            @{ Path = "src/big2.ps1"; Bytes = 80000 },
            @{ Path = "src/big3.ps1"; Bytes = 70000 },
            @{ Path = "src/small.ps1"; Bytes = 1000 }
        )
        { Test-CandidateBudget -FileEntries $entries } | Should -Throw "*candidate exceeds 200 KiB per-runtime budget — reduce scope*"
        try {
            Test-CandidateBudget -FileEntries $entries | Out-Null
            throw "expected Test-CandidateBudget to throw"
        }
        catch {
            $msg = $_.Exception.Message
            $msg | Should -Match "big1\.ps1"
        }
    }

    It "generated-as-metadata passes" {
        $entries = @(
            @{ Path = "dist/bundle.min.js"; Bytes = 500000 },
            @{ Path = "src/foo.generated.cs"; Bytes = 300000 },
            @{ Path = "src/app.min.js"; Bytes = 400000 },
            @{ Path = "src/real.ps1"; Bytes = 1000 }
        )
        $r = Test-CandidateBudget -FileEntries $entries
        $r.TotalBytes | Should -Be 4072
    }

    It "invalid BaseRef fails closed" {
        { Test-CandidateBudget -BaseRef 'nonexistent-ref-zzz-123' -RepoRoot $script:repoRootForBudget } | Should -Throw '*fail-closed*'
    }
}
