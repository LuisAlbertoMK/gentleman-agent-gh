#requires -Version 7

<#
.SYNOPSIS
    Tests for sync-all.ps1 — chains global-setup + sync-vmk.
#>

BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'sync-all.ps1'

    # Pre-compute: run once, reuse across all tests
    $script:jsonResult = & pwsh -NoProfile -Command "& '$scriptPath' -Json" 2>&1
    $script:jsonJoined = ($script:jsonResult | Where-Object { $_ -is [String] }) -join "`n"
    $script:jsonExitCode = $LASTEXITCODE

    $script:quietResult = & pwsh -NoProfile -Command "& '$scriptPath' -Quiet" 2>&1
    $script:quietJoined = ($script:quietResult | Where-Object { $_ -is [String] }) -join "`n"
    $script:quietExitCode = $LASTEXITCODE

    # Parse the LAST complete JSON object from joined output.
    # sync-all calls global-setup which also outputs JSON, so we need
    # sync-all's own JSON (the last one) not the subprocess's.
    # Strategy: find "success" (unique to sync-all's JSON), then scan
    # backwards to find the enclosing {, then forward to find matching }.
    function Parse-LastJson {
        param([string]$Joined)
        if (-not $Joined) { return $null }
        # Find "success" key (unique to sync-all's JSON)
        $successIdx = $Joined.LastIndexOf('"success"')
        if ($successIdx -lt 0) { return $null }
        # Scan backwards to find the enclosing { (skip nested objects)
        $depth = 0
        $start = -1
        for ($i = $successIdx; $i -ge 0; $i--) {
            if ($Joined[$i] -eq '}') { $depth++ }
            elseif ($Joined[$i] -eq '{') {
                if ($depth -eq 0) { $start = $i; break }
                $depth--
            }
        }
        if ($start -ge 0) {
            # Scan forward from { to find matching }
            $depth = 0; $end = -1
            for ($i = $start; $i -lt $Joined.Length; $i++) {
                if ($Joined[$i] -eq '{') { $depth++ }
                elseif ($Joined[$i] -eq '}') {
                    $depth--
                    if ($depth -eq 0) { $end = $i; break }
                }
            }
            if ($end -ge 0) {
                $jsonStr = $Joined.Substring($start, $end - $start + 1)
                try {
                    return $jsonStr | ConvertFrom-Json -ErrorAction Stop
                } catch {
                    return $null
                }
            }
        }
        return $null
    }

    function Invoke-SyncAll {
        param(
            [switch]$Json,
            [switch]$Quiet
        )
        $args = @()
        if ($Json)  { $args += '-Json' }
        if ($Quiet) { $args += '-Quiet' }
        $cmd = "& '$scriptPath' $($args -join ' ')"
        $output = & pwsh -NoProfile -Command $cmd 2>&1
        $joined = ($output | Where-Object { $_ -is [string] }) -join "`n"
        return [PSCustomObject]@{
            output    = $output
            joined    = $joined
            exitCode  = $LASTEXITCODE
        }
    }

    $script:parsedJson = Parse-LastJson $script:jsonJoined
    $script:parsedQuietJson = Parse-LastJson $script:quietJoined
}

Describe "sync-all.ps1 — syntax validation" {
    It "script has no parse errors" {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
}

Describe "sync-all.ps1 — -Json flag" {
    It "exits 0 with -Json" {
        $jsonExitCode | Should -Be 0
    }

    It "produces JSON with timestamp" {
        $parsedJson | Should -Not -BeNullOrEmpty
        $parsedJson.timestamp | Should -Not -BeNullOrEmpty
    }

    It "produces JSON with results array" {
        $parsedJson | Should -Not -BeNullOrEmpty
        $parsedJson.results | Should -Not -BeNullOrEmpty
        $parsedJson.results.Count | Should -Be 2  # global-setup + sync-vmk
    }

    It "produces JSON with success boolean" {
        $parsedJson | Should -Not -BeNullOrEmpty
        $parsedJson.success | Should -Be $true
    }

    It "results include global-setup step" {
        $setup = $parsedJson.results | Where-Object { $_.step -eq "global-setup" }
        $setup | Should -Not -BeNullOrEmpty
        $setup.status | Should -Be "OK"
    }

    It "results include sync-vmk step" {
        $vmk = $parsedJson.results | Where-Object { $_.step -eq "sync-vmk" }
        $vmk | Should -Not -BeNullOrEmpty
        $vmk.status | Should -Be "OK"
    }
}

Describe "sync-all.ps1 — -Quiet flag" {
    It "exits 0 with -Quiet" {
        $quietExitCode | Should -Be 0
    }

    It "suppresses SYNC-ALL COMPLETE header" {
        $quietResult | Should -Not -Match 'SYNC-ALL COMPLETE'
    }

    It "-Quiet with -Json produces parseable JSON" {
        $r = Invoke-SyncAll -Json -Quiet
        $json = Parse-LastJson $r.joined
        $json | Should -Not -BeNullOrEmpty
        $json.results.Count | Should -Be 2
    }
}

Describe "sync-all.ps1 — exit code on success" {
    It "exit 0 when both steps succeed" {
        $jsonExitCode | Should -Be 0
    }
}
