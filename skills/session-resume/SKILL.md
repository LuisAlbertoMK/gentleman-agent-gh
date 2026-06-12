---
name: session-resume
description: Safe session resume — git state gate (uncommitted + unpushed) BEFORE "continuá".
license: Apache-2.0
metadata: version: "1.3"
triggers: "dónde lo dejamos", "continuá", session start in git repo
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
4. Check project fingerprint exists: `mem_search(topic_key="project/{name}")`
5. If missing → trigger Project fingerprint mode (dreaming skill)

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

## Resources
Engram: `mem_context` · quality-gate · recovery-protocol (frustration, not resume)
