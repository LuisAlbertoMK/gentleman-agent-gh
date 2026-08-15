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
        'BaseRef','AllowedPaths','ExpectedFiles','RepoRoot','PollIntervalSec','MaxWaitSec' |
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
}