---
name: chained-pr
description: "Manage stacked sequential PRs — one per work unit, dependency declared, rebase-chain handled"
triggers: "Stacked PRs, chained PR, sequential PR, stacked branches"
license: Apache-2.0
metadata:
  tags:
    - engineering
    - git
  author: gentleman-vMK
  version: "1.0"
---

Trigger: Multi-commit features, stacked PR workflow, sequential deliverables.

## CHAIN STRUCTURE
```
main ── PR#1 (feat/a-auth) ── PR#2 (feat/a-service) ── PR#3 (feat/a-ui)
```
Each PR depends on previous. Merge order: 1→2→3.

## WORKFLOW
1. **Split** — from delivery-harness work units, map each to one branch
2. **Branch** — `feat/{prefix}-{n}-{slug}` naming
3. **Build chain** — each branch targets its predecessor (not main)
4. **Commit** — per work-unit-commits rules (one deliverable, tests/docs included)
5. **Open PRs** — `gh pr create --base {parent-branch} --title "..." --body "..."`
6. **Declare deps** — in PR body: `Depends on: #N` for clear chain visibility

## RULES
- Each PR MUST pass quality gate independently
- NEVER merge PR#N before PR#N-1 is merged
- After merge of PR#N → rebase PR#N+1 onto updated main
- Max chain length: 5 (beyond that → collapse into fewer PRs)
- If chain breaks (conflict) → fix in earliest PR, cascade rebase

## REBASE CASCADE
When PR#N merges:
```bash
git checkout feat/{prefix}-{n+1}-{slug}
git rebase main
# resolve conflicts in earliest PR only
git push --force-with-lease
```

## ROLLBACK
Single `git revert <merge-commit>` on the merged PR. If chain is partially merged, revert from end to start.

## DEPENDENCIES
- work-unit-commits (commit discipline per unit)
- command-wrapper (safe git commands)
