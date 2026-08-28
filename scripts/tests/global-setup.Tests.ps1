#requires -Version 7

<#
.SYNOPSIS
    Tests for global-setup.ps1 — one-click global OpenCode setup.
#>

BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'global-setup.ps1'

    # Pre-compute: run each variant once to avoid slow subprocess per test
    $script:jsonOutput = & pwsh -NoProfile -Command "& '$scriptPath' -Force -Json" 2>&1
    $script:jsonJoined = ($script:jsonOutput | Where-Object { $_ -is [string] }) -join "`n"
    $script:jsonExitCode = $LASTEXITCODE

    $script:quietOutput = & pwsh -NoProfile -Command "& '$scriptPath' -Force -Quiet" 2>&1
    $script:quietJoined = ($script:quietOutput | Where-Object { $_ -is [string] }) -join "`n"
    $script:quietExitCode = $LASTEXITCODE

    $script:skipMcpOutput = & pwsh -NoProfile -Command "& '$scriptPath' -Force -SkipMCP -Json" 2>&1
    $script:skipMcpJoined = ($script:skipMcpOutput | Where-Object { $_ -is [string] }) -join "`n"
    $script:skipMcpExitCode = $LASTEXITCODE

    # Parse JSON from output (handles pretty-printed multi-line JSON)
    function Parse-JsonFromOutput {
        param([string]$Joined)
        if (-not $Joined) { return $null }
        $start = $Joined.IndexOf('{')
        if ($start -lt 0) { return $null }
        $jsonStr = $Joined.Substring($start)
        $depth = 0; $end = -1
        for ($i = 0; $i -lt $jsonStr.Length; $i++) {
            if ($jsonStr[$i] -eq '{') { $depth++ }
            elseif ($jsonStr[$i] -eq '}') {
                $depth--
                if ($depth -eq 0) { $end = $i; break }
            }
        }
        if ($end -ge 0) {
            try {
                return $jsonStr.Substring(0, $end + 1) | ConvertFrom-Json -ErrorAction Stop
            } catch {
                return $null
            }
        }
        return $null
    }

    $script:parsedJson    = Parse-JsonFromOutput $script:jsonJoined
    $script:parsedQuiet   = Parse-JsonFromOutput $script:quietJoined
    $script:parsedSkipMcp = Parse-JsonFromOutput $script:skipMcpJoined
}

Describe "global-setup.ps1 — syntax validation" {
    It "script has no parse errors" {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        @($errors).Count | Should -Be 0
    }
}

Describe "global-setup.ps1 — -Json flag" {
    It "exits 0 with -Force -Json" {
        $jsonExitCode | Should -Be 0
    }

    It "produces JSON with timestamp field" {
        $parsedJson | Should -Not -BeNullOrEmpty
        $parsedJson.timestamp | Should -Not -BeNullOrEmpty
    }

    It "produces JSON with results array" {
        $parsedJson | Should -Not -BeNullOrEmpty
        $parsedJson.results | Should -Not -BeNullOrEmpty
        @($parsedJson.results).Count | Should -BeGreaterThan 0
    }

    It "produces JSON with summary object" {
        $parsedJson | Should -Not -BeNullOrEmpty
        $parsedJson.summary | Should -Not -BeNullOrEmpty
    }

    It "each result has name, status, detail" {
        $parsedJson | Should -Not -BeNullOrEmpty
        $first = $parsedJson.results[0]
        $first.name    | Should -Not -BeNullOrEmpty
        $first.status  | Should -Not -BeNullOrEmpty
        $first.detail  | Should -Not -BeNullOrEmpty
    }
}

Describe "global-setup.ps1 — -Quiet flag" {
    It "exits 0 with -Force -Quiet" {
        $quietExitCode | Should -Be 0
    }

    It "suppresses GLOBAL SETUP header" {
        $quietOutput | Should -Not -Match 'GLOBAL SETUP'
    }

    It "produces parseable JSON output" {
        $parsedQuiet | Should -Not -BeNullOrEmpty
        @($parsedQuiet.results).Count | Should -BeGreaterThan 0
    }
}

Describe "global-setup.ps1 — -SkipMCP flag" {
    It "exits 0 with -Force -SkipMCP -Json" {
        $skipMcpExitCode | Should -Be 0
    }

    It "produces valid JSON" {
        $parsedSkipMcp | Should -Not -BeNullOrEmpty
        @($parsedSkipMcp.results).Count | Should -BeGreaterThan 0
    }

    It "result count decreases (MCP entries skipped)" {
        @($parsedSkipMcp.results).Count | Should -BeLessThan 60
    }
}

Describe "global-setup.ps1 — status values" {
    It "results only use valid status strings" {
        $parsedJson | Should -Not -BeNullOrEmpty
        $validStatuses = @("OK", "SYNCED", "FAIL", "SKIP")
        $invalid = $parsedJson.results | Where-Object { $_.status -notin $validStatuses }
        @($invalid).Count | Should -Be 0
    }

    It "all steps succeed (ok or synced, no failures)" {
        $parsedJson | Should -Not -BeNullOrEmpty
        $failures = $parsedJson.results | Where-Object { $_.status -eq "FAIL" }
        @($failures).Count | Should -Be 0
    }
}

Describe "global-setup.ps1 — idempotency" {
    It "second run is still exit 0" {
        # Re-run to verify idempotency
        $output2 = & pwsh -NoProfile -Command "& '$scriptPath' -Force -Json" 2>&1
        $LASTEXITCODE | Should -Be 0
    }
}
