#requires -Version 7

<#
.SYNOPSIS
    Tests for subagent-budget-guard.ps1 — budget enforcement for subagent delegations.
#>

BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'subagent-budget-guard.ps1'
}

Describe "subagent-budget-guard.ps1 — syntax & structure" {
    It "script has no parse errors" {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
}

Describe "subagent-budget-guard.ps1 — poll action" {
    It "returns not_found and exit 1 for invalid TaskId" {
        $r = & pwsh -NoProfile -Command "& '$scriptPath' -Action poll -TaskId 'test-not-exist'" 2>&1
        $r | Should -Match "not found"
    }

    It "returns JSON not_found in Quiet mode for invalid TaskId" {
        $r = & pwsh -NoProfile -Command "& '$scriptPath' -Action poll -TaskId 'test-not-exist' -Quiet" 2>&1
        $jsonLine = $r | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $jsonLine | ConvertFrom-Json
        $json.status | Should -Be "not_found"
        $json.task_id | Should -Be "test-not-exist"
    }
}

Describe "subagent-budget-guard.ps1 — enforce action" {
    It "returns not_found and exit 1 for invalid TaskId" {
        $r = & pwsh -NoProfile -Command "& '$scriptPath' -Action enforce -TaskId 'test-not-exist'" 2>&1
        $r | Should -Match "not found"
    }

    It "returns JSON not_found in Quiet mode for invalid TaskId" {
        $r = & pwsh -NoProfile -Command "& '$scriptPath' -Action enforce -TaskId 'test-not-exist' -Quiet" 2>&1
        $jsonLine = $r | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $jsonLine | ConvertFrom-Json
        $json.status | Should -Be "not_found"
        $json.task_id | Should -Be "test-not-exist"
        $json.quality_score | Should -Be 0
        $json.contract_valid | Should -BeFalse
    }
}
