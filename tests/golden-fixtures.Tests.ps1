#requires -Version 7
<#
.SYNOPSIS
    Static gate for Golden Prompt fixtures (tests/prompts/*.golden.md).
.DESCRIPTION
    Validates the golden-prompt suite structurally WITHOUT a runtime LLM
    harness: 1:1 coverage, 5-section integrity, contract-shape and a live
    cross-reference against each skill ## Output contract. Skills that
    document Output as prose (e.g. image-pipeline) are governed by a
    whitelist fallback.
.NOTES
    Cluster = 10 design-cluster skills. Helpers live in BeforeAll because
    script-level bindings are not visible under Invoke-Pester -Path.
#>
Describe 'Golden Prompt Suite - Static Gate - Fixtures' {
    BeforeAll {
        $Cluster = @(
            'baseline-ui','ui-engine','seo','web-quality-audit','performance',
            'performance-tracker','accessibility','visual-testing','vision-analyze','image-pipeline'
        )
        $promptsDir = Join-Path $PSScriptRoot 'prompts'
        $RequiredSections = @('## Skill','## Trigger','## Input','## Expected Output','## Assertion')
        $KeyWhitelist = @{
            'baseline-ui'         = 'UI-CLEANUP'
            'ui-engine'           = 'UI-IMPLEMENT'
            'seo'                 = 'SEO AUDIT'
            'web-quality-audit'   = 'AUDIT'
            'performance'         = 'PERF-AUDIT'
            'performance-tracker' = 'PERF-SCORE'
            'accessibility'       = 'A11Y-AUDIT'
            'visual-testing'      = 'VRT'
            'vision-analyze'      = 'VISION'
            'image-pipeline'      = 'IMG-PIPELINE'
        }

        function Get-SkillOutputContract {
            param([string]$SkillName)
            $rel = '..\.agents\skills\' + $SkillName + '\SKILL.md'
            $path = Join-Path $PSScriptRoot $rel
            if (-not (Test-Path $path)) { return '' }
            $content = Get-Content $path -Raw
            if ($content -match '(?s)##\s*Output:?\s*\r?\n\s*`([^`]+)`') { return $Matches[1].Trim() }
            if ($content -match '(?s)##\s*Output\s*\r?\n\s*```\s*\r?\n(.*?)\r?\n\s*```') { return $Matches[1].Trim() }
            return ''
        }

        function Get-ExpectedLine {
            param([string]$Path)
            $all = Get-Content $Path
            $i = [Array]::IndexOf($all, '## Expected Output')
            if ($i -lt 0 -or $i -ge $all.Count - 1) { return '' }
            return $all[$i + 1].Trim()
        }
    }

    Context 'Coverage' {
        It 'Every cluster skill has a golden fixture (10/10)' {
            $names = (Get-ChildItem -Path $promptsDir -Filter '*.golden.md' -File |
                ForEach-Object { $_.BaseName -replace '\.golden$', '' } | Sort-Object)
            $missing = $Cluster | Where-Object { $names -notcontains $_ }
            $missing | Should -BeNullOrEmpty
            $names.Count | Should -Be $Cluster.Count
        }
    }

    Context 'Structure' {
        It 'Each golden fixture contains all 5 required sections' {
            $failures = @()
            foreach ($skill in $Cluster) {
                $p = Join-Path $promptsDir ($skill + '.golden.md')
                if (-not (Test-Path $p)) { $failures += ($skill + ' (missing)'); continue }
                $txt = Get-Content $p -Raw
                $miss = $RequiredSections | Where-Object { $txt -notmatch [regex]::Escape($_) }
                if ($miss) { $failures += ($skill + ' (missing: ' + ($miss -join ',') + ')') }
            }
            $failures | Should -BeNullOrEmpty
        }

        It 'No golden fixture exceeds 12 KB (bloat guard)' {
            $oversized = Get-ChildItem -Path $promptsDir -Filter '*.golden.md' -File |
                Where-Object { $_.Length -gt 12KB }
            $oversized | Should -BeNullOrEmpty
        }
    }

    Context 'Contract Shape' {
        It 'Each golden fixture Expected Output references its skill contract key' {
            $failures = @()
            foreach ($skill in $Cluster) {
                $p = Join-Path $promptsDir ($skill + '.golden.md')
                if (-not (Test-Path $p)) { $failures += ($skill + ' (missing)'); continue }
                $expected = Get-ExpectedLine -Path $p
                if (-not $expected) { $failures += ($skill + ' (no Expected Output line)'); continue }
                # Prefer the live SKILL.md contract key; fall back to the whitelist only for
                # skills that document Output as prose (e.g. image-pipeline) so the check is
                # grounded in source-of-truth whenever a machine-readable contract exists.
                $contract = Get-SkillOutputContract -SkillName $skill
                $key = if ($contract) { ($contract -split ':')[0].Trim() } else { $KeyWhitelist[$skill] }
                if ($expected -notmatch [regex]::Escape($key)) {
                    $failures += ($skill + ' (Expected Output does not reference contract key ' + $key + ')')
                }
            }
            $failures | Should -BeNullOrEmpty
        }
    }
}
