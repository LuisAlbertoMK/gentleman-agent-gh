#requires -Version 7

<#
.SYNOPSIS
    Tests for hardware-profile.ps1 — hardware detection + profile recommendation.
#>

BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'hardware-profile.ps1'

    # Pre-compute results to avoid slow subprocess calls per test
    function Invoke-HardwareProfileCmd {
        param([string]$Profile, [switch]$Json, [switch]$WriteProfile)
        $args = @("-OutputProfile $Profile")
        if ($Json)       { $args += '-Json' }
        if ($WriteProfile) { $args += '-WriteProfile' }
        $cmd = "& '$scriptPath' $($args -join ' ')"
        $output = & pwsh -NoProfile -Command $cmd 2>&1
        $joined = ($output | Where-Object { $_ -is [string] }) -join "`n"
        return [PSCustomObject]@{
            output   = $output
            joined   = $joined
            exitCode = $LASTEXITCODE
        }
    }

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
            return $jsonStr.Substring(0, $end + 1) | ConvertFrom-Json
        }
        return $null
    }

    # Pre-compute all profiles (run each subprocess once)
    $script:results = @{
        low   = Invoke-HardwareProfileCmd -Profile "low" -Json
        medium = Invoke-HardwareProfileCmd -Profile "medium" -Json
        high  = Invoke-HardwareProfileCmd -Profile "high" -Json
        all   = Invoke-HardwareProfileCmd -Profile "all" -Json
        detect = Invoke-HardwareProfileCmd -Profile "detect" -Json
        invalid = Invoke-HardwareProfileCmd -Profile "invalid"
    }

    $script:jsonLow    = Parse-JsonFromOutput $results.low.joined
    $script:jsonMedium = Parse-JsonFromOutput $results.medium.joined
    $script:jsonHigh   = Parse-JsonFromOutput $results.high.joined
    $script:jsonAll    = Parse-JsonFromOutput $results.all.joined
    $script:jsonDetect = Parse-JsonFromOutput $results.detect.joined
}

Describe "hardware-profile.ps1 — syntax validation" {
    It "script has no parse errors" {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
}

Describe "hardware-profile.ps1 — OutputProfile validation" {
    It "exits 1 for invalid profile name" {
        $results.invalid.exitCode | Should -Be 1
    }

    It "accepts valid profile names (low)" {
        $results.low.exitCode | Should -Be 0
    }

    It "accepts valid profile names (medium)" {
        $results.medium.exitCode | Should -Be 0
    }

    It "accepts valid profile names (high)" {
        $results.high.exitCode | Should -Be 0
    }

    It "accepts valid profile names (all)" {
        $results.all.exitCode | Should -Be 0
    }

    It "accepts valid profile names (detect)" {
        $results.detect.exitCode | Should -Be 0
    }
}

Describe "hardware-profile.ps1 — JSON output structure" {
    It "low profile has expected fields" {
        $jsonLow | Should -Not -BeNullOrEmpty
        $jsonLow.name | Should -Be "low-resource"
        $jsonLow.description | Should -Not -BeNullOrEmpty
        $jsonLow.compaction | Should -Not -BeNullOrEmpty
        $jsonLow.agent | Should -Not -BeNullOrEmpty
        $jsonLow.watcher | Should -Not -BeNullOrEmpty
        $jsonLow.tools | Should -Not -BeNullOrEmpty
        $jsonLow.snapshot | Should -Not -BeNullOrEmpty
        $jsonLow.memory_monitoring | Should -Not -BeNullOrEmpty
        $jsonLow.notes | Should -Not -BeNullOrEmpty
        # mcp is @{} (empty hashtable) — verify property exists
        $jsonLow.PSObject.Properties.Name | Should -Contain "mcp"
    }

    It "high profile has expected fields" {
        $jsonHigh | Should -Not -BeNullOrEmpty
        $jsonHigh.name | Should -Be "high-resource"
    }

    It "medium profile has expected fields" {
        $jsonMedium | Should -Not -BeNullOrEmpty
        $jsonMedium.name | Should -Be "medium-resource"
    }
}

Describe "hardware-profile.ps1 — profile values" {
    It "low profile: depth=1, watcher disabled" {
        $jsonLow.agent.default.depth | Should -Be 1
        $jsonLow.watcher.enabled | Should -Be $false
    }

    It "medium profile: depth=2" {
        $jsonMedium.agent.default.depth | Should -Be 2
    }

    It "high profile: depth=3, watcher enabled" {
        $jsonHigh.agent.default.depth | Should -Be 3
        $jsonHigh.watcher.enabled | Should -Be $true
    }

    It "low profile has mcp property defined" {
        $jsonLow.PSObject.Properties.Name | Should -Contain "mcp"
    }

    It "low profile has 7 memory notes" {
        $jsonLow.notes.Count | Should -Be 7
    }
}

Describe "hardware-profile.ps1 — all profiles output" {
    It "outputs all 3 profiles with hardware info" {
        $jsonAll | Should -Not -BeNullOrEmpty
        $jsonAll.hardware | Should -Not -BeNullOrEmpty
        $jsonAll.hardware.cpu_cores | Should -BeGreaterThan 0
        $jsonAll.hardware.ram_gb | Should -BeGreaterThan 0
        $jsonAll.hardware.recommended_tier | Should -Match '^(low|medium|high)$'
        $jsonAll.profiles | Should -Not -BeNullOrEmpty
    }

    It "profiles object contains low, medium, high keys" {
        $profileNames = $jsonAll.profiles.PSObject.Properties.Name
        $profileNames | Should -Contain "low"
        $profileNames | Should -Contain "medium"
        $profileNames | Should -Contain "high"
    }
}

Describe "hardware-profile.ps1 — detect mode" {
    It "detect mode resolves to a valid tier name" {
        $jsonDetect.name | Should -Match '^(low|medium|high)-resource$'
    }
}

Describe "hardware-profile.ps1 — human-readable output" {
    It "low profile shows key settings without -Json" {
        $r = Invoke-HardwareProfileCmd -Profile "low"
        $joined = ($r.output | Where-Object { $_ -is [string] }) -join "`n"
        $joined | Should -Match "low-resource"
        $joined | Should -Match "compaction"
    }
}
