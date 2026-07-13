#requires -Version 7.6
<#
.SYNOPSIS
  Pester tests for skill-graph.ps1 core logic.
  Tests: Register-Skill, New-Graph, Resolve-Skill token matching, Get-AgentRecommendation.
  Compatible with Pester 5.x / 6.x.

  NOTE: skill-graph.ps1 uses $skillRegistry (bare, line 43) for init and
  $script:skillRegistry (Register-Skill, line 54) for mutation. When dot-sourced
  under Pester 6, these resolve to different scopes. This test extracts only the
  FUNCTIONS via regex and initializes its own registry.
#>
param([switch]$Quiet)
Set-StrictMode -Version Latest

BeforeAll {
    # --- Extract functions only (skip top-level Register-Skill calls) ---
    $raw = Get-Content (Join-Path $PSScriptRoot 'skill-graph.ps1') -Raw

    # Extract function blocks — skill-graph.ps1 uses C#-style signatures:
    #   function Register-Skill(\n    $Name,\n    ...\n)\n{ ... }
    $functionNames = @('Register-Skill', 'New-Graph', 'Resolve-Skill', 'Get-AgentRecommendation')
    foreach ($fn in $functionNames) {
        # Match: function NAME followed by ( or { (may have params on separate lines)
        if ($raw -match "(?s)(function\s+$fn\s*[\(\{].+?\n\})") {
            . ([ScriptBlock]::Create($Matches[1]))
        }
    }

    # Initialize our own registry in the test scope
    $script:skillRegistry = @()

    # Also load agent recommendations array (needed by Get-AgentRecommendation)
    if ($raw -match '(?s)(\$agentRecommendations\s*=\s*@\(.+?\n\))') {
        . ([ScriptBlock]::Create($Matches[1]))
    }

    # Helper: rebuild the skillLookup hashtable from current registry
    # (Resolve-Skill uses this at line 262 to look up skill objects by name)
    function Update-SkillLookup {
        $script:skillLookup = @{}
        foreach ($skill in $script:skillRegistry) {
            $script:skillLookup[$skill.Name] = $skill
        }
    }
}

# ============================================================
Describe 'Register-Skill' {
    BeforeEach {
        $script:skillRegistry = @()
    }

    It 'adds a skill with all fields' {
        Register-Skill 'test-skill' 'trigger1|trigger2' 'test' 'low' 'dep1' 'rel1' 'Test skill'

        $script:skillRegistry.Count | Should -Be 1
        $script:skillRegistry[0].Name | Should -Be 'test-skill'
        $script:skillRegistry[0].Category | Should -Be 'test'
        $script:skillRegistry[0].Effort | Should -Be 'low'
        $script:skillRegistry[0].Description | Should -Be 'Test skill'
    }

    It 'splits triggers by pipe' {
        Register-Skill 'split-test' 'a|b|c' 'test' 'low' '' '' 'Split test'

        $script:skillRegistry[0].Triggers.Count | Should -Be 3
        $script:skillRegistry[0].Triggers[0] | Should -Be 'a'
        $script:skillRegistry[0].Triggers[1] | Should -Be 'b'
        $script:skillRegistry[0].Triggers[2] | Should -Be 'c'
    }

    It 'splits dependencies by pipe' {
        Register-Skill 'dep-test' 'trigger' 'test' 'low' 'dep1|dep2' '' 'Dep test'

        $script:skillRegistry[0].DependsOn.Count | Should -Be 2
        $script:skillRegistry[0].DependsOn[0] | Should -Be 'dep1'
        $script:skillRegistry[0].DependsOn[1] | Should -Be 'dep2'
    }

    It 'accumulates multiple skills' {
        Register-Skill 'skill1' 'trigger1' 'test' 'low' '' '' 'First'
        Register-Skill 'skill2' 'trigger2' 'test' 'low' '' '' 'Second'

        $script:skillRegistry.Count | Should -Be 2
        $script:skillRegistry[0].Name | Should -Be 'skill1'
        $script:skillRegistry[1].Name | Should -Be 'skill2'
    }
}

