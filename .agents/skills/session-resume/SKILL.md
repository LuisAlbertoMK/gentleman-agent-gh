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

## Proactive Recall (post-gate)
1. `mem_search(query="<last session>", limit=5)` — past work context
2. If user msg has keywords → search matching observations
3. Present relevant decisions/bugfixes
4. Check project fingerprint: `mem_search(query="project/{name}", scope=project, limit=1)`
5. If missing → trigger Project fingerprint (dreaming skill)
## Skill Pre-load (mandatory)
```powershell
.\scripts\skill-graph.ps1 -Task "<session keywords>" -Format Text
# Then skill_use with resolved names
```
Typical reduction: 55→4-8 (−85-92%)
## Commands
`git status --porcelain` · `git log @{u}.. --oneline 2>/dev/null` · `git branch --show-current; git log -1 --oneline`
## Output (dirty)
```
{branch}: {N} uncommitted ({paths}) + {M} unpushed ({sha} {msg})
Action: commit/push/stash/continue?
```
Actions: commit→`git add -A`+msg · push→`git push` (quality-gate) · stash→`git stash push -m "auto-stash"` · continue→Engram.
## Post-Check: `mem_context` = actual resume. Git is safety gate.
## Anti-Patterns: Auto-commit/push · mid-task runs · output >10 lines · skip "small project" · skip skill-graph pre-load
## Resources: Engram `mem_context` · quality-gate · recovery-protocol · skill-graph.ps1

## Save State
Saves exact state before session end for seamless resumption.

### Handoff captures
- **Current task**: what, why, where (files), status (blocked/ready/done)
- **Next step**: exact next action (file:line, what to do)
- **Context**: decisions made, rejected approaches, user preferences
- **Open questions**: unresolved items for next session
- **Files touched**: paths + what changed + pending changes

### State format
```json
{session_id, last_update, task:{description,status,blockers}, next_step:{file,action}, ctx:{decisions:[],preferences:[],rejected:[]}, files:[{path,status,summary}], todos:[{id,desc,status}]}
```

### WORKFLOW
- **Start**: find agent-state → load + show handoff | new → create
- **During**: detect changes → update state
- **End**: save full state → handoff summary → next step
- **Session resumption**: present handoff automatically before work

### AUTO-SAVE TRIGGERS
file created/deleted · >20 line change · discovery · important question · decision made
