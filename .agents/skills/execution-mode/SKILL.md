---
name: execution-mode
description: "Auto-detect task execution mode — QUICK, THOROUGH, or DRAFT — based on scope, risk, familiarity, and keywords"
triggers: "Execution mode, quick/thorough/draft, resource adaptive, zone green/yellow/orange/red, runtime mode"
license: Apache-2.0
metadata:
  tags:
    - engineering
    - runtime
  author: gentleman-vMK
  version: "2.0"
  changelog: "1.1->2.0: added resource-adaptive zone matrix — GREEN/YELLOW/ORANGE/RED dynamic runtime adaptation"
---

## TASK MODES
| Mode | When | Depth | Artifacts | Verification |
|------|------|-------|-----------|-------------|
| QUICK | Simple bugfix, known pattern | Minimal | None/1-file | Tests only |
| THOROUGH | Complex feature, risky change | Full SDD | Spec+Design+Verify | Full gate |
| DRAFT | Exploration, prototyping | Light | Notes only | Skip |

## DECIDE
Simple/known? -> QUICK (code+tests+commit) | Complex/risky? -> THOROUGH (full SDD) | Unclear/exploring? -> DRAFT (findings -> ask -> commit)

## AUTO-DETECTION (when unspecified)
Infer from: scope (1-file vs multi-file), risk (typo vs security/data loss), familiarity (3x+ vs new), keywords ("fix/typo" vs "arch/redesign" vs "explore/what if"), tone.

## RESOURCE-ADAPTIVE ZONE OVERRIDE
Task mode is per-task. Resource zone adjusts behavioral knobs continuously.

### Metrics
| Metric | Source | GREEN (<40%) | YELLOW (40-60%) | ORANGE (60-80%) | RED (>80%) |
|--------|--------|-------------|----------------|----------------|-----------|
| Context Pressure | ctx_stats | <40% | 40-60% | 60-80% | >80% |
| Session Depth | msgs+tool calls | LOW <10 | MEDIUM 10-25 | HIGH >25 | - |
| Error Rate | last 5 tools | LOW 0 | MEDIUM 1 | HIGH 2+ | - |

### Zone -> Behavior
| Zone | Response | Compression | Verification | Skill Loading |
|------|----------|-------------|-------------|---------------|
| GREEN | Full answer | L1 normal | Full gate | Normal |
| YELLOW | Brief+expand | L1+L2 proactive | Essential | Sparse |
| ORANGE | Headline | L2 forced | Skip non-critical | Minimal |
| RED | 1-liner | L3 emergency | Skip all | Zero |

### Rules
Static+dynamic combined: THOROUGH in YELLOW = full SDD + shorter summaries. Re-evaluate every 5 tools. Escalate on any HIGH; de-escalate after 3 checks in lower zone. User override wins.

### Compression Levels
L1: Oldest raw -> full summary (-60-70%) | L2: L1s -> decisions+Engram IDs (-40-50%) | L3: 1-liner + engram-obs-ref (-80-90%)

## MODE RULES
QUICK: No SDD. Code+tests. Score+move.
THOROUGH: Full SDD. Every decision to Engram. Quality gate. PR with evidence.
DRAFT: Explore first. No commit without user OK.
