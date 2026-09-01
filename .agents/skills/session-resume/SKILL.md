---
name: session-resume
description: "Session continuity — save/restore state, git gate, sparse skill pre-load, Engram recall"
triggers: "session resume, dónde lo dejamos, continuá, session start, code memory, memory, recordar, acordate, multi-session, donde quedamos, handoff"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1600
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
- Unpushed commits silently growing (>5 ahead) → push now or `git branch` diverges
- Restoring session without `mem_context` → re-discover what you already solved

## Verification
- Resume path chosen in ≤4 options, output ≤10 lines, branch/commit info accurate
> docs/skills/session-resume/reference.md
