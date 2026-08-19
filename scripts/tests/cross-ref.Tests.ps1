#requires -Version 7
<#
.SYNOPSIS
  Pester tests for cross-ref-check.ps1 cross-reference integrity.
.DESCRIPTION
  Validates that all cross-references, junctions, and skill index consistency pass.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe "Cross-Reference Integrity" {

    It "T1: cross-ref-check.ps1 -Json returns 0 errors" {
        $RepoRoot = "D:\gentleman-agent-gh"
        $result = & (Join-Path $RepoRoot "scripts\cross-ref-check.ps1") -Json | ConvertFrom-Json
        $result.errors.Count | Should -Be 0
        $result.brokenCrossRefs | Should -Be 0
    }

    It "T2: SKILLS-INDEX.md has no stale/orphaned skill entries" {
        $RepoRoot = "D:\gentleman-agent-gh"
        $skillsDir = Join-Path $RepoRoot ".agents\skills"
        $actualCount = (Get-ChildItem $skillsDir -Directory).Where({ $_.Name -ne '_shared' }).Count
        $indexLine = Select-String -Path (Join-Path $RepoRoot "SKILLS-INDEX.md") -Pattern "all \d+ skills"
        $indexLine.Matches.Value -match "all (\d+) skills" | Out-Null
        $declaredCount = [int]$Matches[1]
        $declaredCount | Should -Be $actualCount
    }

    It "T3: Every ## Cross-Refs entry resolves to a real skill directory" {
        $RepoRoot = "D:\gentleman-agent-gh"
        $skillsDir = Join-Path $RepoRoot ".agents\skills"
        $allSkillNames = @((Get-ChildItem $skillsDir -Directory).Where({ $_.Name -ne '_shared' }).ForEach({ $_.Name.ToLower() }))

        $brokenRefs = @()
        $skillDirs = (Get-ChildItem $skillsDir -Directory).Where({ $_.Name -ne '_shared' })
        foreach ($skill in $skillDirs) {
            $md = Join-Path $skill.FullName "SKILL.md"
            if (Test-Path $md) {
                $content = [IO.File]::ReadAllText($md)

                # Check Cross-Refs (## Cross-Refs and ## Refs)
                if ($content -match '(?im)^##\s*(?:Cross-)?Refs:?\s*(.*)$') {
                    $raw = $Matches[1]
                    if ([string]::IsNullOrWhiteSpace($raw) -and $Matches[0] -match ':\s*$') {
                        $afterHeader = $content.Substring($Matches[0].Length)
                        $nextLine = ($afterHeader -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
                        $raw = $nextLine
                    }
                    $boldTokens = @([regex]::Matches($raw, '\*\*([a-z][a-z0-9_-]+)\*\*', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) |
                        ForEach-Object { $_.Groups[1].Value.ToLower() })
                    $clean = [regex]::Replace($raw, '(?i)\*\*[a-z][a-z0-9_-]+\*\*(\s*\([^)]*\))?', ' ')
                    $splitTokens = @()
                    if ($clean -match '[·|,]' -or $boldTokens.Count -eq 0) {
                        $splitTokens = @($clean -split '\s*[·|,]\s*' |
                            ForEach-Object { $_.Trim() } |
                            Where-Object { $_ -cmatch '^[a-z][a-z0-9_-]+$' } |
                            ForEach-Object { $_.ToLower() })
                    }
                    $refs = @($boldTokens + $splitTokens | Select-Object -Unique)
                    foreach ($ref in $refs) {
                        if ($allSkillNames -notcontains $ref) {
                            $brokenRefs += "$($skill.Name) cross-refs '$ref' missing"
                        }
                    }
                }
            }
        }
        $brokenRefs.Count | Should -Be 0
    }

    It "T4: All skills have junctions in global config" {
        $RepoRoot = "D:\gentleman-agent-gh"
        $globalSkills = Join-Path $env:USERPROFILE ".config/opencode/skills"
        $skillsDir = Join-Path $RepoRoot ".agents\skills"
        $missingJunctions = @()
        $skillDirs = (Get-ChildItem $skillsDir -Directory).Where({ $_.Name -ne '_shared' })
        foreach ($skill in $skillDirs) {
            $junctionPath = Join-Path $globalSkills $skill.Name
            if (-not (Test-Path $junctionPath)) {
                $missingJunctions += $skill.Name
            }
        }
        $missingJunctions.Count | Should -Be 0
    }
}