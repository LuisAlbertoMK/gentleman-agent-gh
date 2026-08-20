---
name: session-resume
description: "Session continuity — save/restore state, git gate, sparse skill pre-load, Engram recall"
triggers: "session resume, dónde lo dejamos, continuá, session start, code memory, memory, recordar, acordate, multi-session, donde quedamos, handoff"
changelog: docs/ciclos/cycle28-20260815.md
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
> docs/skills/session-resume/reference.md