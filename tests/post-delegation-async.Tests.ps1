#requires -Version 7
<#
.SYNOPSIS
    post-delegation-check.ps1 -Async (fire-and-forget delegation) + monitor-subagent.ps1.
.DESCRIPTION
    Tests for the async delegation path: -Async switch existence, fail-closed
    behavior without -AllowedPaths (v3 Perm-4), monitor script params, result
    JSON schema, and the {BaseRef}.async-result.json naming convention.
    Uses isolated git repos in $TestDrive for hermetic testing.
#>
BeforeAll {
    $scriptPath   = Join-Path $PSScriptRoot '..\scripts\post-delegation-check.ps1'
    $monitorPath  = Join-Path $PSScriptRoot '..\scripts\monitor-subagent.ps1'
}

Describe 'post-delegation-check.ps1 -Async flag' {
    It 'T1 -Async exists and is a [switch], declared after -Quiet' {
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
        $errors.Count | Should -Be 0

        $asyncParam = $ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'Async' }
        $asyncParam | Should -Not -BeNullOrEmpty
        $asyncParam.StaticType.Name | Should -Be 'SwitchParameter'

        $paramNames = @($ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
        $paramNames.IndexOf('Quiet') | Should -BeLessThan $paramNames.IndexOf('Async')
    }

    It 'T2 -Async without -AllowedPaths fails closed (v3 Perm-4)' {
        $r = & $scriptPath -BaseRef HEAD -Async -RepoRoot $TestDrive 2>&1
        $LASTEXITCODE | Should -Be 1
        ($r -join "`n") | Should -Match 'FAIL-CLOSED|AllowedPaths'
    }
}

