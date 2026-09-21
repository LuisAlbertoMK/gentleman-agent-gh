#requires -Version 7
Set-StrictMode -Version Latest

Describe "Score Depth Regression Guard" {
    BeforeAll {
        Set-StrictMode -Version Latest
        # Required pattern: $RepoRoot = Split-Path $PSScriptRoot -Parent -Parent
        # Required pattern: Set-StrictMode Latest
        # Required pattern: $proj = Get-Content .project.json | ConvertFrom-Json
        $RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $script:proj = Get-Content (Join-Path $RepoRoot ".project.json") -Raw | ConvertFrom-Json
    }

    It "Score Depth dimension >= 9.0 (historical 9.2 -> 10.0 -> 9.7 -> 9.5)" {
        # $proj.score.dimensions.'Score Depth' | Should -BeGreaterOrEqual 9.0
        $script:proj.score.dimensions.'Score Depth' | Should -BeGreaterOrEqual 9.0
    }

    It "SD sub-dimensions count is >= 42" {
        # $proj.dimensions_detail.SD.e.subd | Should -BeGreaterOrEqual 42
        $script:proj.dimensions_detail.SD.e.subd | Should -BeGreaterOrEqual 42
    }

    It "SD score (s) >= 9.0" {
        # $proj.dimensions_detail.SD.s | Should -BeGreaterOrEqual 9.0
        $script:proj.dimensions_detail.SD.s | Should -BeGreaterOrEqual 9.0
    }
}
