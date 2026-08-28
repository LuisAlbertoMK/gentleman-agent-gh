#requires -Version 7

<#
.SYNOPSIS
    Tests for check-config-drift.ps1 — 2-way config drift detection.
#>

BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'check-config-drift.ps1'

    # Helper: run script with given flags, return parsed JSON object.
    # The script outputs pretty-printed (multi-line) JSON, so we join
    # all output lines before parsing.
    # Runs IN-PROCESS (& $scriptPath) — `pwsh -NoProfile -Command` subprocess
    # spawn is DENIED by permission policy; see docs/operations/RUNBOOK.md:64.
    function Invoke-DriftCheck {
        param([switch]$Json, [switch]$Quiet)
        $invokeParams = @{}
        if ($Json)  { $invokeParams['Json']  = $true }
        if ($Quiet) { $invokeParams['Quiet'] = $true }
        $output = & $scriptPath @invokeParams 2>&1
        # Join all lines into a single string for ConvertFrom-Json
        $joined = ($output | Where-Object { $_ -is [string] }) -join "`n"
        $joined | ConvertFrom-Json
    }
}

Describe "check-config-drift.ps1 — syntax validation" {
    It "script has no parse errors" {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
}

Describe "check-config-drift.ps1 — output structure" -Skip:(($env:CI -eq 'true') -or (-not (Test-Path (Join-Path $env:USERPROFILE '.config/opencode')))) {
    It "produces valid JSON with expected fields" {
        $json = Invoke-DriftCheck -Json
        $json.timestamp | Should -Not -BeNullOrEmpty
        $json.version | Should -Be "1.0.0"
        $json.sections | Should -Not -BeNullOrEmpty
        $json.totalDrift | Should -BeOfType [long]
        $json.exitCode | Should -BeOfType [long]
    }

    It "reports sections with OK or DRIFT status" {
        $json = Invoke-DriftCheck -Json
        # Every section must carry a status, and each status must be one of
        # the two valid values. All-DRIFT is a legitimate state (e.g. when
        # canonical and global diverge), so we assert membership, not the
        # presence of a specific status.
        $statuses = @($json.sections | ForEach-Object { $_.status })
        $statuses | Should -Not -BeNullOrEmpty
        foreach ($status in $statuses) {
            $status | Should -BeIn @("OK", "DRIFT")
        }
    }
}

Describe "check-config-drift.ps1 — JSON output" {
    It "-Json flag produces valid JSON with expected fields" {
        $json = Invoke-DriftCheck -Json
        $json.timestamp | Should -Not -BeNullOrEmpty
        $json.version | Should -Be "1.0.0"
        $json.sections | Should -Not -BeNullOrEmpty
        $json.totalDrift | Should -BeOfType [long]
        $json.exitCode | Should -BeOfType [long]
    }

    It "JSON includes excludedSections field with mcp" {
        $json = Invoke-DriftCheck -Json
        $json.excludedSections | Should -Contain "mcp"
    }

    It "JSON includes files field with canonical and global paths" {
        $json = Invoke-DriftCheck -Json
        $json.files.canonical | Should -Not -BeNullOrEmpty
        $json.files.global | Should -Not -BeNullOrEmpty
    }
}

Describe "check-config-drift.ps1 — Quiet flag" {
    It "-Quiet suppresses non-JSON output" {
        $output = & $scriptPath -Quiet 2>&1
        $output | Should -Not -Match 'CONFIG DRIFT CHECK'
        $output | Should -Not -Match '═══'
        $output | Should -Not -Match 'Total drifts:'
    }

    It "-Quiet produces parseable JSON" {
        $json = Invoke-DriftCheck -Quiet
        $json.totalDrift | Should -Not -BeNullOrEmpty
        $json.exitCode | Should -Not -BeNullOrEmpty
    }
}

Describe "check-config-drift.ps1 — MCP exclusion" {
    It "sections list does not include mcp" {
        $json = Invoke-DriftCheck -Json
        $sectionNames = $json.sections | ForEach-Object { $_.section }
        $sectionNames | Should -Not -Contain "mcp"
    }
}

Describe "check-config-drift.ps1 — exit code" -Skip:(($env:CI -eq 'true') -or (-not (Test-Path (Join-Path $env:USERPROFILE '.config/opencode')))) {
    It "exit code reflects drift count (capped at 2)" {
        $json = Invoke-DriftCheck -Json
        $json.exitCode | Should -BeGreaterOrEqual 0
        $json.exitCode | Should -BeLessOrEqual 2
        # Script caps exitCode at 2 via [Math]::Min($totalDrift, 2), so when
        # totalDrift exceeds 2 the code must equal the cap, not the raw count.
        $json.exitCode | Should -Be ([Math]::Min($json.totalDrift, 2))
    }
}
