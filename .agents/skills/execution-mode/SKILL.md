---
name: execution-mode
description: "Auto-detect task execution mode - QUICK/THOROUGH/DRAFT - from scope/risk/familiarity. Not resource optimization."
triggers: "Execution mode, quick/thorough/draft, resource adaptive, zone green/yellow/orange/red"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Auto-detect task execution mode — QUICK/THOROUGH/DRAFT — based on scope, risk, and familiarity. Not resource optimization.

## Modes
| Mode | When | Depth | Verification |
|------|------|-------|-------------|
| QUICK | Simple bugfix, known | Minimal | Tests only |
| THOROUGH | Complex, risky | Full SDD | Full gate |
| DRAFT | Explore, prototype | Notes | Skip |

## Decision Table (auto-detect when unspecified)
| Scope | Risk | Familiarity | Keywords | Mode |
|-------|------|-------------|----------|------|
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
| User says "careful"/"validate" while QUICK→escalate to THOROUGH. User override wins.

## Context Zones (via context-watchdog)
GREEN <40%: Full depth | YELLOW 40-60%: L1+L2 compression | ORANGE 60-80%: L2+L3, compact@70% | RED >80%: mem_save+break session
Re-evaluate every 5 tools. Escalate on any HIGH. De-escalate after 3 lower. User override wins.

## Mode Pipeline
| Mode | Pipeline | Output |
|------|----------|--------|
| QUICK | sdd-quick (3-phase: Propose→Apply→Verify) | Code+tests. Score+move. |
| THOROUGH | Full SDD (9-phase) | Every decision→Engram. Quality gate. PR with evidence. |
| DRAFT | Explore first | Notes. No commit without user OK. |

### THOROUGH (full SDD)
1. SDD Init→context+registry | 2. Propose→why/scope/approach | 3. Spec→requirements+scenarios | 4. Design→architecture | 5. Tasks→implementation units | 6. Apply→implement per task | 7. Verify→tests pass, spec covered | 8. Quality Gate→secrets+commit+lint | 9. Archive→persist to engram
Every step→mem_save with checkpoint.

## Examples
1. **QUICK**: Fix typo in button label — "typo in submit button" → 1 file, known codebase → sdd-quick, tests pass, done.
2. **QUICK**: Update config version — "bump version to 2.1.0" → 1-2 files, known pattern → sdd-quick, verify build.
3. **THOROUGH**: Migrate auth from sessions to JWT — "migrate to JWT" → 5+ files, data loss risk, security → full SDD 9-phase, Engram checkpoints, quality gate.
4. **THOROUGH**: Redesign API contracts across packages — "redesign API" → multi-package, API change, new domain → full SDD, spec first, cross-package impact.
5. **DRAFT**: Explore new state management approach — "prototype Zustand vs Redux" → unknown scope, research keyword → notes only, no commit, user decides.

## Testing Patterns
1. **Mode Detection Test**: Given task description, assert detected mode matches decision table — cover all 11 rows.
2. **Override Test**: User says "careful" on QUICK task → assert escalation to THOROUGH; user says "quick" on THOROUGH → assert de-escalation to QUICK.
3. **Zone Re-evaluation Test**: Simulate context at 45% → assert YELLOW compression applied; at 75% → assert ORANGE + mem_save triggered.

## Edge Cases
1. **Single file, high risk**: "delete production database" → 1 file but data loss risk → THOROUGH override (row 11 in decision table).
2. **Mixed familiarity**: Known codebase, new domain (e.g., known React app, new WebRTC feature) → scope 3-5 files, some familiarity → QUICK→THOROUGH boundary, clarify with user.
3. **Context zone shift mid-task**: Started QUICK in GREEN, context hits ORANGE → re-evaluate, apply L2+L3 compression, continue or compact.
4. **User contradicts auto-detect**: Auto says THOROUGH, user says "just do it quick" → honor override, log decision, mem_save rationale.

## Anti-Patterns
DRAFT when user asked THOROUGH · Skip zone re-evaluation · Ignore RED zone · Stay in one mode for entire session · Auto-detect without explaining override · THOROUGH for single-line typo · DRAFT for destructive operations · Escalate to THOROUGH for every minor change "just in case" · De-escalate from THOROUGH to QUICK to skip quality gate

## Refs
development-mode · context-watchdog · lean-context · quality-gate · sdd · sdd-quick · sdd-init