Describe 'monitor-subagent.ps1' {
    It 'T3 exists with all required parameters' {
        Test-Path $monitorPath | Should -BeTrue
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($monitorPath, [ref]$tokens, [ref]$errors)
        $errors.Count | Should -Be 0
        $paramNames = @($ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
        'BaseRef','AllowedPaths','ExpectedFiles','SubagentOutputFile','RepoRoot','PollIntervalSec','MaxWaitSec' |
            ForEach-Object { $paramNames | Should -Contain $_ }
    }

    It 'T4 writes result JSON with expected fields (status, passed, checks)' {
        $repo = Join-Path $TestDrive 'repo-async'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        git -C $repo init --quiet 2>&1
        git -C $repo config user.email 'test@test.local'
        git -C $repo config user.name 'Pester Test'
        Set-Content -Path (Join-Path $repo 'init.txt') -Value 'initial'
        git -C $repo add init.txt 2>&1
        git -C $repo commit -m 'init' --quiet 2>&1
        Set-Content -Path (Join-Path $repo 'new.txt') -Value 'new file'

        Push-Location $repo
        try {
            $out = & pwsh -NoProfile -File $monitorPath -BaseRef HEAD -AllowedPaths '*.txt' -ExpectedFiles 'new.txt' -RepoRoot $repo -PollIntervalSec 1 -MaxWaitSec 30 2>&1
        } finally { Pop-Location }
        $LASTEXITCODE | Should -Be 0

        $resultFile = Join-Path $repo 'HEAD.async-result.json'
        Test-Path $resultFile | Should -BeTrue
        $json = Get-Content -Path $resultFile -Raw | ConvertFrom-Json
        $json.PSObject.Properties.Name -contains 'status'  | Should -BeTrue
        $json.PSObject.Properties.Name -contains 'passed'  | Should -BeTrue
        $json.PSObject.Properties.Name -contains 'checks'  | Should -BeTrue
        $json.status | Should -Be 'OK'
        $json.passed | Should -BeTrue
        @($json.checks).Count | Should -BeGreaterThan 0
        $json.reason | Should -Be 'stable'
    }

    It 'T5 uses {BaseRef}.async-result.json naming convention' {
        $repo = Join-Path $TestDrive 'repo-naming'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        git -C $repo init --quiet 2>&1
        git -C $repo config user.email 'test@test.local'
        git -C $repo config user.name 'Pester Test'
        Set-Content -Path (Join-Path $repo 'init.txt') -Value 'initial'
        git -C $repo add init.txt 2>&1
        git -C $repo commit -m 'init' --quiet 2>&1
        Set-Content -Path (Join-Path $repo 'b.txt') -Value 'second'
        git -C $repo add b.txt 2>&1
        git -C $repo commit -m 'second' --quiet 2>&1

        Push-Location $repo
        try {
            & pwsh -NoProfile -File $monitorPath -BaseRef HEAD~1 -AllowedPaths '*.txt' -RepoRoot $repo -PollIntervalSec 1 -MaxWaitSec 30 2>&1 | Out-Null
        } finally { Pop-Location }
        $LASTEXITCODE | Should -Be 0

        $resultFile = Join-Path $repo 'HEAD~1.async-result.json'
        Test-Path $resultFile | Should -BeTrue
        $json = Get-Content -Path $resultFile -Raw | ConvertFrom-Json
        $json.base_ref | Should -Be 'HEAD~1'
        $json.status | Should -Be 'OK'
    }

    It 'T6 -SubagentOutputFile with valid 4-field output reports contract_valid=true' {
        $repo = Join-Path $TestDrive 'repo-contract-valid'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        git -C $repo init --quiet 2>&1
        git -C $repo config user.email 'test@test.local'
        git -C $repo config user.name 'Pester Test'
        Set-Content -Path (Join-Path $repo 'init.txt') -Value 'initial'
        git -C $repo add init.txt 2>&1
        git -C $repo commit -m 'init' --quiet 2>&1
        Set-Content -Path (Join-Path $repo 'new.txt') -Value 'new file'

        $outFile = Join-Path $repo 'agent-output.txt'
        Set-Content -Path $outFile -Value @"
## Decision Taken
Added new file.

## Files Changed
new.txt

## Key Findings
1. LOW Test finding — evidence — recommendation

## Nuance
Some detail here.
"@

        Push-Location $repo
        try {
            $out = & pwsh -NoProfile -File $monitorPath -BaseRef HEAD -AllowedPaths '*.txt' -SubagentOutputFile $outFile -RepoRoot $repo -PollIntervalSec 1 -MaxWaitSec 30 2>&1
        } finally { Pop-Location }
        $LASTEXITCODE | Should -Be 0

        $resultFile = Join-Path $repo 'HEAD.async-result.json'
        Test-Path $resultFile | Should -BeTrue
        $json = Get-Content -Path $resultFile -Raw | ConvertFrom-Json
        $json.contract_valid | Should -BeTrue
        $json.contract_ran | Should -BeTrue
        $contractCheck = @($json.checks) | Where-Object { $_.name -eq 'contract_validation' }
        $contractCheck | Should -Not -BeNullOrEmpty
        $contractCheck.passed | Should -BeTrue
    }

    It 'T7 -SubagentOutputFile with missing Nuance fails contract validation' {
        $repo = Join-Path $TestDrive 'repo-contract-fail'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        git -C $repo init --quiet 2>&1
        git -C $repo config user.email 'test@test.local'
        git -C $repo config user.name 'Pester Test'
        Set-Content -Path (Join-Path $repo 'init.txt') -Value 'initial'
        git -C $repo add init.txt 2>&1
        git -C $repo commit -m 'init' --quiet 2>&1
        Set-Content -Path (Join-Path $repo 'new.txt') -Value 'new file'

        $outFile = Join-Path $repo 'agent-output.txt'
        Set-Content -Path $outFile -Value @"
## Decision Taken
Added new file.

## Files Changed
new.txt

## Key Findings
1. LOW Test finding — evidence — recommendation
"@

        Push-Location $repo
        try {
            $out = & pwsh -NoProfile -File $monitorPath -BaseRef HEAD -AllowedPaths '*.txt' -SubagentOutputFile $outFile -RepoRoot $repo -PollIntervalSec 1 -MaxWaitSec 30 2>&1
        } finally { Pop-Location }
        $LASTEXITCODE | Should -Be 1

        $resultFile = Join-Path $repo 'HEAD.async-result.json'
        Test-Path $resultFile | Should -BeTrue
        $json = Get-Content -Path $resultFile -Raw | ConvertFrom-Json
        $json.status | Should -Be 'FAIL'
        $json.contract_valid | Should -BeFalse
        $contractCheck = @($json.checks) | Where-Object { $_.name -eq 'contract_validation' }
        $contractCheck | Should -Not -BeNullOrEmpty
        $contractCheck.passed | Should -BeFalse
    }

    It 'T8 -SubagentOutputFile nonexistent path skips contract check' {
        $repo = Join-Path $TestDrive 'repo-contract-skip'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        git -C $repo init --quiet 2>&1
        git -C $repo config user.email 'test@test.local'
        git -C $repo config user.name 'Pester Test'
        Set-Content -Path (Join-Path $repo 'init.txt') -Value 'initial'
        git -C $repo add init.txt 2>&1
        git -C $repo commit -m 'init' --quiet 2>&1
        Set-Content -Path (Join-Path $repo 'new.txt') -Value 'new file'

        $fakePath = Join-Path $repo 'nonexistent-output.txt'

        Push-Location $repo
        try {
            $out = & pwsh -NoProfile -File $monitorPath -BaseRef HEAD -AllowedPaths '*.txt' -SubagentOutputFile $fakePath -RepoRoot $repo -PollIntervalSec 1 -MaxWaitSec 30 2>&1
        } finally { Pop-Location }
        $LASTEXITCODE | Should -Be 0

        $resultFile = Join-Path $repo 'HEAD.async-result.json'
        Test-Path $resultFile | Should -BeTrue
        $json = Get-Content -Path $resultFile -Raw | ConvertFrom-Json
        $json.contract_valid | Should -BeTrue   # sync-path convention: not evaluated = no violation detected
        $json.contract_ran | Should -BeFalse
        $json.contract_detail | Should -Be 'not evaluated'
        $contractCheck = @($json.checks) | Where-Object { $_.name -eq 'contract_validation' }
        $contractCheck | Should -BeNullOrEmpty
    }
}