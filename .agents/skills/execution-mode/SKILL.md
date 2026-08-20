---
name: execution-mode
description: "Auto-detect task execution mode - QUICK/THOROUGH/DRAFT - from scope/risk/familiarity. Not resource optimization."
triggers: "Execution mode, quick/thorough/draft, resource adaptive, zone green/yellow/orange/red"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Auto-detect task execution mode — QUICK/THOROUGH/DRAFT — from scope, risk, familiarity. Not resource optimization.

## Modes
| Mode | When | Depth | Verification |
|---|---|---|---|
| QUICK | Simple bugfix, known | Minimal | Tests only |
| THOROUGH | Complex, risky | Full SDD | Full gate |
| DRAFT | Explore, prototype | Notes | Skip |

## Decision Table (auto-detect)
| Scope | Risk | Familiarity | Keywords | Mode |
|---|---|---|---|---|
| 1 file | Typo | Known (3x+) | "fix","typo" | QUICK |
| 1-2 | Minor bug | Known | "bug","error" | QUICK |
| 1-3 | Config change | Known | "update","bump" | QUICK |
| 3-5 | Logic change | Some | "refactor","change" | QUICK→THOROUGH |
| 5+ | Data loss | Known | "migrate" | THOROUGH |
| 5+ | Security | Any | "auth","permissions" | THOROUGH |
| Multi-pkg | API change | New | "redesign","rearchitect" | THOROUGH |
| Unknown | Unknown | New | "explore","prototype","idea" | DRAFT |
| Any | Any | Any | "research","investigate" | DRAFT |
| 1 file | High (data loss) | Known | "delete","drop","rm" | THOROUGH (override) |

User says "careful"/"validate" on QUICK → escalate THOROUGH. User override wins.

## Context Zones (via context-watchdog)
GREEN <40%: full depth | YELLOW 40-60%: L1+L2 | ORANGE 60-80%: L2+L3 compact@70% | RED >80%: mem_save+break. Re-evaluate every 5 tools. Escalate on any HIGH. De-escalate after 3 lower. User override wins.

## Mode Pipeline
| Mode | Pipeline | Output |
|---|---|---|
| QUICK | sdd-quick (Propose→Apply→Verify) | Code+tests. Score+move. |
| THOROUGH | Full SDD 9-phase | Every decision→Engram. Quality gate. PR with evidence. |
| DRAFT | Explore first | Notes. No commit without user OK. |

THOROUGH: Init→Propose→Spec→Design→Tasks→Apply→Verify→Quality Gate→Archive. Every step→mem_save checkpoint.

## Examples
1. "typo in submit button" → 1 file, known → QUICK. 2. "migrate to JWT" → 5+ files, data loss, security → THOROUGH 9-phase. 3. "redesign API" → multi-package, new → THOROUGH, spec first. 4. "prototype Zustand vs Redux" → DRAFT, notes only.

## Testing
1. Mode detection covers all 11 table rows. 2. Override: "careful" on QUICK → THOROUGH; "quick" on THOROUGH → QUICK. 3. Zones: 45%→YELLOW applied; 75%→ORANGE+mem_save.

## Edge Cases
1. "delete production database" → 1 file but data loss → THOROUGH override (row 11). 2. Zone shift mid-task → re-evaluate, apply L2+L3, continue or compact. 3. User contradicts auto-detect → honor override, log, mem_save rationale.

## Anti-Patterns
DRAFT when asked THOROUGH · Skip zone re-eval · Ignore RED · One mode all session · Auto-detect without explaining · THOROUGH for single-line typo · DRAFT for destructive ops