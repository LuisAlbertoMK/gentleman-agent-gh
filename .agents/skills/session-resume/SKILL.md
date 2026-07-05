---
name: session-resume
description: "Safe session resume — git state gate + sparse skill pre-load + Engram recall"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "2.1"
  changelog: "2.1: karpathy compress"
triggers: "session resume, dónde lo dejamos, continuá, session start"
---
## Gate
1. is git repo? NO → `mem_context` only. YES → check 2 states.
2. Dirty (uncommitted)? WARN+ask: commit/stash/continue.
3. Ahead (unpushed)? WARN+ask: push/keep/continue.
4. Both clean → silent, `mem_context` only.
5. One question, max 4 options. Terse (numbers+paths).
6. Bridge hook (auto): run `.\scripts\check-bridge.ps1` — if hasNew, SHOW entries to user before proceeding.
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
