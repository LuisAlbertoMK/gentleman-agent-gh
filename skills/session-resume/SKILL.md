---
name: session-resume
description: >
  Safe session resume: gate non-blocking that checks git state (uncommitted + unpushed)
  BEFORE continuing any "where did we leave off" / "continuá" request.
  Triggers: "dónde lo dejamos", "continuá", "qué hicimos", "where did we leave off",
  "en que nos quedamos", session start in git repo.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.1"
---

## When
Resume prior work OR session start in git repo. NOT for frustration → `recovery-protocol`.

## Critical Patterns
1. **Non-blocking gate** — INFORM, ASK, never auto-commit silently
2. **Two states**: uncommitted (dirty) + unpushed (ahead of remote)
3. **Skip git if not a repo** → Engram-only recovery
4. **Skip output if clean** → silent Engram restore
5. **One question, max 4 options** — commit/push/stash/continue
6. **Terse output** — numbers+paths, not narrative

## Detection (parallel, <100ms each)
```bash
git status --porcelain                    # dirty if non-empty
git log @{u}.. --oneline 2>/dev/null      # unpushed if non-empty
git branch --show-current
git log -1 --oneline
```

## Decision Tree
```
is git repo? NO → skip → mem_context
YES → dirty? WARN+ask: commit/stash/continue
     → unpushed? WARN+ask: push/keep/continue
     → both clean → silent → mem_context
```

## Output (when dirty)
```
**Git state**: ⚠️ dirty
- Branch: {branch}
- Uncommitted: {N} files
  - {path1}, {path2}, … +X more (max 5)
- Unpushed: {M} commits
  - {short-sha} {msg}
**Action**: commit now / push first / stash / continue without
```

Actions: commit → `git add -A` + conv msg · push → `git push` (quality-gate first) · stash → `git stash push -m "auto-stash session-resume"` · continue → Engram recovery.

## Side-State Hooks
- `.refactor/steps.json` exists → ask: continue from incomplete OR restart
- `.metricas/bookmark.json` exists → report label+ts, ask: compare or discard

## After Check (always)
`mem_context` to restore session summary. **THIS is the actual resume** — git check is just the safety gate.

## Anti-Patterns
- ❌ Auto-commit/push without asking
- ❌ Run mid-task (only on resume/start)
- ❌ Output > 10 lines
- ❌ Skip check because "small project"

## Resources
- **Engram**: `mem_context` (actual resume)
- **Quality gate**: required before commit/push
- **Recovery protocol**: for frustration (different intent)
