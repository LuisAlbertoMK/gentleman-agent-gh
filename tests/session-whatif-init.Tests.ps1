#requires -Version 7
# WhatIf init/heal guard tests for inter-track.ps1
# Pattern: temp-dir copy (no mutation of real files). Seeds WITHOUT inter-track.json.

BeforeAll {
    $script:ScriptsRoot = Join-Path $PSScriptRoot "..\scripts"
    $script:RepoRoot = Join-Path $PSScriptRoot ".."
}

Describe "HIGH2: inter-track.ps1 WhatIf does not create/mutate fresh file" {

    BeforeEach {
        $script:TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "whatif-init-$(Get-Random)"
        $script:TmpScripts = Join-Path $script:TmpDir "scripts"
        New-Item -ItemType Directory -Path $script:TmpScripts -Force | Out-Null
        $learningsDir = Join-Path $script:TmpDir ".learnings"
        New-Item -ItemType Directory -Path $learningsDir -Force | Out-Null
        # NO seed — inter-track.json does NOT exist (fresh repo scenario)
        Copy-Item -LiteralPath (Join-Path $script:ScriptsRoot "inter-track.ps1") -Destination $script:TmpScripts -Force
    }

    AfterEach {
        if (Test-Path -LiteralPath $script:TmpDir) {
            Remove-Item -LiteralPath $script:TmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Increment -WhatIf on fresh repo does NOT create inter-track.json" {
        $trackPath = Join-Path $script:TmpDir ".learnings\inter-track.json"
        Test-Path -LiteralPath $trackPath | Should -Be $false
        $null = & "$($script:TmpScripts)\inter-track.ps1" -Increment -WhatIf -Quiet
        Test-Path -LiteralPath $trackPath | Should -Be $false
    }

    It "Reset -WhatIf on fresh repo does NOT create inter-track.json" {
        $trackPath = Join-Path $script:TmpDir ".learnings\inter-track.json"
        Test-Path -LiteralPath $trackPath | Should -Be $false
        $null = & "$($script:TmpScripts)\inter-track.ps1" -Reset -WhatIf -Quiet
        Test-Path -LiteralPath $trackPath | Should -Be $false
    }

    It "Increment -WhatIf on empty file does NOT recreate it" {
        $trackPath = Join-Path $script:TmpDir ".learnings\inter-track.json"
        # Create an empty file (triggers the second init block)
        Set-Content -LiteralPath $trackPath -Value "" -Encoding UTF8
        Test-Path -LiteralPath $trackPath | Should -Be $true
        (Get-Content -LiteralPath $trackPath -Raw).Trim() | Should -BeNullOrEmpty
        $null = & "$($script:TmpScripts)\inter-track.ps1" -Increment -WhatIf -Quiet
        # File should still exist but remain empty (no init wrote to it)
        Test-Path -LiteralPath $trackPath | Should -Be $true
        (Get-Content -LiteralPath $trackPath -Raw).Trim() | Should -BeNullOrEmpty
    }

    It "Increment -WhatIf on fresh seed with empty cycle.id does NOT heal id" {
        # Seed with empty id (post-init state)
        $seed = @{
            cycle  = @{ id = ""; start = ""; target = 30; count = 0 }
            history = @()
        }
        $trackPath = Join-Path $script:TmpDir ".learnings\inter-track.json"
        $seed | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $trackPath -Encoding UTF8
        $before = (Get-Content -LiteralPath $trackPath -Raw | ConvertFrom-Json).cycle.id
        $null = & "$($script:TmpScripts)\inter-track.ps1" -Increment -WhatIf -Quiet
        $after = (Get-Content -LiteralPath $trackPath -Raw | ConvertFrom-Json).cycle.id
        $after | Should -Be $before
    }

    It "Increment -WhatIf output is valid JSON with no mutation flag" {
        $result = & "$($script:TmpScripts)\inter-track.ps1" -Increment -WhatIf -Quiet | ConvertFrom-Json
        $result | Should -Not -BeNullOrEmpty
        # Under WhatIf on fresh file, no cycle id should exist (file not created)
        $trackPath = Join-Path $script:TmpDir ".learnings\inter-track.json"
        Test-Path -LiteralPath $trackPath | Should -Be $false
    }
}

Describe "HIGH2: inter-track.ps1 -Increment without WhatIf still works on fresh repo" {

    BeforeEach {
        $script:TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "whatif-init-real-$(Get-Random)"
        $script:TmpScripts = Join-Path $script:TmpDir "scripts"
        New-Item -ItemType Directory -Path $script:TmpScripts -Force | Out-Null
        $learningsDir = Join-Path $script:TmpDir ".learnings"
        New-Item -ItemType Directory -Path $learningsDir -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:ScriptsRoot "inter-track.ps1") -Destination $script:TmpScripts -Force
    }

    AfterEach {
        if (Test-Path -LiteralPath $script:TmpDir) {
            Remove-Item -LiteralPath $script:TmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Increment without WhatIf on fresh repo creates file and increments" {
        $trackPath = Join-Path $script:TmpDir ".learnings\inter-track.json"
        Test-Path -LiteralPath $trackPath | Should -Be $false
        $result = & "$($script:TmpScripts)\inter-track.ps1" -Increment -Quiet | ConvertFrom-Json
        Test-Path -LiteralPath $trackPath | Should -Be $true
        $result.count | Should -Be 1
        # Heal should have assigned a cycle id
        $result.cycleId | Should -Not -BeNullOrEmpty
    }
}
