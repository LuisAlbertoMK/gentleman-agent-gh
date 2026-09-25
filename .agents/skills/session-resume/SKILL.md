---
name: session-resume
description: "Session continuity — save/restore state, git gate, sparse skill pre-load, Engram recall"
triggers: "session resume, dónde lo dejamos, continuá, session start, code memory, memory, recordar, acordate, multi-session, donde quedamos, handoff"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2400
---
## When to Use
1. Is git repo? NO → `mem_context` only. YES → check 2 states.
2. Dirty (uncommitted)? WARN+ask: commit/stash/continue.
3. Ahead (unpushed)? WARN+ask: push/keep/continue.
4. Both clean → silent, `mem_context` only.
5. One question, max 4 options. Terse (numbers+paths).
## Output (dirty)
```
{branch}: {N} uncommitted ({paths}) + {M} unpushed ({sha} {msg})
Action: commit/push/stash/continue?
```
commit→`git add -A`+msg · push→`git push` (quality-gate) · stash→`git stash push -m "auto-stash"` · continue→Engram.
## Refs
dreaming · skill-graph · recovery-protocol · context-watchdog · quality-gate
## Anti-Patterns
Auto-commit/push · mid-task runs · output >10 lines · skip "small project" · skip skill-graph

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Continue without checking git" | Skipping dirty/ahead states 2-3 | `git status --porcelain=v1 -b` before any work — dirty/ahead must be WARNed |
| "Session is small, no need" | Auto-skip skill-graph/Engram | Even tiny session → `mem_context` (cost ~0, saves hours) |
| "Will remember later" | Not calling mem_save before RED zone | Every 25 calls or YELLOW → `mem_save(topic_key=checkpoint/session-state)` |

## Red Flags
- Unpushed commits silently growing (>5 ahead) → push now or `git branch` diverges — STOP new work until push/stash/continue is chosen (When to Use 2-3)
- Restoring session without `mem_context` → re-discover what you already solved

## Verification
- `git status --porcelain=v1 -b` run before any work — dirty/ahead states drive When-to-Use paths 2–4
- Resume output matches the `## Output (dirty)` contract: `{branch}: {N} uncommitted…`, ≤10 lines, ≤4 options
- Branch/commit info verified via `git rev-parse --abbrev-ref HEAD` + `git log --oneline -3`
- `mem_context` recalled before restore; `mem_save(topic_key=checkpoint/session-state)` every 25 calls or YELLOW zone
> docs/skills/session-resume/reference.md
