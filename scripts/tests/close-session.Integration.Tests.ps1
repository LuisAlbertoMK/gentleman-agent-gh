#requires -Version 5.1
<#
.SYNOPSIS
    Non-destructive integration tests for close-session.ps1.
.NOTES
    Tests output format, parameter passthrough, and JSON contract without
    modifying real project state. The script's internal logic (needsAudit,
    bloat detection, session-miner) is covered by 43 unit tests in
    close-session.Tests.ps1 — this file tests the integration surface:
    parameter binding, JSON contract, and error paths.
#>

BeforeAll {
    $scriptsRoot = Resolve-Path "$PSScriptRoot/.."
    $scriptPath = "$scriptsRoot/close-session.ps1"

    # Create isolated temp dir — the script still resolves its real paths
    # (BITACORA, .agents/skills/*) from the real repo root via $PSScriptRoot,
    # so we can't fully isolate without script patching. Instead, we test:
    #   1. JSON contract shape (Quiet mode)
    #   2. Parameter binding
    #   3. Non-modifying output paths
}

Describe "close-session — Integration: JSON contract" {

    It "returns valid JSON in -Quiet mode with expected fields" {
        $output = & $scriptPath -Goal "IntTestGoal" -Description "Int test" -Quiet 2>&1
        $result = $output | Out-String | ConvertFrom-Json

        # Contract: all expected fields must exist
        $result.action | Should -Be "close-session"
        $result.timestamp | Should -Not -BeNullOrEmpty
        $result.branch | Should -Not -BeNullOrEmpty
        $result.hasChanges | Should -Not -BeNullOrEmpty
        $result.goal | Should -Be "IntTestGoal"
        $result.needsAudit | Should -Not -BeNullOrEmpty
        $result.auditGatePassed | Should -Not -BeNullOrEmpty
    }

    It "changeCount is a valid number" {
        $output = & $scriptPath -Goal "Test" -Description "Int test" -Quiet 2>&1
        $result = $output | Out-String | ConvertFrom-Json
        $result.changeCount -is [ValueType] | Should -Be $true
        $result.changeCount | Should -BeGreaterOrEqual 0
    }

    It "includes protectedTouched as array when protected files changed" {
        # This test runs against the real project's git status
        # If there are any modified protected files, it will flag them
        # If not, protectedTouched will be empty — both are valid
        $output = & $scriptPath -Goal "Test" -Description "Protected check" -Quiet 2>&1
        $result = $output | Out-String | ConvertFrom-Json
        $result.protectedTouched -is [System.Array] | Should -Be $true
    }

    It "auditGatePassed is boolean" {
        $output = & $scriptPath -Goal "Test" -Description "Gate check" -Quiet 2>&1
        $result = $output | Out-String | ConvertFrom-Json
        ($result.auditGatePassed -is [bool]) | Should -Be $true
    }
}

Describe "close-session — Integration: parameter binding" {

    It "accepts -Goal parameter" {
        $output = & $scriptPath -Goal "Integrate auth middleware" -Description "Test" -Quiet 2>&1
        $result = $output | Out-String | ConvertFrom-Json
        $result.goal | Should -Be "Integrate auth middleware"
    }

    It "accepts -Description parameter" {
        $output = & $scriptPath -Goal "Test" -Description "Added RBAC support" -Quiet 2>&1
        $result = $output | Out-String | ConvertFrom-Json
        # Description is not in JSON output (it's only in BITACORA), but we can verify no error
        $result | Should -Not -BeNullOrEmpty
    }

    It "accepts -DryRun flag" {
        $output = & $scriptPath -Goal "Test" -Description "Dry run" -DryRun -Quiet 2>&1
        $result = $output | Out-String | ConvertFrom-Json
        $result.action | Should -Be "close-session"
    }

    It "accepts -CompactPrompt flag" {
        $output = & $scriptPath -Goal "Test" -Description "Compact" -CompactPrompt 2>&1
        $outputString = $output | Out-String
        $outputString | Should -Match "COMPACT PROMPT FOR NEXT SESSION"
    }
}

Describe "close-session — Integration: non-Quiet output format" {

    It "outputs compact prompt or session header in non-Quiet mode" {
        $output = & $scriptPath -Goal "Test" -Description "Non-quiet test" 2>&1
        $outputString = $output | Out-String
        # When changes exist, compact prompt takes priority; when clean, SESSION CLOSE shows
        $hasSessionHeader = $outputString -match "SESSION CLOSE"
        $hasCompactPrompt = $outputString -match "COMPACT PROMPT FOR NEXT SESSION"
        ($hasSessionHeader -or $hasCompactPrompt) | Should -Be $true
    }

    It "includes branch and goal in output" {
        $output = & $scriptPath -Goal "TestBranchGoal" -Description "Branch test" 2>&1
        $outputString = $output | Out-String
        $outputString | Should -Match "Branch|COMPACT PROMPT"
        $outputString | Should -Match "TestBranchGoal"
    }
}
