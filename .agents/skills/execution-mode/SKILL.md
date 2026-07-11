---
name: execution-mode
description: "Auto-detect task execution mode — QUICK/THOROUGH/DRAFT — based on scope/risk/familiarity. NOT system resource optimization (see development-mode)."
triggers: "Execution mode, quick/thorough/draft, resource adaptive, zone green/yellow/orange/red"
license: Apache-2.0
metadata:
  tags: [engineering, runtime]
  author: gentleman-vMK
  version: "2.1"
  changelog: "2.1: karpathy compress"
---
## Modes
| Mode | When | Depth | Verification |
|------|------|-------|-------------|
| QUICK | Simple bugfix, known | Minimal | Tests only |
| THOROUGH | Complex, risky | Full SDD | Full gate |
| DRAFT | Explore, prototype | Notes | Skip |
## Decide: Simple/known→QUICK · Complex/risky→THOROUGH · Unclear→DRAFT (findings→ask)
## Auto-detect (when unspecified)
Scope (1-file vs multi), risk (typo vs data loss), familiarity (3x+ vs new), keywords ("fix" vs "redesign" vs "explore").
## Resource-Adaptive Zones
| Metric | Source | GREEN (<40%) | YELLOW (40-60%) | ORANGE (60-80%) | RED (>80%) |
|--------|--------|-------------|----------------|----------------|-----------|
| Context | ctx_stats | <40% | 40-60% | 60-80% | >80% |
| Depth | msgs+tools | LOW <10 | MEDIUM 10-25 | HIGH >25 | — |
| Errors | last 5 | 0 | 1 | 2+ | — |
| Response | — | Full | Brief+expand | Headline | 1-liner |
| Verify | — | Full | Essential | Non-critical skip | Skip all |
| Skills | — | Normal | Sparse | Minimal | Zero |
Compression: L1 summary (-60-70%) · L2 decisions+Engram (-40-50%) · L3 1-liner+ref (-80-90%)
**Rules**: Re-evaluate every 5 tools. Escalate on any HIGH. De-escalate after 3 lower. User override wins.
## Mode Rules
QUICK: sdd-quick (3-phase fast path: Propose→Apply→Verify). Code+tests. Score+move.
THOROUGH: Full SDD. Every decision→Engram. Quality gate. PR with evidence.
DRAFT: Explore first. No commit without user OK.

## Refs
development-mode · context-watchdog · lean-context · quality-gate · sdd · sdd-quick

## Anti-Patterns
DRAFT when user asked for THOROUGH · Skip zone re-evaluation · Ignore RED zone compression · Stay in one mode for entire session
