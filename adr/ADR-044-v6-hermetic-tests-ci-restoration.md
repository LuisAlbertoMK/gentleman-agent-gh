# ADR-044: V6 hermetic test suite + CI restoration

- **Status**: Accepted (experiment branch — NOT merged to main)
- **Date**: 2026-08-24
- **Branch**: `experimento/mejora-autonoma-v6-2026-08-24` (base: main @ `d3ab1003`)
- **Protocol**: docs/protocolos/protocolo_mejora_autonoma_v3.md

## Context

Post-V5 full-suite run showed 27 failures. Worktree comparison vs clean main
proved none were caused by V5, but 6 test FILES failed chronically on EVERY
machine due to code-level defects: hardcoded absolute paths from at least two
different machines (`D:/gentleman-agent-gh` ×5, `C:/Users/MK` ×1), a duplicate
`#requires` directive making a production script permanently unparseable, and
tests asserting mutable live-machine state (opencode.json profile, global
junctions, repo token budget). Additionally the GitHub Actions workflows from
C5 had gone missing from the repo — no enforcement layer existed.

## Decision

1. **Kill the whole class, not instances**: swept scripts/tests for hardcoded
   machine paths; replaced with `PSScriptRoot` derivation everywhere.
2. **Real bug fix (§3.6)**: `remove-semi-agents.ps1` had `#requires -Version 5.1`
   AND `#requires -Version 7` → parse error since birth. Removed stale directive.
3. **Machine-state vs repo-contract separation**: tests validating machine setup
   (global config presence, skill junctions) now derive paths portably AND skip
   in CI (`-Skip:($env:CI -eq 'true')`) — they stay honest-red locally when the
   machine drifts, which is valuable signal, not noise.
4. **Hermetic fixtures over live-state assertions**: token-budget over-budget
   test uses a temp fixture; benchmark R6 pins baseline inside a child pwsh with
   clean USERPROFILE; resource-optimization dropped its live-opencode.json block.
5. **CI restored** (.github/workflows/ci.yml): pester-tests job (run-ci-tests.ps1,
   PESTER_TEST=1) + pssa-lint job (repo PSScriptAnalyzerSettings.psd1, errors block).

## Consequences

- Suite is green on any clean checkout (CI-verifiable); local runs surface real
  machine drift instead of fake regressions (this machine currently has 13
  untracked skills, 49 dead junctions, 20 missing junctions — user decision).
- Known limitation: CI first run may reveal runner-specific failures not
  reproducible locally; iterate on the branch before merge.

## Verification

Per-suite: remove-semi-agents 9/9 · resource-optimization 13/13 ·
subagent-quality-e2e 5/5 · benchmark 7/7 · subagent-e2e 2/2 · readme-drift 4/4 ·
check-token-budget 7/7 · async-resilience 16/16 · monitor-callback 17/17 ·
babyagi-async-push 12/12.
