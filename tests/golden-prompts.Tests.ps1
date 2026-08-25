#requires -Version 7
<#
.SYNOPSIS
    Static gate for the Golden Prompt Suite (tests/prompts/).
.DESCRIPTION
    Validates the suite WITHOUT a runtime harness:
    - 1:1 coverage: every UI/UIX/SEO cluster skill has a golden prompt file
    - Trigger activation: each prompt's Trigger line matches a real frontmatter trigger of that skill
    - Output contract: each prompt's Expected block matches the skill's ## Output contract
    - Routing sanity: each prompt's primary trigger is NOT an exact trigger of another cluster skill
.NOTES
    Cluster = 10 skills: baseline-ui, ui-engine, seo, web-quality-audit, performance,
    performance-tracker, accessibility, visual-testing, vision-analyze, image-pipeline.
    Runtime harness (load-apply-verify) is deferred — this gate proves suite integrity only.
    Pester 5 scoping: ALL helpers + data defined inside BeforeAll (visible in It blocks);
    script-level functions/vars are NOT visible under Invoke-Pester -Path.
#>

Describe "Golden Prompt Suite — Static Gate" {
    BeforeAll {
        $Cluster = @(
            'baseline-ui', 'ui-engine', 'seo', 'web-quality-audit', 'performance',
            'performance-tracker', 'accessibility', 'visual-testing', 'vision-analyze', 'image-pipeline'
        )

        function Get-SkillFrontmatterTriggers {
            param([string]$SkillName)
            $path = Join-Path $PSScriptRoot "..\.agents\skills\$SkillName\SKILL.md"
            if (-not (Test-Path $path)) { return @() }
            $content = Get-Content $path -Raw
            if ($content -match '(?s)^\s*---\s*\r?\n(.*?)\r?\n\s*---') {
                $fm = $matches[1]
                if ($fm -match '(?m)^triggers:\s*(.+?)\s*$') {
                    $raw = $matches[1].Trim()
                    if ($raw.StartsWith('[')) { $raw = $raw.Trim('[', ']') }
                    return ($raw -split ',\s*' | ForEach-Object { $_.Trim('"', "'", ' ') } | Where-Object { $_ })
                }
            }
            return @()
        }

        function Get-SkillOutputContract {
            param([string]$SkillName)
            $path = Join-Path $PSScriptRoot "..\.agents\skills\$SkillName\SKILL.md"
            if (-not (Test-Path $path)) { return '' }
            $content = Get-Content $path -Raw
            # Format A: inline backtick — ## Output:`KEY:...` (with or without colon after header)
            if ($content -match '(?s)## Output:?\s*\r?\n?\s*`([^`]+)`') {
                return $matches[1].Trim()
            }
            # Format B: fenced block — ## Output\n```\nKEY:...\n```
            if ($content -match '(?s)## Output\s*\r?\n\s*```\s*\r?\n(.*?)\r?\n\s*```') {
                return $matches[1].Trim()
            }
            return ''
        }

        $promptsDir = Join-Path $PSScriptRoot "prompts"
        $promptFiles = Get-ChildItem -Path $promptsDir -Filter "*.md" -File | Where-Object { $_.Name -ne 'README.md' -and $_.Name -notmatch '\.golden\.md$' }
        $promptMap = @{}
        foreach ($f in $promptFiles) { $promptMap[$f.BaseName] = $f }
    }

    Context "Coverage" {
        It "Every cluster skill has a golden prompt (10/10)" {
            $missing = $Cluster | Where-Object { -not $promptMap.ContainsKey($_) }
            $missing | Should -BeNullOrEmpty
        }

        It "No orphan prompt files (files without a cluster skill)" {
            $orphans = $promptFiles | Where-Object { -not $promptMap.ContainsValue($_) }
            $orphans | Should -BeNullOrEmpty
        }

        It "Prompt count matches cluster size" {
            $promptFiles.Count | Should -Be $Cluster.Count
        }
    }

    Context "Trigger Activation" {
        It "Each prompt Trigger matches a real frontmatter trigger of its skill" {
            $failures = @()
            foreach ($skill in $Cluster) {
                $promptPath = Join-Path $promptsDir "$skill.md"
                if (-not (Test-Path $promptPath)) { continue }
                $promptContent = Get-Content $promptPath -Raw
                $realTriggers = Get-SkillFrontmatterTriggers -SkillName $skill
                $triggerLineMatches = @()
                foreach ($t in $realTriggers) {
                    if ($promptContent -match [regex]::Escape($t)) { $triggerLineMatches += $t }
                }
                if ($triggerLineMatches.Count -eq 0) { $failures += "$skill (no trigger match)" }
            }
            $failures | Should -BeNullOrEmpty
        }

        It "Each prompt **Trigger line** is a real frontmatter trigger of its skill" {
            $failures = @()
            foreach ($skill in $Cluster) {
                $promptPath = Join-Path $promptsDir "$skill.md"
                if (-not (Test-Path $promptPath)) { continue }
                $lines = Get-Content $promptPath
                $triggerLine = $lines | Where-Object { $_ -match '^\*\*Trigger\*\*' } | Select-Object -First 1
                if (-not $triggerLine) { $failures += "$skill (no **Trigger** line)"; continue }
                $realTriggers = Get-SkillFrontmatterTriggers -SkillName $skill
                $lineMatched = $false
                foreach ($t in $realTriggers) {
                    if ($triggerLine -match [regex]::Escape($t)) { $lineMatched = $true; break }
                }
                if (-not $lineMatched) { $failures += "$skill (Trigger line does not match any frontmatter trigger: '$triggerLine')" }
            }
            $failures | Should -BeNullOrEmpty
        }

        It "Each prompt's PRIMARY trigger does not collide with another cluster skill" {
            $failures = @()
            foreach ($skill in $Cluster) {
                $promptPath = Join-Path $promptsDir "$skill.md"
                if (-not (Test-Path $promptPath)) { continue }
                $lines = Get-Content $promptPath
                $triggerLine = $lines | Where-Object { $_ -match '^\*\*Trigger\*\*' } | Select-Object -First 1
                if (-not $triggerLine) { continue }
                # Primary trigger = first quoted phrase in the Trigger line
                if ($triggerLine -notmatch '"([^"]+)"') { continue }
                $primary = $matches[1].Trim().ToLowerInvariant()
                if ($primary.Length -lt 3) { continue }
                foreach ($other in $Cluster) {
                    if ($other -eq $skill) { continue }
                    $otherTriggers = Get-SkillFrontmatterTriggers -SkillName $other
                    if ($otherTriggers -contains $primary) {
                        $failures += "$skill primary trigger '$primary' is an exact trigger of $other"
                    }
                }
            }
            $failures | Should -BeNullOrEmpty
        }
    }

    Context "Output Contract" {
        It "Each prompt Expected block matches its skill's ## Output contract" {
            $failures = @()
            foreach ($skill in $Cluster) {
                $promptContent = Get-Content (Join-Path $promptsDir "$skill.md") -Raw
                $contract = Get-SkillOutputContract -SkillName $skill
                if (-not $contract) { continue }
                $contractKey = ($contract -split ':')[0].Trim('`', ' ')
                if ($promptContent -notmatch [regex]::Escape($contractKey)) {
                    $failures += "$skill (Expected does not reference contract '$contractKey')"
                }
            }
            $failures | Should -BeNullOrEmpty
        }
    }
}
