#requires -Version 7
# Session WhatIf / Close-Session / Checkpoint tests
# Pattern: temp-dir copy (no mutation of real files). Seed .learnings for inter-track.

BeforeAll {
    $script:ScriptsRoot = Join-Path $PSScriptRoot "..\scripts"
    $script:RepoRoot = Join-Path $PSScriptRoot ".."
}

Describe "S1: inter-track.ps1 -WhatIf does not mutate" {

    BeforeEach {
        $script:TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "session-whatif-$(Get-Random)"
        $script:TmpScripts = Join-Path $script:TmpDir "scripts"
        New-Item -ItemType Directory -Path $script:TmpScripts -Force | Out-Null
        $learningsDir = Join-Path $script:TmpDir ".learnings"
        New-Item -ItemType Directory -Path $learningsDir -Force | Out-Null
        # Seed inter-track.json with known state
        $seed = @{
            cycle  = @{ id = "CYC-TEST-001"; start = "2026-01-01T00:00:00Z"; target = 30; count = 5 }
            history = @()
        }
        $seed | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $learningsDir "inter-track.json") -Encoding UTF8
        # Copy inter-track.ps1 to temp/scripts/ (so $PSScriptRoot -> temp/scripts, repoRoot -> temp)
        Copy-Item -LiteralPath (Join-Path $script:ScriptsRoot "inter-track.ps1") -Destination $script:TmpScripts -Force
    }

    AfterEach {
        if (Test-Path -LiteralPath $script:TmpDir) {
            Remove-Item -LiteralPath $script:TmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Increment -WhatIf does not change count" {
        $trackPath = Join-Path $script:TmpDir ".learnings\inter-track.json"
        $before = (Get-Content -LiteralPath $trackPath -Raw | ConvertFrom-Json).cycle.count
        $result = & "$($script:TmpScripts)\inter-track.ps1" -Increment -WhatIf -Quiet
        $after = (Get-Content -LiteralPath $trackPath -Raw | ConvertFrom-Json).cycle.count
        $after | Should -Be $before
    }

    It "Reset -WhatIf does not change cycle id" {
        $trackPath = Join-Path $script:TmpDir ".learnings\inter-track.json"
        $before = (Get-Content -LiteralPath $trackPath -Raw | ConvertFrom-Json).cycle.id
        $result = & "$($script:TmpScripts)\inter-track.ps1" -Reset -WhatIf -Quiet
        $after = (Get-Content -LiteralPath $trackPath -Raw | ConvertFrom-Json).cycle.id
        $after | Should -Be $before
    }

    It "Increment without -WhatIf changes count" {
        $trackPath = Join-Path $script:TmpDir ".learnings\inter-track.json"
        $before = (Get-Content -LiteralPath $trackPath -Raw | ConvertFrom-Json).cycle.count
        $result = & "$($script:TmpScripts)\inter-track.ps1" -Increment -Quiet
        $after = (Get-Content -LiteralPath $trackPath -Raw | ConvertFrom-Json).cycle.count
        $after | Should -Be ($before + 1)
    }

    It "Reset without -WhatIf changes cycle id" {
        $trackPath = Join-Path $script:TmpDir ".learnings\inter-track.json"
        $before = (Get-Content -LiteralPath $trackPath -Raw | ConvertFrom-Json).cycle.id
        $result = & "$($script:TmpScripts)\inter-track.ps1" -Reset -Quiet
        $after = (Get-Content -LiteralPath $trackPath -Raw | ConvertFrom-Json).cycle.id
        $after | Should -Not -Be $before
    }

    It "WhatIf output includes whatIf marker for engram event" {
        $result = & "$($script:TmpScripts)\inter-track.ps1" -RecordEngramEvent -TopicKey "test/key" -EventKind "pending-consumed" -WhatIf -Quiet | ConvertFrom-Json
        $result.engram_recorded | Should -Be $false
        $result.engram_event.whatIf | Should -Be $true
    }
}
