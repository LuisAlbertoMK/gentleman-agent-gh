#requires -Version 7
<#
.SYNOPSIS
    E2E tests for the subagent result quality pipeline:
    register → simulate output → enforce (contract check + quality scoring).

    Validates the full chain: delegation-registry register, post-delegation-check
    contract validation wiring, and subagent-budget-guard quality scoring.

    Uses $TestDrive for temp files to avoid polluting git diff (write_scope check).

    Run: Invoke-Pester .\scripts\tests\subagent-quality-e2e.Tests.ps1
#>

Describe "Subagent Quality Pipeline - E2E" {
    BeforeAll {
        # Derive from script location (v6 hermetic fix: was hardcoded to
        # "D:/gentleman-agent-gh" which breaks on any other checkout path).
        $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $regScript = Join-Path $repoRoot 'scripts\delegation-registry.ps1'
        $bgScript  = Join-Path $repoRoot 'scripts\subagent-budget-guard.ps1'
    }

    AfterEach {
        # Clean up any temp output files that leaked into docs/
        $docsDir = Join-Path $repoRoot 'docs'
        if (Test-Path $docsDir) {
            Get-ChildItem $docsDir -Filter '_e2e_test_*' -ErrorAction SilentlyContinue | Remove-Item -Force
        }
    }

    Context "Successful delegation with valid 4-field contract" {
        It "registers, simulates output, enforces, and scores quality" {
            $testId = "e2e-success-$(Get-Random -Maximum 99999)"
            $validOutput = @"
## Decision Taken
Implemented C4d contract validation wiring
## Files Changed
scripts/post-delegation-check.ps1
## Key Findings
1. [HIGH] Contract validation was dead code - now wired via -SubagentOutputFile
2. [MEDIUM] Specialist subagents lack -auto twins for mode-aware routing
## Nuance
The -SubagentOutputFile parameter avoids command-string escaping issues.
"@
            $outFile = Join-Path $TestDrive "agent_output_$testId.txt"
            Set-Content -Path $outFile -Value $validOutput -NoNewline -Encoding UTF8

            $regResult = & pwsh -NoProfile -File $regScript -Action register -TaskId $testId `
                -AllowedPaths "scripts/*" `
                -TimeoutSeconds 30 -MaxToolCalls 25 `
                -SubagentOutputFile $outFile -RepoRoot $repoRoot -Quiet 2>&1
            $regJson = $regResult | Where-Object { $_ -match '^\{' } | Select-Object -First 1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            $regJson.status | Should -Be "registered"

            $pollResult = & pwsh -NoProfile -File $regScript -Action poll -TaskId $testId -RepoRoot $repoRoot -Quiet 2>&1
            $pollJson = $pollResult | Where-Object { $_ -match '^\{' } | Select-Object -First 1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            $pollJson.budget_exceeded | Should -Be $false

            $enforceResult = & pwsh -NoProfile -File $bgScript -Action enforce -TaskId $testId -RepoRoot $repoRoot -Quiet 2>&1
            $enforceJson = $enforceResult | Where-Object { $_ -match '^\{' } | Select-Object -First 1 | ConvertFrom-Json -ErrorAction SilentlyContinue

            $enforceJson.quality_score | Should -BeGreaterThan 0
            "contract_valid" | Should -BeIn $enforceJson.PSObject.Properties.Name
        }
    }

    Context "Malformed subagent output (missing Nuance)" {
        It "contract_validation fails and quality_score reflects it" {
            $testId = "e2e-bad-$(Get-Random -Maximum 99999)"
            $badOutput = @"
## Decision Taken
Did something
## Files Changed
src/x.ts
## Key Findings
1. [HIGH] Finding
"@
            $outFile = Join-Path $TestDrive "agent_output_bad_$testId.txt"
            Set-Content -Path $outFile -Value $badOutput -NoNewline -Encoding UTF8

            $regResult = & pwsh -NoProfile -File $regScript -Action register -TaskId $testId `
                -AllowedPaths "scripts/*" `
                -TimeoutSeconds 30 -MaxToolCalls 25 `
                -SubagentOutputFile $outFile -RepoRoot $repoRoot -Quiet 2>&1
            $regJson = $regResult | Where-Object { $_ -match '^\{' } | Select-Object -First 1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            $regJson.status | Should -Be "registered"

            $enforceResult = & pwsh -NoProfile -File $bgScript -Action enforce -TaskId $testId -RepoRoot $repoRoot -Quiet 2>&1
            $enforceJson = $enforceResult | Where-Object { $_ -match '^\{' } | Select-Object -First 1 | ConvertFrom-Json -ErrorAction SilentlyContinue

            $enforceJson | Should -Not -BeNull
            $enforceJson.contract_valid | Should -Be $false
        }
    }

    Context "Budget guard poll timeout detection" {
        It "flags timeout when duration exceeds limit" {
            $testId = "e2e-timeout-$(Get-Random -Maximum 99999)"
            $outFile = Join-Path $TestDrive "empty_$testId.txt"
            Set-Content -Path $outFile -Value "" -NoNewline

            $regResult = & pwsh -NoProfile -File $regScript -Action register -TaskId $testId `
                -AllowedPaths "scripts/*" `
                -TimeoutSeconds 1 -MaxToolCalls 25 `
                -SubagentOutputFile $outFile -RepoRoot $repoRoot -Quiet 2>&1
            $regJson = $regResult | Where-Object { $_ -match '^\{' } | Select-Object -First 1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            $regJson.status | Should -Be "registered"

            Start-Sleep -Seconds 2

            $pollResult = & pwsh -NoProfile -File $regScript -Action poll -TaskId $testId -RepoRoot $repoRoot -Quiet 2>&1
            $pollJson = $pollResult | Where-Object { $_ -match '^\{' } | Select-Object -First 1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            $pollJson.budget_exceeded | Should -Be $true
            $pollJson.status | Should -Be "timeout"
        }
    }

    It "subagent-budget-guard.ps1 has no syntax errors" {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($bgScript, [ref]$tokens, [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It "delegation-registry.ps1 has no syntax errors after extension" {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($regScript, [ref]$tokens, [ref]$errors)
        $errors.Count | Should -Be 0
    }
}
