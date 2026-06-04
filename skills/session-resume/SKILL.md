---
name: session-resume
description: >
  Safe session resume: gate non-blocking that checks git state (uncommitted + unpushed)
  BEFORE continuing any "where did we leave off" / "continuá" request.
  Triggers: "dónde lo dejamos", "continuá", "qué hicimos", "where did we leave off",
  "en que nos quedamos", session start in git repo.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## When
User asks to resume prior work OR session starts in a git repo.
NOT for: frustration cases (use `recovery-protocol`).

## Critical Patterns
1. **Non-blocking gate** — INFORM first, ASK, never auto-commit silently
2. **Two states to check** — uncommitted (working tree dirty) + unpushed (ahead of remote)
3. **Skip git check if not a repo** — degrade to Engram-only recovery
4. **Skip output if clean** — proceed silently to Engram context restore
5. **One question, max 4 options** — commit / push / stash / continue
6. **Terse output** — numbers + paths, not narrative

## Detection Commands (cross-platform)
```bash
# Working tree state (empty = clean)
git status --porcelain

# Unpushed commits (empty = in sync with upstream)
git log @{u}.. --oneline 2>/dev/null

# Current branch (empty = detached HEAD)
git branch --show-current

# Last commit (always works, even detached)
git log -1 --oneline
```

Run all 4 in parallel. Each is cheap (< 100ms).

## Decision Tree
```
is git repo?
├── NO  → skip git, go straight to mem_context
└── YES
    ├── dirty working tree? (git status --porcelain non-empty)
    │   └── WARN uncommitted, ask: commit / stash / continue
    ├── unpushed commits? (git log @{u}.. non-empty)
    │   └── WARN unpushed, ask: push / keep local / continue
    └── both clean
        └── silent, go to mem_context
```

## Output Format (when dirty)
```
**Git state**: ⚠️ dirty
- Branch: {branch}
- Uncommitted: {N} files
  - {path1}
  - {path2}
  - {… max 5, then "+X more"}
- Unpushed: {M} commits
  - {short-sha} {msg}
**Action**: commit now / push first / stash / continue without
```

If user picks **commit**: run `git add -A` + conventional commit message based on diff stat.
If user picks **push**: run `git push` (use quality-gate first).
If user picks **stash**: run `git stash push -m "auto-stash session-resume"`.
If user picks **continue**: proceed to Engram recovery.

## After Check (always)
Call `mem_context` to restore last session summary regardless of git state.
This is the ACTUAL resume — git check is just the safety gate.

## Anti-Patterns
- ❌ Auto-commit without asking (violates user intent)
- ❌ Auto-push (dangerous, needs quality-gate)
- ❌ Run when user is mid-task (only on resume/start)
- ❌ Long narrative — output must fit in < 10 lines
- ❌ Skip the check because "project is small" — no exceptions

## Resources
- **Engram**: `mem_context` for session summary
- **Quality gate**: required before any commit/push
- **Recovery protocol**: `recovery-protocol/SKILL.md` for frustration (different intent)