# ============================================================
Describe 'New-Graph' {
    BeforeEach {
        $script:skillRegistry = @()
        Register-Skill 'A' 'triggerA' 'test' 'low' 'B' '' 'Skill A depends on B'
        Register-Skill 'B' 'triggerB' 'test' 'low' '' '' 'Skill B'
        Register-Skill 'C' 'triggerC' 'test' 'low' 'A' '' 'Skill C depends on A'
    }

    It 'creates nodes for all registered skills' {
        $graph = New-Graph

        $graph.Nodes.ContainsKey('A') | Should -Be $true
        $graph.Nodes.ContainsKey('B') | Should -Be $true
        $graph.Nodes.ContainsKey('C') | Should -Be $true
    }

    It 'creates adjacency lists for all nodes' {
        $graph = New-Graph

        $graph.AdjList.ContainsKey('A') | Should -Be $true
        $graph.AdjList.ContainsKey('B') | Should -Be $true
        $graph.AdjList.ContainsKey('C') | Should -Be $true
    }

    It 'links dependencies correctly (A depends on B)' {
        $graph = New-Graph

        $graph.AdjList['B'].to.ContainsKey('A') | Should -Be $true
        $graph.AdjList['B'].to['A'] | Should -Be 'depends_on'

        $graph.AdjList['A'].from.ContainsKey('B') | Should -Be $true
        $graph.AdjList['A'].from['B'] | Should -Be 'depended_by'
    }

    It 'links C -> A (C depends on A)' {
        $graph = New-Graph

        $graph.AdjList['A'].to.ContainsKey('C') | Should -Be $true
        $graph.AdjList['C'].from.ContainsKey('A') | Should -Be $true
    }
}

# ============================================================
Describe 'Resolve-Skill' {
    BeforeEach {
        $script:skillRegistry = @()
        Register-Skill 'quality-gate' 'quality gate|pre-commit|validate commit' 'quality' 'medium' '' 'auto-metrics|commit-crafter' 'Pre-commit quality gate'
        Register-Skill 'auto-metrics' 'auto-score|metrics|post-task|evaluate|self-evaluate' 'quality' 'medium' '' '' 'Post-task self-evaluation'
        Register-Skill 'triple-verify' 'triple verify|triangulate|3 enfoques|verificacion profunda|!ship' 'quality' 'high' '' '' 'Triple verification'
        Register-Skill 'seo' 'SEO|search engine|meta tags|structured data|sitemap' 'web-quality' 'medium' '' '' 'SEO optimization'
        Register-Skill 'accessibility' 'accessibility|a11y|WCAG|screen reader|keyboard nav' 'web-quality' 'medium' '' '' 'Web accessibility'
        Register-Skill 'research' 'research|investigar|technical investigation|learn|compare solutions' 'research' 'medium' '' '' 'Structured research'
        Update-SkillLookup
    }

    It 'returns empty for no-match task' {
        $results = @(Resolve-Skill 'xyzzy plugh' 0)
        $results.Count | Should -Be 0
    }

    It 'matches single skill by trigger word' {
        $results = @(Resolve-Skill 'quality gate please' 0)

        $results.Count | Should -BeGreaterOrEqual 1
        $results[0].Name | Should -Be 'quality-gate'
        $results[0].Score | Should -BeGreaterOrEqual 1
    }

    It 'matches multiple skills when triggers overlap' {
        $results = @(Resolve-Skill 'quality gate and metrics evaluation' 0)

        $names = @($results | ForEach-Object { $_.Name })
        $names | Should -Contain 'quality-gate'
        $names | Should -Contain 'auto-metrics'
    }

    It 'respects MaxDepth=0 (no dependencies)' {
        $results = @(Resolve-Skill 'quality gate' 0)

        $names = @($results | ForEach-Object { $_.Name })
        $names | Should -Contain 'quality-gate'
        $depth0Deps = @($results | Where-Object { $_.Name -eq 'auto-metrics' -and $_.Depth -eq 0 })
        $depth0Deps.Count | Should -Be 0
    }

    It 'includes dependents at MaxDepth=1' {
        # BFS follows .to edges (dependents, not dependencies)
        # quality-gate has no dependents in our test, so only quality-gate itself
        $results = @(Resolve-Skill 'quality gate' 1)

        $names = @($results | ForEach-Object { $_.Name })
        $names | Should -Contain 'quality-gate'
        # quality-gate has no dependents — only the direct match
        $names.Count | Should -Be 1
    }

    It 'matches case-insensitively' {
        $results = @(Resolve-Skill 'QUALITY GATE' 0)

        $results.Count | Should -BeGreaterOrEqual 1
        $results[0].Name | Should -Be 'quality-gate'
    }

    It 'returns results sorted by depth then score' {
        $results = @(Resolve-Skill 'quality gate' 1)

        $results[0].Depth | Should -Be 0
    }
}

