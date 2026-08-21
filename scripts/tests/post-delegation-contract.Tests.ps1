#requires -Version 7
<#
.SYNOPSIS
    Tests for C4d: post-delegation-check.ps1 contract validation wiring.

    Verifies that the -SubagentOutputFile parameter in post-delegation-check.ps1
    is correctly forwarded to check-subagent-output.ps1 -AgentOutput, so the
    4-field return contract (Decision Taken | Files Changed | Key Findings | Nuance)
    is actually validated.

    Run: Invoke-Pester .\scripts\tests\post-delegation-contract.Tests.ps1
#>

Describe "post-delegation-check.ps1 -- contract validation wiring (C4d)" {
    BeforeAll {
        $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'post-delegation-check.ps1'

        # Isolated fixture repo so tests don't depend on the real working tree.
        $script:fixtureRepo = Join-Path $TestDrive 'fixture-repo'
        if (Test-Path $script:fixtureRepo) { Remove-Item -Recurse -Force $script:fixtureRepo }
        New-Item -ItemType Directory -Path $script:fixtureRepo -Force | Out-Null
        git -C $script:fixtureRepo init -q
        git -C $script:fixtureRepo config user.email "test@test.com"
        git -C $script:fixtureRepo config user.name "Test"
        Set-Content -Path (Join-Path $script:fixtureRepo 'base.txt') -Value 'base'
        git -C $script:fixtureRepo add .
        git -C $script:fixtureRepo commit -q -m "base"
        Set-Content -Path (Join-Path $script:fixtureRepo 'untracked.txt') -Value 'change'
    }

    It "script has no syntax errors" {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It "emits JSON with passed field (baseline smoke test)" {
        $r = & pwsh -NoProfile -File $scriptPath -BaseRef HEAD -Quiet 2>&1
        $jsonLine = $r | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $jsonLine | ConvertFrom-Json -ErrorAction SilentlyContinue
        $json | Should -Not -BeNull
        $json.PSObject.Properties.Name -contains 'passed' | Should -Be $true
        $json.PSObject.Properties.Name -contains 'checks' | Should -Be $true
    }

    It "does NOT include contract_validation check when -SubagentOutputFile omitted (backward compat)" {
        $r = & pwsh -NoProfile -File $scriptPath -BaseRef HEAD -Quiet 2>&1
        $jsonLine = $r | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $jsonLine | ConvertFrom-Json -ErrorAction SilentlyContinue
        $checkNames = @($json.checks | ForEach-Object { $_.name })
        $checkNames -contains 'contract_validation' | Should -Be $false
    }

    It "includes contract_validation check when -SubagentOutputFile is provided (wiring)" {
        $validOutput = "## Decision Taken`nFix C4d`n## Files Changed`nsrc/x.ts`n## Key Findings`n1. [HIGH] f`n## Nuance`nok"
        $tmpFile = Join-Path $TestDrive 'valid_out.txt'
        Set-Content -Path $tmpFile -Value $validOutput -NoNewline

        $r = & pwsh -NoProfile -File $scriptPath -BaseRef HEAD -Quiet -RepoRoot $script:fixtureRepo -AllowedPaths '*' -SubagentOutputFile $tmpFile 2>&1
        $jsonLine = $r | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $jsonLine | ConvertFrom-Json -ErrorAction SilentlyContinue
        $checkNames = @($json.checks | ForEach-Object { $_.name })
        $checkNames -contains 'contract_validation' | Should -Be $true
    }

    It "contract_validation PASSES for well-formed 4-field output" {
        $validOutput = "## Decision Taken`nFix C4d`n## Files Changed`nsrc/x.ts`n## Key Findings`n1. [HIGH] f`n## Nuance`nok"
        $tmpFile = Join-Path $TestDrive 'valid_out2.txt'
        Set-Content -Path $tmpFile -Value $validOutput -NoNewline

        $r = & pwsh -NoProfile -File $scriptPath -BaseRef HEAD -Quiet -RepoRoot $script:fixtureRepo -AllowedPaths '*' -SubagentOutputFile $tmpFile 2>&1
        $jsonLine = $r | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $jsonLine | ConvertFrom-Json -ErrorAction SilentlyContinue
        $contractCheck = $json.checks | Where-Object { $_.name -eq 'contract_validation' } | Select-Object -First 1
        $contractCheck | Should -Not -BeNullOrEmpty
        $contractCheck.passed | Should -Be $true
    }

    It "contract_validation FAILS for output missing Nuance section" {
        $invalidOutput = "## Decision Taken`nFix`n## Files Changed`nsrc/x.ts`n## Key Findings`n1. [HIGH] f"
        $tmpFile = Join-Path $TestDrive 'invalid_out.txt'
        Set-Content -Path $tmpFile -Value $invalidOutput -NoNewline

        $r = & pwsh -NoProfile -File $scriptPath -BaseRef HEAD -Quiet -RepoRoot $script:fixtureRepo -AllowedPaths '*' -SubagentOutputFile $tmpFile 2>&1
        $jsonLine = $r | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $jsonLine | ConvertFrom-Json -ErrorAction SilentlyContinue
        $contractCheck = $json.checks | Where-Object { $_.name -eq 'contract_validation' } | Select-Object -First 1
        $contractCheck | Should -Not -BeNullOrEmpty
        $contractCheck.passed | Should -Be $false
        $contractCheck.detail | Should -Match 'missing'
    }

    It "contract_validation FAILS for output with empty Key Findings section" {
        $invalidOutput = "## Decision Taken`nFix`n## Files Changed`nsrc/x.ts`n## Key Findings`n`n## Nuance`nok"
        $tmpFile = Join-Path $TestDrive 'empty_kf.txt'
        Set-Content -Path $tmpFile -Value $invalidOutput -NoNewline

        $r = & pwsh -NoProfile -File $scriptPath -BaseRef HEAD -Quiet -RepoRoot $script:fixtureRepo -AllowedPaths '*' -SubagentOutputFile $tmpFile 2>&1
        $jsonLine = $r | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $jsonLine | ConvertFrom-Json -ErrorAction SilentlyContinue
        $contractCheck = $json.checks | Where-Object { $_.name -eq 'contract_validation' } | Select-Object -First 1
        $contractCheck | Should -Not -BeNullOrEmpty
        $contractCheck.passed | Should -Be $false
        $contractCheck.detail | Should -Match 'empty'
    }

    It "contract_validation works end-to-end with subagent output via -SubagentOutputFile" {
        $validOutput = "## Decision Taken`nFix C4d`n## Files Changed`nsrc/x.ts`n## Key Findings`n1. [HIGH] f`n## Nuance`nok"
        $tmpFile = Join-Path $TestDrive 'file_transport.txt'
        Set-Content -Path $tmpFile -Value $validOutput -NoNewline

        $r = & pwsh -NoProfile -File $scriptPath -BaseRef HEAD -Quiet -RepoRoot $script:fixtureRepo -AllowedPaths '*' -SubagentOutputFile $tmpFile 2>&1
        $jsonLine = $r | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $jsonLine | ConvertFrom-Json -ErrorAction SilentlyContinue
        $contractCheck = $json.checks | Where-Object { $_.name -eq 'contract_validation' } | Select-Object -First 1
        $contractCheck | Should -Not -BeNullOrEmpty
        $contractCheck.passed | Should -Be $true
    }

    It "SubagentOutputFile with missing file logs warning but does not crash" {
        $missingFile = Join-Path $TestDrive 'nonexistent.txt'
        $r = & pwsh -NoProfile -File $scriptPath -BaseRef HEAD -Quiet -RepoRoot $script:fixtureRepo -AllowedPaths '*' -SubagentOutputFile $missingFile 2>&1
        $jsonLine = $r | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $jsonLine | ConvertFrom-Json -ErrorAction SilentlyContinue
        $json | Should -Not -BeNullOrEmpty
        $checkNames = @($json.checks | ForEach-Object { $_.name })
        $checkNames -contains 'contract_validation' | Should -Be $false
    }
}
