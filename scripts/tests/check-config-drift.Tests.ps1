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
    function Invoke-DriftCheck {
        param([switch]$Json, [switch]$Quiet)
        $flags = @()
        if ($Json)  { $flags += '-Json' }
        if ($Quiet) { $flags += '-Quiet' }
        $cmd = "& '$scriptPath' $($flags -join ' ')"
        $output = & pwsh -NoProfile -Command $cmd 2>&1
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

Describe "check-config-drift.ps1 — output structure" {
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
        $statuses = $json.sections | ForEach-Object { $_.status }
        $statuses | Should -Contain "OK"
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
        $flags = '-Quiet'
        $output = & pwsh -NoProfile -Command "& '$scriptPath' $flags" 2>&1
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

Describe "check-config-drift.ps1 — exit code" {
    It "exit code reflects drift count (capped at 2)" {
        $json = Invoke-DriftCheck -Json
        $json.exitCode | Should -BeGreaterOrEqual 0
        $json.exitCode | Should -BeLessOrEqual 2
        $json.exitCode | Should -Be $json.totalDrift
    }
}
