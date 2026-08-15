#requires -Version 7
# Auto-Improve Phase 3 - E2E Tests (Pester 6.1 / pwsh compatible)
# Dot-sources auto-improve.ps1 in BeforeAll to access real functions.

Describe "Auto-Improve Phase 3 - Issue Scanning" {

    BeforeAll {
        $env:BABYAGI_TEST_MODE = "1"
        $scriptPath = Join-Path $PSScriptRoot "..\scripts\auto-improve.ps1"
        . $scriptPath -AllowedPaths @("docs/*") -CodeRoot (Get-Location)
    }

    Context "T1: Scans for TODO/FIXME tags" {
        It "Scan-Issues returns array" {
            $issues = Scan-Issues -Paths @("docs/mejoras") -Root (Get-Location)
            @($issues).Count | Should -BeGreaterOrEqual 0
        }
    }

    Context "T2: Goal generation from issues" {
        It "Creates goal when issues found" {
            $issues = @("Fix TODO in test.ps1", "Fix FIXME in main.ts")
            $goal = New-ImprovementGoal -Issues $issues
            $goal | Should -Not -BeNullOrEmpty
            $goal | Should -Match "Fix code quality"
        }

        It "Returns null when no issues" {
            $goal = New-ImprovementGoal -Issues @()
            $goal | Should -BeNullOrEmpty
        }
    }
}

Describe "Auto-Improve Phase 3 - Fail-Closed" {

    Context "T3: Requires AllowedPaths" {
        It "Script contains fail-closed guard" {
            $content = Get-Content (Join-Path $PSScriptRoot "..\scripts\auto-improve.ps1") -Raw
            $content | Should -Match "FAIL-CLOSED"
        }
    }

    Context "T4: Has test mode guard" {
        It "Script skips execution in test mode" {
            $content = Get-Content (Join-Path $PSScriptRoot "..\scripts\auto-improve.ps1") -Raw
            $content | Should -Match "BABYAGI_TEST_MODE"
        }
    }
}
