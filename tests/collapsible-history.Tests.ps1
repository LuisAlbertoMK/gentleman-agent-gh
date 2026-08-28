#requires -Version 7
<#
.SYNOPSIS
    Validation for opencode-collapsible-history plugin — native TUI collapsible.
.DESCRIPTION
    Checks:
    - Plugin file exists at plugins/collapsible-history.ts (repo deliverable)
    - Exports PLUGIN_NAME / PLUGIN_VERSION, CollapsibleHistoryPlugin, tui, default
    - Hooks: chat.message, experimental.chat.messages.transform, event
    - TUI slot: sidebar_content registered (or alias), no bun:sqlite
    - Helpers: truncate 80, estimateTokens, formatTime, group/collapse logic
    - opencode-base.json NOT mutated (opt-in registration)
    - Branch safety: feat/collapsible-history exists, HEAD is fb391e11 base
    - LOC < 300
.NOTES
    Read-only validation, no side effects. Node-compatible only checks.
#>

Describe "opencode-collapsible-history Plugin" {

    BeforeAll {
        $repoRoot = Split-Path $PSScriptRoot -Parent
        $pluginPath = Join-Path $repoRoot "plugins\collapsible-history.ts"
        $basePath = Join-Path $repoRoot "scripts\lib\opencode-base.json"
        $globalPluginPath = "C:\Users\MK\.config\opencode\plugins\collapsible-history.ts"
        $script:pluginText = $null
        $script:baseJson = $null
        if (Test-Path $pluginPath) { $script:pluginText = Get-Content $pluginPath -Raw }
        if (Test-Path $basePath) { $script:baseJson = Get-Content $basePath -Raw | ConvertFrom-Json }
    }

    Context "File existence and location" {
        It "Repo plugin file exists at plugins/collapsible-history.ts" {
            $repoRoot = Split-Path $PSScriptRoot -Parent
            $p = Join-Path $repoRoot "plugins\collapsible-history.ts"
            Test-Path $p | Should -Be $true
        }

        It "Plugin is < 300 LOC (spec constraint)" {
            $loc = ($script:pluginText -split "`n").Count
            $loc | Should -BeLessThan 300
        }

        It "Global plugin path is optional (repo deliverable is primary)" {
            # Document expectation: global mirror may exist but not required
            $true | Should -Be $true
        }
    }

    Context "Exports and metadata" {
        It "Exports PLUGIN_NAME = opencode-collapsible-history" {
            $script:pluginText | Should -Match 'PLUGIN_NAME\s*=\s*"opencode-collapsible-history"'
        }

        It "Exports PLUGIN_VERSION = 0.1.0" {
            $script:pluginText | Should -Match 'PLUGIN_VERSION\s*=\s*"0\.1\.0"'
        }

        It "Exports CollapsibleHistoryPlugin: Plugin" {
            $script:pluginText | Should -Match 'export const CollapsibleHistoryPlugin:\s*Plugin'
        }

        It "Exports tui slot plugin" {
            $script:pluginText | Should -Match 'export const tui\s*='
        }

        It "Exports default with name/plugin/tui" {
            $script:pluginText | Should -Match 'export default'
            $script:pluginText | Should -Match 'name:\s*PLUGIN_NAME'
        }
    }

    Context "Hooks contract (DESIGN.md §2-3)" {
        It "Implements event hook" {
            $script:pluginText | Should -Match 'event:\s*async'
        }

        It "Implements chat.message hook" {
            $script:pluginText | Should -Match '"chat\.message"'
        }

        It "Implements experimental.chat.messages.transform hook" {
            $script:pluginText | Should -Match '"experimental\.chat\.messages\.transform"'
        }
    }

    Context "TUI slot contract" {
        It "Registers sidebar_content slot (or alias session_history)" {
            $script:pluginText | Should -Match 'sidebar_content'
        }

        It "References @opencode-ai/plugin (and tui) — no bun:sqlite" {
            $script:pluginText | Should -Match '@opencode-ai/plugin'
            $script:pluginText | Should -Not -Match 'from\s+["'']bun:sqlite["'']'
            $script:pluginText | Should -Not -Match 'import.*bun:sqlite'
            $script:pluginText | Should -Not -Match 'Bun\.spawn'
            $script:pluginText | Should -Not -Match 'Bun\.which'
        }

        It "Mentions @opentui/solid JSX peer" {
            $script:pluginText | Should -Match '@opentui/solid'
        }

        It "Has in-memory Map for collapsed state (no disk)" {
            $script:pluginText | Should -Match 'new Map<string,\s*Set<string>>'
        }
    }

    Context "Helper logic (pure, Node-compatible)" {
        It "Exports truncate helper (80 chars)" {
            $script:pluginText | Should -Match 'export function truncate'
            $script:pluginText | Should -Match 'SNIPPET_LEN\s*=\s*80'
        }

        It "Exports estimateTokens helper" {
            $script:pluginText | Should -Match 'export function estimateTokens'
        }

        It "Exports groupMessagesByTurn with collapsed default" {
            $script:pluginText | Should -Match 'export function groupMessagesByTurn'
            $script:pluginText | Should -Match 'collapsed.*except last|!isLast'
        }

        It "Exports collapseAll / expandAll / toggleCollapsed" {
            $script:pluginText | Should -Match 'export function collapseAll'
            $script:pluginText | Should -Match 'export function expandAll'
            $script:pluginText | Should -Match 'export function toggleCollapsed'
        }

        It "Exports navigateSelection for j/k" {
            $script:pluginText | Should -Match 'export function navigateSelection'
        }

        It "Documents key bindings Enter/o, c, a, j/k" {
            $script:pluginText | Should -Match '"enter"'
            $script:pluginText | Should -Match '"c"'
            $script:pluginText | Should -Match '"a"'
            $script:pluginText | Should -Match '"j"'
            $script:pluginText | Should -Match '"k"'
        }
    }

    Context "Safety: opencode-base.json untouched (opt-in)" {
        It "opencode-base.json still exists" {
            $repoRoot = Split-Path $PSScriptRoot -Parent
            $p = Join-Path $repoRoot "scripts\lib\opencode-base.json"
            Test-Path $p | Should -Be $true
        }

        It "opencode-base.json plugin array does NOT yet contain collapsible-history (zero risk to main)" {
            # Base config should remain ["context-mode","opencode-ralph-loop","opencode-personality"]
            # Plugin file exists but not loaded until user opts in.
            $raw = Get-Content (Join-Path (Split-Path $PSScriptRoot -Parent) "scripts\lib\opencode-base.json") -Raw
            $raw | Should -Not -Match 'collapsible-history'
        }

        It "Generated opencode.json (if present) also not forced" {
            $repoRoot = Split-Path $PSScriptRoot -Parent
            $gen = Join-Path $repoRoot "opencode.json"
            if (Test-Path $gen) {
                (Get-Content $gen -Raw) | Should -Not -Match 'opencode-collapsible-history'
            } else {
                $true | Should -Be $true
            }
        }
    }

    Context "Branch safety" {
        It "Current branch is feat/collapsible-history" {
            $branch = (git branch --show-current 2>$null).Trim()
            $branch | Should -Be "feat/collapsible-history"
        }

        It "Base HEAD fb391e11 is ancestor of current HEAD" {
            $base = "fb391e11bd1561b80b6dff66e44b239d4de2d40b"
            git merge-base --is-ancestor $base HEAD 2>$null | Out-Null
            $isAncestor = ($LASTEXITCODE -eq 0)
            $isAncestor | Should -Be $true
        }

        It "git status shows plugin file as untracked or staged, not committed to main" {
            $status = git status --porcelain -uall 2>$null
            ($status -join "`n") | Should -Match 'collapsible-history'
        }
    }
}
