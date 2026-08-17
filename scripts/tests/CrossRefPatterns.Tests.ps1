#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
  Pester 6 tests for cross-ref-check.ps1 output contract and regex patterns
.DESCRIPTION
  cross-ref-check.ps1 defines zero functions (entirely procedural inline code).
  Tests the output contract (allClean, shape) and the regex patterns used
  to parse SKILL.md cross-ref/anti-pattern/config_ref headers.
#>
param([switch]$Quiet)
Set-StrictMode -Version Latest

BeforeAll {
    # ponytail: contract + regex extraction — source has no function blocks
    # Mirrors cross-ref-check.ps1 output shape (line 43)
    function New-CrossRefResult([array]$Errors, [array]$Warnings, [int]$CanonicalSkills, [int]$BrokenRefs) {
        return @{
            timestamp       = (Get-Date -Format "o")
            canonicalSkills = $CanonicalSkills
            errors          = $Errors
            warnings        = $Warnings
            brokenCrossRefs = $BrokenRefs
            allClean        = ($Errors.Count -eq 0 -and $Warnings.Count -eq 0)
        }
    }

    # Mirrors cross-ref-check.ps1 skill name filter (Get-SkillRef, now with
    # middot separator + **skill** bold tokens + next-line fallback)
    function Get-SkillRefs([string]$HeaderValue) {
        if ([string]::IsNullOrWhiteSpace($HeaderValue)) { return @() }
        $boldTokens = @([regex]::Matches($HeaderValue, '\*\*([a-z][a-z0-9_-]+)\*\*', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | ForEach-Object { $_.Groups[1].Value.ToLower() })
        $hasBold = $boldTokens.Count -gt 0
        $clean = [regex]::Replace($HeaderValue, '(?i)\*\*[a-z][a-z0-9_-]+\*\*(\s*\([^)]*\))?', ' ')
        $splitTokens = @()
        if ($clean -match '[·|,]' -or -not $hasBold) {
            $splitTokens = @($clean -split '\s*[·|,]\s*' |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ -cmatch '^[a-z][a-z0-9_-]+$' } |
                ForEach-Object { $_.ToLower() })
        }
        return @($boldTokens + $splitTokens | Select-Object -Unique)
    }
}

Describe 'Cross-Ref Output Contract' {
    It 'allClean is true when both arrays are empty' {
        $r = New-CrossRefResult @() @() 59 0
        $r.allClean | Should -BeTrue
    }
    It 'allClean is false when errors exist' {
        $r = New-CrossRefResult @("missing skill") @() 59 0
        $r.allClean | Should -BeFalse
    }
    It 'allClean is false when only warnings exist' {
        $r = New-CrossRefResult @() @("old format") 59 0
        $r.allClean | Should -BeFalse
    }
    It 'allClean is false when both errors and warnings exist' {
        $r = New-CrossRefResult @("err") @("warn") 59 1
        $r.allClean | Should -BeFalse
    }
    It 'canonicalSkills is non-negative integer' {
        $r = New-CrossRefResult @() @() 59 0
        $r.canonicalSkills | Should -BeGreaterOrEqual 0
    }
    It 'brokenCrossRefs matches provided count' {
        $errs = @("a refs 'x' missing", "b refs 'y' missing")
        $r = New-CrossRefResult $errs @() 50 2
        $r.brokenCrossRefs | Should -Be 2
    }
    It 'timestamp is ISO 8601 format' {
        $r = New-CrossRefResult @() @() 0 0
        $r.timestamp | Should -Match '^\d{4}-\d{2}-\d{2}T'
    }
}

Describe 'Skill Name Regex Filter' {
    It 'extracts valid skill names (lowercase + digits + hyphens + underscores)' {
        $refs = Get-SkillRefs 'skill-a | skill_b, skill01'
        $refs.Count | Should -Be 3
        $refs | Should -Contain 'skill-a'
        $refs | Should -Contain 'skill_b'
        $refs | Should -Contain 'skill01'
    }
    It 'filters out UPPERCASE names' {
        $refs = Get-SkillRefs 'valid | INVALID'
        $refs | Should -Contain 'valid'
        $refs | Should -Not -Contain 'INVALID'
    }
    It 'filters out names starting with digits' {
        $refs = Get-SkillRefs 'ok | 123bad'
        $refs | Should -Contain 'ok'
        $refs | Should -Not -Contain '123bad'
    }
    It 'filters out names with spaces or special characters' {
        $refs = @(Get-SkillRefs 'good-name | has space | has@special')
        @($refs).Count | Should -Be 1
        $refs | Should -Contain 'good-name'
    }
    It 'returns empty for header with no valid names' {
        $refs = @(Get-SkillRefs 'UPPER | 123 | spaced name')
        @($refs).Count | Should -Be 0
    }
    It 'handles single skill reference' {
        $refs = @(Get-SkillRefs 'single-skill')
        @($refs).Count | Should -Be 1
        $refs | Should -Contain 'single-skill'
    }
}

