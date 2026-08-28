#requires -Version 7
<#
.SYNOPSIS
    Static gate for orchestrator enforcement hooks and weakness-plan artifacts.
.DESCRIPTION
    Validates WITHOUT a runtime harness:
    - T1: prompts/gentleman-vMK.md exists (fail-closed)
    - T2: All four mandatory hook markers are present in the prompt
    - T3: Every script referenced by the 2026-08-14 weakness plan exists on disk
    - T4: Fail-closed negative — missing prompt file is detected, not silently ignored
.NOTES
    Data-driven via Pester -ForEach (Pester 6).
    Arrays defined at Describe scope (discovery) AND in BeforeAll (run) because
    -ForEach is evaluated at discovery time while summary Its need them at run time.
#>

Describe "Orchestrator Hooks — Static Gate" {
    $hookMarkers   = @(
        'Pre-Answer Evidence Gate',
        'Memory Capture',
        'UX Boundary',
        'Perf Profiling'
    )
    $weaknessPlanScripts = @(
        'scripts\session-checkpoint.ps1',
        'scripts\close-session.ps1',
        'scripts\hardware-profile.ps1',
        'scripts\benchmark-regression.ps1',
        'scripts\ui-specialist-pairing.ps1'
    )
    BeforeAll {
        $repoRoot          = Join-Path $PSScriptRoot ".."
        $promptFile        = Join-Path $repoRoot "prompts\gentleman-vMK.md"
        $hookMarkers       = @(
            'Pre-Answer Evidence Gate',
            'Memory Capture',
            'UX Boundary',
            'Perf Profiling'
        )
        $weaknessPlanScripts = @(
            'scripts\session-checkpoint.ps1',
            'scripts\close-session.ps1',
            'scripts\hardware-profile.ps1',
            'scripts\benchmark-regression.ps1',
            'scripts\ui-specialist-pairing.ps1'
        )
    }

    Context "T1 — Prompt file existence" {
        It "prompts/gentleman-vMK.md exists (fail-closed)" {
            Test-Path $promptFile | Should -BeTrue
        }
    }

    Context "T2 — Mandatory hook markers" {
        BeforeAll {
            $promptContent = Get-Content $promptFile -Raw -ErrorAction SilentlyContinue
        }

        It "Prompt file is readable" {
            $promptContent | Should -Not -BeNullOrEmpty
        }

        It "Contains marker: '<_>'" -ForEach $hookMarkers {
            $promptContent | Should -Match ([regex]::Escape($_))
        }

        It "All four markers present (summary)" {
            $found = @()
            foreach ($m in $hookMarkers) {
                if ($promptContent -match [regex]::Escape($m)) { $found += $m }
            }
            $found.Count | Should -Be 4
        }
    }

    Context "T3 — Weakness-plan artifact existence" {
        It "Script exists: <_>" -ForEach $weaknessPlanScripts {
            Test-Path (Join-Path $repoRoot $_) | Should -BeTrue
        }

        It "All five scripts present (summary)" {
            $missing = @()
            foreach ($s in $weaknessPlanScripts) {
                if (-not (Test-Path (Join-Path $repoRoot $s))) { $missing += $s }
            }
            $missing | Should -BeNullOrEmpty
        }
    }

    Context "T4 — Fail-closed: missing prompt file detected" {
        BeforeAll {
            $tempPrompt = Join-Path $TestDrive "no-such-prompt.md"
        }

        It "Non-existent prompt path is correctly identified as absent" {
            Test-Path $tempPrompt | Should -BeFalse
        }

        It "Reading absent file produces empty/null content (fail-closed)" {
            $content = Get-Content $tempPrompt -Raw -ErrorAction SilentlyContinue
            $content | Should -BeNullOrEmpty
        }

        It "Marker search on absent content matches nothing" {
            $content = Get-Content $tempPrompt -Raw -ErrorAction SilentlyContinue
            foreach ($m in $hookMarkers) {
                $content | Should -Not -Match ([regex]::Escape($m))
            }
        }
    }
}
