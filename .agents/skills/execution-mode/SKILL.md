---
name: execution-mode
description: "Auto-detect task execution mode — QUICK/THOROUGH/DRAFT — based on scope/risk/familiarity. NOT system resource optimization (see development-mode)."
triggers: "Execution mode, quick/thorough/draft, resource adaptive, zone green/yellow/orange/red"
license: Apache-2.0
metadata:
  tags: [engineering, runtime]
  author: gentleman-vMK
  version: "2.2"
  changelog: "2.2: enriched with auto-detect decision table, THOROUGH scenario, escalation example, mode transitions"
---

## Modes
| Mode | When | Depth | Verification |
|------|------|-------|-------------|
| QUICK | Simple bugfix, known | Minimal | Tests only |
| THOROUGH | Complex, risky | Full SDD | Full gate |
| DRAFT | Explore, prototype | Notes | Skip |

## Decision Table (auto-detect when unspecified)

| Scope | Risk | Familiarity | Keywords | Mode |
|-------|------|-------------|----------|------|
| 1 file | Typo | Known (3x+) | "fix", "typo" | QUICK |
| 1-2 files | Minor bug | Known | "bug", "error" | QUICK |
| 1-3 files | Config change | Known | "update", "bump" | QUICK |
| 3-5 files | Logic change | Some | "refactor", "change" | QUICK → THOROUGH |
| 5+ files | Data loss | Known | "migrate" | THOROUGH |
| 5+ files | Security | Any | "auth", "permissions" | THOROUGH |
| Multi-package | API change | New | "redesign", "rearchitect" | THOROUGH |
| Unknown | Unknown | New | "explore", "prototype", "idea" | DRAFT |
| Any | Any | Any | "research", "investigate" | DRAFT |
| Single file | High (data loss) | Known | "delete", "drop", "rm" | THOROUGH (override) |

Escalate: if auto-detect says QUICK but user says "careful" or "validate" → THOROUGH. User override wins.

## Auto-detect (when unspecified)
Scope (1-file vs multi), risk (typo vs data loss), familiarity (3x+ vs new), keywords ("fix" vs "redesign" vs "explore").

## Auto-detect example
User: "fix the nil pointer in user.go"

Detection:
- Scope: 1 file → QUICK
- Risk: nil pointer (panic at runtime) → HIGH → override to THOROUGH
- Keyword: "fix" → QUICK
- Verdict: THOROUGH (risk override)

Flow: `THOROUGH → full SDD: propose → spec → design → tasks → apply → verify`. Output includes RCA, test for nil path, and engram save.

## Context Zones (via context-watchdog)
GREEN <40%: Full depth | YELLOW 40-60%: L1+L2 compression | ORANGE 60-80%: L2+L3, compact@70% | RED >80%: mem_save + break session

**Rules**: Re-evaluate every 5 tools. Escalate on any HIGH. De-escalate after 3 lower. User override wins.

## Zone escalation example
```
Tool #5: Context at 42% → YELLOW → L1+L2 compression → continue
Tool #10: Context at 63% → ORANGE → L2+L3 compact(70%) → warn user
Tool #12: Context at 82% → RED → mem_save("execution-checkpoint") → break session
```
De-escalation: after 3 consecutive tools in YELLOW with no new HIGH → drop to GREEN.

## Mode Rules
| Mode | Pipeline | Output |
|------|----------|--------|
| QUICK | sdd-quick (3-phase: Propose→Apply→Verify) | Code + tests. Score+move. |
| THOROUGH | Full SDD (9-phase) | Every decision→Engram. Quality gate. PR with evidence. |
| DRAFT | Explore first | Notes. No commit without user OK. |

### THOROUGH mode scenario (full SDD)
```
1. SDD Init → context + registry
2. SDD Propose → "Why this change, what scope, approach"
3. SDD Spec → requirements + scenarios
4. SDD Design → architecture approach
5. SDD Tasks → break into implementation units
6. SDD Apply → implement per task with commits
7. SDD Verify → tests pass, spec covered
8. Quality Gate → secrets + commit format + lint
9. SDD Archive → persist to engram
Every step → mem_save with checkpoint
```

## Mode Rules
QUICK: sdd-quick (3-phase fast path: Propose→Apply→Verify). Code+tests. Score+move.
THOROUGH: Full SDD. Every decision→Engram. Quality gate. PR with evidence.
DRAFT: Explore first. No commit without user OK.

## Refs
development-mode · context-watchdog · lean-context · quality-gate · sdd · sdd-quick · sdd-init

## Anti-Patterns
DRAFT when user asked for THOROUGH · Skip zone re-evaluation · Ignore RED zone compression · Stay in one mode for entire session · Auto-detect without explaining override · THOROUGH for single-line typo · DRAFT for destructive operations
