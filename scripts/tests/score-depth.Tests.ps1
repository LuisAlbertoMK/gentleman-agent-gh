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

    It "Score Depth dimension is 9.7 (historical 9.2 -> 10.0 -> 9.7 regression guard)" {
        # $proj.score.dimensions.'Score Depth' | Should -Be 9.7
        $script:proj.score.dimensions.'Score Depth' | Should -Be 9.7
    }

    It "SD sub-dimensions count is >= 42" {
        # $proj.dimensions_detail.SD.e.subd | Should -BeGreaterOrEqual 42
        $script:proj.dimensions_detail.SD.e.subd | Should -BeGreaterOrEqual 42
    }

    It "SD score (s) is 9.7" {
        # $proj.dimensions_detail.SD.s | Should -Be 9.7
        $script:proj.dimensions_detail.SD.s | Should -Be 9.7
    }
}
