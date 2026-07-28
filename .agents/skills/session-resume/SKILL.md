---
name: session-resume
description: "Session continuity — save/restore state, git gate, sparse skill pre-load, Engram recall"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "2.2"
  changelog: "2.2: merged code-memory (Save State section + triggers)"
triggers: "session resume, dónde lo dejamos, continuá, session start, code memory, memory, recordar, acordate, multi-session, donde quedamos, handoff"
---
## Gate
1. is git repo? NO → `mem_context` only. YES → check 2 states.
2. Dirty (uncommitted)? WARN+ask: commit/stash/continue.
3. Ahead (unpushed)? WARN+ask: push/keep/continue.
4. Both clean → silent, `mem_context` only.
5. One question, max 4 options. Terse (numbers+paths).

## Proactive Recall
1. `mem_search(query="<last session>", limit=5)` — past work
2. If user msg has keywords → `mem_search(query="<keywords>", type="bugfix|pattern|decision", limit=3)` → inject top 3 as context
3. Present relevant decisions/bugfixes
4. `mem_search(query="project/{name}", scope=project, limit=1)`
5. If missing → trigger Project fingerprint (dreaming)

**Pre-answer search**: See `engram-protocol` skill for proactive search protocol. See also `gentleman-vMK.md` for the Pre-Answer Evidence Gate (hard gate).

## Skill Pre-load
```powershell
.\scripts\skill-graph.ps1 -Task "<session keywords>" -Format Text
```
Typical: 55→4-8 (−85-92%)

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
- **Current task**: what, why, where (files), status
- **Next step**: exact action (file:line, what)
- **Context**: decisions, rejected approaches, preferences
- **Open questions**: unresolved items
- **Files touched**: paths + changes + pending

### State format
JSON: `{session_id, task:{description,status,blockers}, next_step:{file,action}, ctx:{decisions:[],preferences:[],rejected:[]}, files:[{path,status,summary}], todos:[{id,desc,status}]}`

### Workflow
Start→load handoff|create. During→detect→update. End→save+handoff+next step.

### Auto-save triggers
file created/deleted · >20 line change · discovery · important question · decision

## Cross-Project Wisdom
1. Check `docs/cross-project/patterns/` exists
2. If yes → quick scan: load patterns matching session keywords via `cross-project-wisdom` skill
3. Present max 3 HIGH/CRITICAL patterns as advisory context
4. `ponytail:` lite — only runs if `ponytail` mode is lite/full/ultra (not off)

## Post-Check
`mem_context` = resume. Git is safety gate.

## Anti-Patterns
Auto-commit/push · mid-task runs · output >10 lines · skip "small project" · skip skill-graph

## Resources
Engram `mem_context` · quality-gate · recovery-protocol · skill-graph.ps1

## Refs
dreaming · skill-graph · recovery-protocol · context-watchdog · quality-gate
