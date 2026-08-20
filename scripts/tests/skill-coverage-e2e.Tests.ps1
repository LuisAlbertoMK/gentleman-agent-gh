#requires -Version 7
<#
.SYNOPSIS
  E2E coverage gate for all 90 skills in .agents/skills/.
  Read-only validations (NO skill content mutated):
    - canonical count == 90 (excl _shared)  [aligns SKILLS-INDEX + README + .project.json]
    - YAML frontmatter (---, name, triggers, description) on every skill
    - every skill declares >=1 depth section (Examples|Testing|Anti-Patterns|Testing Patterns)
    - every declared Cross-Ref resolves to a real skill dir
  Pester 6 It-scope is isolated → data shared via BeforeAll + $script: vars
   (the canonical Pester pattern). Runs in ~6s, read-only.
  Run: Invoke-Pester scripts/tests/skill-coverage-e2e.Tests.ps1
#>

Set-StrictMode -Version Latest

Describe 'E2E: Skill Coverage (all 90 skills)' {
    BeforeAll {
        $proj = (git rev-parse --show-toplevel 2>$null)
        if (-not $proj) { $proj = $PWD.Path }
        $skillsDir = Join-Path $proj ".agents\skills"
        if (-not (Test-Path $skillsDir)) { throw "skills dir not found: $skillsDir (proj=$proj)" }
        $script:allDirs = @((Get-ChildItem $skillsDir -Directory -ErrorAction Stop).Name.ToLower())
        $script:skillTable = Get-ChildItem $skillsDir -Directory |
            Where-Object { $_.Name -ne '_shared' } | ForEach-Object {
                $p = Join-Path $skillsDir "$($_.Name)\SKILL.md"
                $c = if (Test-Path $p) { Get-Content $p -Raw } else { '' }
                [PSCustomObject]@{ Name = $_.Name; Content = $c }
            }
    }

    It 'canonical skill count is 91 (excl _shared)' {
        $script:skillTable.Count | Should -Be 91 -Because "SKILLS-INDEX/README/.project must agree on 91 canonical skills"
    }

    It 'every skill has valid YAML frontmatter (--- + name/triggers/description)' {
        foreach ($s in $script:skillTable) {
            $s.Content | Should -Match '^---'              -Because "$($s.Name): missing frontmatter '---'"
            $s.Content | Should -Match "name:\s+$($s.Name)" -Because "$($s.Name): frontmatter name mismatch"
            $s.Content | Should -Match 'triggers:'          -Because "$($s.Name): missing triggers"
            $s.Content | Should -Match 'description:'       -Because "$($s.Name): missing description"
        }
    }

    It 'every skill declares >=1 depth section (Examples/Testing/Anti-Patterns)' {
        foreach ($s in $script:skillTable) {
            $hasDepth = $s.Content -match '(?im)^##[^\n]*(Examples|Testing Patterns|Anti-Patterns|Edge Cases|Quality Gates)'
            # ADR-007: depth content (Examples/Testing Patterns/Edge Cases) is externalized to
            # docs/skills/<name>/reference.md to stay under the 3KB token budget — a reference
            # link satisfies the depth requirement.
            $hasExternalRef = $s.Content -match 'docs/skills/'
            ($hasDepth -or $hasExternalRef) |
                Should -BeTrue -Because "$($s.Name): no depth section or externalized reference (ADR-007)"
        }
    }

    It 'every declared Cross-Ref resolves to a real skill dir' {
        foreach ($s in $script:skillTable) {
            $raw = [regex]::Match($s.Content, '(?im)^##\s*(?:Cross-)?Refs:?\s*([^\r\n]*)').Groups[1].Value.Trim()
            if (-not $raw) { continue }  # no refs declared -> vacuously OK
            # bold-token format: **skill-name**(context) — case-insensitive
            $boldRefs = @([regex]::Matches($raw, '\*\*([a-z][a-z0-9_-]+)\*\*', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | ForEach-Object { $_.Groups[1].Value.ToLower() })
            $hasBold = $boldRefs.Count -gt 0
            $clean = [regex]::Replace($raw, '(?i)\*\*[a-z][a-z0-9_-]+\*\*(\s*\([^)]*\))?', ' ')
            $splitRefs = @()
            if ($clean -match '[·|,]' -or -not $hasBold) {
                $splitRefs = @($clean -split '[·|,]+' |
                    ForEach-Object { $_.Trim() } |
                    Where-Object { $_ -cmatch '^[a-z][a-z0-9_-]+$' } |
                    ForEach-Object { $_.ToLower() })
            }
            @($boldRefs + $splitRefs | Select-Object -Unique) | ForEach-Object {
                $script:allDirs -contains $_ | Should -BeTrue -Because "$($s.Name): references unknown ref '$_'"
            }
        }
    }
}
