---
name: session-resume
description: Safe session resume — git state gate + sparse skill pre-load + Engram recall.
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.0"
triggers: "dónde lo dejamos, continuá, session start in git repo"
---

## Gate
1. **is git repo?** NO → `mem_context` only. YES → check 2 states.
2. **Dirty** (uncommitted)? WARN+ask: commit/stash/continue.
3. **Ahead** (unpushed)? WARN+ask: push/keep/continue.
4. **Both clean** → silent, `mem_context` only.
5. **One question, max 4 options.** Terse output (numbers+paths).

## Proactive Recall (post-gate, pre-resume)
After git gate passes, BEFORE resuming work:
1. `mem_search(query="<last session keywords>", limit=5)` — find related past work
2. If user message has keywords → search for matching observations
3. Present relevant past decisions/bugfixes as context snapshot
4. Check project fingerprint exists: `mem_search(query="project/{name}", scope=project, limit=1)`
5. If missing → trigger Project fingerprint mode (dreaming skill)

## Skill Pre-load (incremental context)
After recall, resolve which skills are relevant to the resumed task:

```powershell
.\scripts\skill-graph.ps1 -Task "<session keywords from mem_context>" -Format Json
```

Use the output to pre-load only the resolved skills via `skill_use`. This avoids loading all 55 skills when only 3-5 are needed. Typical reduction: 55 → 4-8 (−85-92%).

Example flow:
```
mem_context → finds "working on auth refactoring"
→ skill-graph.ps1 -Task "auth refactoring" → [sdd-tasks, code-review-agent, refactoring-planner]
→ skill_use @("sdd-tasks","refactoring-planner","code-review-agent")
```

## Commands
```bash
git status --porcelain                    # dirty if non-empty
git log @{u}.. --oneline 2>/dev/null      # unpushed if non-empty
git branch --show-current; git log -1 --oneline
```

## Output (dirty only)
```
⚠️ {branch}: {N} uncommitted ({paths}) + {M} unpushed ({sha} {msg})
Action: commit/push/stash/continue?
```
Actions: commit→`git add -A`+msg · push→`git push` (quality-gate) · stash→`git stash push -m "auto-stash session-resume"` · continue→Engram.

## Post-Check
`mem_context` = actual resume. Git check is just the safety gate.

## Anti-Patterns
❌ Auto-commit/push · mid-task runs · output >10 lines · skip because "small project"
❌ Load all skills at resume — use skill-graph for sparse pre-load

## Resources
Engram: `mem_context` · quality-gate · recovery-protocol (frustration, not resume)
Skill graph: `scripts/skill-graph.ps1` · `.agents/skills/skill-graph/SKILL.md`