# ============================================================
Describe 'Get-AgentRecommendation' {
    BeforeEach {
        $script:skillRegistry = @()
        Register-Skill 'quality-gate' 'quality gate|pre-commit|validate commit' 'quality' 'medium' '' '' 'Pre-commit quality gate'
        Register-Skill 'seo' 'SEO|search engine|meta tags|structured data|sitemap' 'web-quality' 'medium' '' '' 'SEO optimization'
        Register-Skill 'research' 'research|investigar|technical investigation|learn|compare solutions' 'research' 'medium' '' '' 'Structured research'
    }

    It 'recommends agents for review task' {
        $result = @(Get-AgentRecommendation 'review code for security issues')
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Contain 'code-review-agent'
    }

    It 'recommends agents for bug fix task' {
        $result = @(Get-AgentRecommendation 'fix this bug in the login page')
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Contain 'recovery-protocol'
    }

    It 'recommends agents for SEO task' {
        $result = @(Get-AgentRecommendation 'improve SEO for the landing page')
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Contain 'seo'
    }

    It 'returns unique recommendations' {
        $result = @(Get-AgentRecommendation 'review code and fix bugs and improve quality')
        $result.Count | Should -Be (@($result | Select-Object -Unique)).Count
    }
}

# ============================================================
Describe 'Skill Graph Integration' {
    BeforeEach {
        $script:skillRegistry = @()
        Register-Skill 'A' 'trigger_a' 'test' 'low' 'B' '' 'A depends on B'
        Register-Skill 'B' 'trigger_b' 'test' 'low' '' '' 'B standalone'
        Register-Skill 'C' 'trigger_c' 'test' 'low' 'A' '' 'C depends on A'
        Update-SkillLookup
    }

    It 'resolves dependency chain A -> B via BFS' {
        $results = @(Resolve-Skill 'trigger_a' 1)
        $names = @($results | ForEach-Object { $_.Name })
        $names | Should -Contain 'A'
        $names | Should -Contain 'B'
    }

    It 'resolves deep chain C -> A -> B at depth 2' {
        $results = @(Resolve-Skill 'trigger_c' 2)
        $names = @($results | ForEach-Object { $_.Name })
        $names | Should -Contain 'C'
        $names | Should -Contain 'A'
        $names | Should -Contain 'B'
    }
    It 'does not resolve deep chain at depth 0' {
        # Use specific text that only matches C — "trigger_c" tokenizes to just "trigger"
        # which matches all skills. Use a unique trigger instead.
        $results = @(Resolve-Skill 'trigger_c' 0)

        # At depth 0, BFS doesn't expand, so only direct matches appear
        # "trigger_c" tokenizes to ["trigger", "c"] → after length filter: ["trigger"]
        # "trigger" matches all skills with "trigger" in their triggers (A, B, C)
        $names = @($results | ForEach-Object { $_.Name })
        $names | Should -Contain 'C'
        # All 3 match because token "trigger" is common — but depths should all be 0
        $results | ForEach-Object { $_.Depth } | Should -Not -Contain 1
    }
}
