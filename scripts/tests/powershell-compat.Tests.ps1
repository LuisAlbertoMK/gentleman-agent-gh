#requires -Version 7
# Enforces PS version declaration matches reality (dot-sources must not pull PS7-only libs)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'PS version declaration consistency' {
    BeforeAll {
        $script:RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $script:repoScripts = Get-ChildItem (Join-Path $script:RepoRoot "scripts") -Filter *.ps1 -File
        $script:repoLibs = Get-ChildItem (Join-Path $script:RepoRoot "scripts/lib") -Filter *.ps1 -File
    }

    It 'every scripts/*.ps1 declares #requires -Version (5.1|7) in first 3 lines' {
        $missing = @()
        foreach ($s in $script:repoScripts) {
            $head = (Get-Content $s.FullName -TotalCount 3) -join "`n"
            if ($head -notmatch '#requires -Version (5\.1|7)') { $missing += $s.Name }
        }
        $missing | Should -BeNullOrEmpty
    }

    It 'every lib/*.ps1 declares #requires -Version (5.1|7)' {
        $bad = @()
        foreach ($l in $script:repoLibs) {
            $head = (Get-Content $l.FullName -TotalCount 3) -join "`n"
            if ($head -notmatch '#requires -Version (5\.1|7)') { $bad += $l.Name }
        }
        $bad | Should -BeNullOrEmpty
    }

    It 'a 5.1-declared script must not dot-source a 7-declared lib' {
        $violations = @()
        foreach ($s in $script:repoScripts) {
            $head = (Get-Content $s.FullName -TotalCount 3) -join "`n"
            if ($head -match '#requires -Version 5\.1') {
                $body = Get-Content $s.FullName -Raw
                # find dot-source references to lib files
                if ($body -match 'mcp-resilience\.ps1|permission-gate-lib\.ps1|cache\.ps1|score-dims\.ps1|file-manifest\.ps1|engram-validate-lib\.ps1') {
                    $violations += $s.Name
                }
            }
        }
        $violations | Should -BeNullOrEmpty
    }
}
