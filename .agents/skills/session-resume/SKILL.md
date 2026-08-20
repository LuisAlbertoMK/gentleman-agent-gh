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

## Proactive Recall
1. `mem_search(query="<last session>", limit=5)` — past work
2. User msg keywords → `mem_search(query="<keywords>", type="bugfix|pattern|decision", limit=3)` → inject top 3
3. Present relevant decisions/bugfixes
4. `mem_search(query="project/{name}", scope=project, limit=1)`
5. Missing → trigger Project fingerprint (dreaming)

**Pre-answer search**: `engram-protocol` for proactive search; `gentleman-vMK.md` = Pre-Answer Evidence Gate.

## Skill Pre-load
```powershell
.\scripts\skill-graph.ps1 -Task "<session keywords>" -Format Text
```
Typical: 55→4-8 (−85-92%).

## Commands
`git status --porcelain` · `git log @{u}.. --oneline 2>/dev/null` · `git branch --show-current; git log -1 --oneline`

## Output (dirty)
```
{branch}: {N} uncommitted ({paths}) + {M} unpushed ({sha} {msg})
Action: commit/push/stash/continue?
```
commit→`git add -A`+msg · push→`git push` (quality-gate) · stash→`git stash push -m "auto-stash"` · continue→Engram.

## Save State
### Handoff
Current task (what/why/where/status) · Next step (file:line, what) · Context (decisions, rejected, preferences) · Open questions · Files touched (paths + changes + pending).

### State format
JSON: `{session_id, task:{description,status,blockers}, next_step:{file,action}, ctx:{decisions:[],preferences:[],rejected:[]}, files:[{path,status,summary}], todos:[{id,desc,status}]}`

### Workflow
Start→load handoff|create. During→detect→update. End→save+handoff+next step.

### Auto-save triggers
file created/deleted · >20 line change · discovery · important question · decision

## Cross-Project Wisdom
1. Check `docs/cross-project/patterns/` exists. 2. Load matching patterns via `cross-project-wisdom`. 3. Present max 3 HIGH/CRITICAL advisory patterns.

## Examples
"dónde lo dejamos?" → `git status --porcelain` clean → no WARN; `git log @{u}..` empty → nothing unpushed; `mem_search("last session")` → top 3 injected → silent resume, 0 questions.

## Testing
1. Dirty drill: 1 touched file → WARN + ask (commit/stash/continue), max 4 options. 2. Clean drill: empty status → silent, 0 questions. 3. Pre-load: `skill-graph.ps1` → ≤8 lines.

## Anti-Patterns
Auto-commit/push · mid-task runs · output >10 lines · skip "small project" · skip skill-graph

## Refs
dreaming · skill-graph · recovery-protocol · context-watchdog · quality-gate