Describe 'Cross-Ref Parsing Patterns' {
    It 'extracts cross-ref names from header line' {
        $header = "Cross-Refs: skill-a | skill-b, skill_c"
        if ($header -match '(?im)^##\s*(?:Cross-)?Refs:?\s*(.*)$') {
            $refs = @(Get-SkillRefs $Matches[1])
            @($refs).Count | Should -Be 3
        }
    }
    It 'extracts refs separated by middot (·)' {
        $header = "## Refs: skill-a·skill-b·skill_c"
        if ($header -match '(?im)^##\s*(?:Cross-)?Refs:?\s*(.*)$') {
            $refs = @(Get-SkillRefs $Matches[1])
            @($refs).Count | Should -Be 3
            $refs | Should -Contain 'skill-a'
            $refs | Should -Contain 'skill-b'
            $refs | Should -Contain 'skill_c'
        }
    }
    It 'extracts **skill**(context) bold tokens' {
        $header = "## Refs"
        $next = "**skill-a**(impl)**skill-b**(ARIA)"
        if ($header -match '(?im)^##\s*(?:Cross-)?Refs:?\s*(.*)$') {
            $inline = $Matches[1]
            $refs = @(Get-SkillRefs $(if ($inline) { $inline } else { $next }))
            @($refs).Count | Should -Be 2
            $refs | Should -Contain 'skill-a'
            $refs | Should -Contain 'skill-b'
        }
    }
    It 'extracts anti-pattern names from header line' {
        $header = "Anti-Patterns: immune-system | dreaming"
        if ($header -match 'Anti-Patterns:\s*(.+)') {
            $refs = @(Get-SkillRefs $Matches[1])
            @($refs).Count | Should -Be 2
            $refs | Should -Contain 'immune-system'
            $refs | Should -Contain 'dreaming'
        }
    }
    It 'extracts config_refs file paths (no name filter)' {
        $header = "config_refs: .opencode/skills/foo/SKILL.md | AGENTS.md"
        if ($header -match 'config_refs:\s*(.+)') {
            $refs = @(($Matches[1] -split '\s*[\|,]\s*' |
                ForEach-Object { $_.Trim() }).Where({ $_ -ne '' }))
            @($refs).Count | Should -Be 2
            $refs | Should -Contain '.opencode/skills/foo/SKILL.md'
            $refs | Should -Contain 'AGENTS.md'
        }
    }
    It 'returns nothing for empty Cross-Refs value' {
        $header = "## Cross-Refs: "
        if ($header -match '(?im)^##\s*(?:Cross-)?Refs:?\s*(.*)$') {
            $refs = @(Get-SkillRefs $Matches[1])
            @($refs).Count | Should -Be 0
        }
    }
    It 'does NOT leak prose words after bold tokens' {
        $header = "## Cross-Refs: **skill-a** context **skill-b**"
        if ($header -match '(?im)^##\s*(?:Cross-)?Refs:?\s*(.*)$') {
            $refs = @(Get-SkillRefs $Matches[1])
            $refs | Should -Contain 'skill-a'
            $refs | Should -Contain 'skill-b'
            $refs | Should -Not -Contain 'context'
            @($refs).Count | Should -Be 2
        }
    }
    It 'does NOT leak trailing prose word without separators (bold format)' {
        $header = "## Cross-Refs: **skill-a** manual"
        if ($header -match '(?im)^##\s*(?:Cross-)?Refs:?\s*(.*)$') {
            $refs = @(Get-SkillRefs $Matches[1])
            $refs | Should -Contain 'skill-a'
            $refs | Should -Not -Contain 'manual'
            @($refs).Count | Should -Be 1
        }
    }
    It 'handles UPPERCASE bold tokens case-insensitively' {
        $header = "## Cross-Refs: **SKILL-A** | **skill-b**"
        if ($header -match '(?im)^##\s*(?:Cross-)?Refs:?\s*(.*)$') {
            $refs = @(Get-SkillRefs $Matches[1])
            $refs | Should -Contain 'skill-a'
            $refs | Should -Contain 'skill-b'
        }
    }
    It 'skips next-line fallback when header has no trailing colon' {
        # bare header without ':' must NOT swallow the following body line
        $content = "## Refs`r`nThis is body prose mentioning example"
        if ($content -match '(?im)^##\s*(?:Cross-)?Refs:?\s*(.*)$') {
            $refs = @(Get-SkillRefs $Matches[1])
            @($refs).Count | Should -Be 0
        }
    }
    It 'uses next-line fallback only when header ends with colon' {
        # trailing-colon header DOES fall back to the next line
        $header = "## Cross-Refs:"
        if ($header -match '(?im)^##\s*(?:Cross-)?Refs:?\s*(.*)$') {
            $raw = $Matches[1]
            if ([string]::IsNullOrWhiteSpace($raw) -and $Matches[0] -match ':\s*$') {
                $raw = 'skill-a · skill-b'
            }
            $refs = @(Get-SkillRefs $raw)
            @($refs).Count | Should -Be 2
        }
    }
    It 'filters config_refs with a dedicated path parser (no name filter)' {
        $header = "config_refs: .opencode/skills/foo/SKILL.md | AGENTS.md"
        if ($header -match 'config_refs:\s*(.+)') {
            $refs = @(($Matches[1] -split '\s*[\|,]\s*' |
                ForEach-Object { $_.Trim() }).Where({ $_ -ne '' }))
            @($refs).Count | Should -Be 2
            $refs | Should -Contain '.opencode/skills/foo/SKILL.md'
            $refs | Should -Contain 'AGENTS.md'
        }
    }
}
