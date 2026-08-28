---
name: execution-mode
description: "Auto-detect task execution mode - QUICK/THOROUGH/DRAFT - from scope/risk/familiarity. Not resource optimization."
triggers: "Execution mode, quick/thorough/draft, resource adaptive, zone green/yellow/orange/red"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1634
---
## When to Use
Auto-detect task execution mode — QUICK/THOROUGH/DRAFT — from scope, risk, familiarity. Not resource optimization.
## Modes
| Mode | When | Depth | Verification |
|---|---|---|---|
| QUICK | Simple bugfix, known | Minimal | Tests only |
| THOROUGH | Complex, risky | Full SDD | Full gate |
| DRAFT | Explore, prototype | Notes | Skip |
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
## Anti-Patterns
DRAFT when asked THOROUGH · Skip zone re-eval · Ignore RED · One mode all session · Auto-detect without explaining · THOROUGH for single-line typo · DRAFT for destructive ops
> docs/skills/execution-mode/reference.md
## Refs
Cross-Refs: sdd | sdd-apply
