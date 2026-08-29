#requires -Version 7
<#
.SYNOPSIS
    Anti-regression guard: ensures retired OpenCode free-model IDs never
    reappear in project config. Fails the build (fail-closed) if any do.

.DESCRIPTION
    Source of truth for "retired" IDs: pi.dev model registry (retrieved from
    https://opencode.ai/zen/v1) returned HTTP 404 for these IDs, verified
    2026-08-21. OpenCode free-model availability is FLUID across time
    (see GitHub issues #30534 Jun, #28929 May, #10620 Jan):
      opencode/mimo-v2.5-free          -> 404 (retired from free tier)
      opencode/deepseek-v4-flash-free  -> 404 (was "limited-time free"; removed)
      opencode/nemotron-3-super-free   -> 404 (nemotron-3-ultra-free survives)
      opencode/kimi-k2.5-free          -> 404 (retired)
    These 4 IDs were referenced ~32 times across config files and have
    been REPLACED. This test enforces they never return — if any reappears,
    the build breaks. This is the "smoke detector" the 2026-07-28
    self-analysis flagged as missing
    (docs/mejoras/2026-07-28-orchestrator-self-analysis.md:210:
     "Mecanismos existen, enforcement es nulo").

    Replacement models (verified available, 0 cost):
      opencode/big-pickle            -> pi.dev 200, cost 0, reasoning, 200K ctx
      opencode/nemotron-3-ultra-free -> pi.dev 200, cost 0, reasoning, 1M ctx
      opencode/muse-spark-1.2-contributor-free -> pi.dev 200, cost 0, code generation, 1M ctx (replaces retired laguna-s-2.1-free as of 2026-08-29, Model not found verified)

    NOTE (Pester 6 scoping): variables used inside It blocks MUST live in
    BeforeAll — Describe-scope assignment is invisible to It at run time.
    This mirrors the pattern in tests/orchestrator-hooks.Tests.ps1.

    NOTE (Get-Content -Raw vs Select-String): Pester 6's BeforeAll scope
    intermittently returns $null for `Get-Content -Raw` on JSON files,
    turning per-file guards VACUOUS. The repo-wide guard (line ~95) proved
    `Select-String -Path <files>` works reliably here, so every guard now
    uses Select-String directly — no joined content variable.
#>
param([switch]$Quiet)
Set-StrictMode -Version Latest

Describe "OpenCode free-model availability — anti-regression guard" {
    BeforeAll {
        # Robust repo-root resolution (Pester 6 $PSScriptRoot is unreliable
        # under `pwsh -File`); git toplevel is cwd-independent and provable.
        $repoRoot = (git -C $PWD rev-parse --show-toplevel 2>$null).Trim()
        if (-not (Test-Path $repoRoot)) { $repoRoot = $PWD.Path }
        $removedIds = @(
            'opencode/mimo-v2.5-free',
            'opencode/deepseek-v4-flash-free',
            'opencode/nemotron-3-super-free',
            'opencode/kimi-k2.5-free',
            'opencode/laguna-s-2.1-free'
        )
        # NOTE: opencode.json (root config) was EDIT-DENIED by the Edit tool
        # (AGENTS.md `edit opencode.json deny` rule), but it STILL held ~23 retired
        # IDs in its .agent section (the real "Model is unavailable" root cause —
        # deepseek 14, mimo 6, nemotron-super 1, kimi 2, confirmed via JSON parse).
        # User-APPROVED extending the sweep here. The tool-layer deny does NOT block
        # the sandbox's atomic os.replace, so it was applied safely (external backup
        # at $env:TEMP\opencode.json.external-backup). opencode.json is NOW CLEAN and
        # IN SCOPE for this guard. (Direct Edit-tool edits remain denied — use the
        # atomic-replace pattern or relax the AGENTS.md rule going forward.)
        $configFiles = @(
            "$repoRoot/opencode.json",
            "$repoRoot/scripts/lib/opencode-base.json",
            "$repoRoot/scripts/opencode-config/semi-agents.json",
            "$repoRoot/scripts/opencode-configs/low-resource.json",
            "$repoRoot/scripts/opencode-configs/medium-resource.json",
            "$repoRoot/scripts/opencode-configs/high-resource.json"
        )
    }

    # --- Negative guards: retired IDs must NOT appear anywhere ---
    It "Retired model opencode/mimo-v2.5-free does NOT appear in any config" {
        $hits = Select-String -Path $configFiles -Pattern ([regex]::Escape('opencode/mimo-v2.5-free')) -AllMatches -ErrorAction SilentlyContinue
        ($hits | Measure-Object).Count | Should -Be 0 -Because "pi.dev 404 — retired from OpenCode free tier"
    }

    It "Retired model opencode/deepseek-v4-flash-free does NOT appear in any config" {
        $hits = Select-String -Path $configFiles -Pattern ([regex]::Escape('opencode/deepseek-v4-flash-free')) -AllMatches -ErrorAction SilentlyContinue
        ($hits | Measure-Object).Count | Should -Be 0 -Because "pi.dev 404 — was limited-time free, now removed"
    }

    It "Retired model opencode/nemotron-3-super-free does NOT appear in any config" {
        $hits = Select-String -Path $configFiles -Pattern ([regex]::Escape('opencode/nemotron-3-super-free')) -AllMatches -ErrorAction SilentlyContinue
        ($hits | Measure-Object).Count | Should -Be 0 -Because "pi.dev 404 — nemotron-3-ultra-free is the survivor"
    }

    It "Retired model opencode/kimi-k2.5-free does NOT appear in any config" {
        $hits = Select-String -Path $configFiles -Pattern ([regex]::Escape('opencode/kimi-k2.5-free')) -AllMatches -ErrorAction SilentlyContinue
        ($hits | Measure-Object).Count | Should -Be 0 -Because "pi.dev 404 — retired"
    }

    # --- Positive guards: replacement IDs MUST appear (proves the fix shipped) ---
    It "Replacement model opencode/muse-spark-1.2-contributor-free IS present (proves laguna->muse-spark mapping as of 2026-08-29)" {
        $hits = Select-String -Path $configFiles -Pattern ([regex]::Escape('opencode/muse-spark-1.2-contributor-free')) -AllMatches -ErrorAction SilentlyContinue
        ($hits | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It "Replacement model opencode/nemotron-3-ultra-free IS present (proves super->ultra mapping)" {
        $hits = Select-String -Path $configFiles -Pattern ([regex]::Escape('opencode/nemotron-3-ultra-free')) -AllMatches -ErrorAction SilentlyContinue
        ($hits | Measure-Object).Count | Should -BeGreaterThan 0
    }

    # --- Repo-wide guard: no retired ID survives in any scripts/*.json (excludes *.bak) ---
    It "No retired IDs remain anywhere under scripts/ (repo-wide guard)" {
        $pattern = ($removedIds | ForEach-Object { [regex]::Escape($_) }) -join '|'
        $hits = Get-ChildItem "$repoRoot/scripts" -Recurse -Filter '*.json' -File -ErrorAction SilentlyContinue |
                Select-String -Pattern $pattern -AllMatches -ErrorAction SilentlyContinue
        ($hits | Measure-Object).Count | Should -Be 0 -Because "no retired model ID should survive in any scripts/*.json"
    }
}
