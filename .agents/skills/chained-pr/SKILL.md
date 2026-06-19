---
name: chained-pr
description: "Manage stacked sequential PRs — split >400 lines, declare deps, rebase-chain handled"
triggers: "Stacked/Chained/Sequential PRs, stacked branches"
license: Apache-2.0
metadata:
  tags: [engineering, git]
  author: gentleman-vMK
  version: "2.2"
  changelog: "2.2: karpathy compress"
---
## When: PR>400L · SDD `400-line budget risk: High` · stacked PRs requested
## Hard Rules
- Split PRs>400L unless maintainer accepts `size:exception`
- Each ≤60 min review · each passes quality gate independently
- NEVER merge PR#N before PR#N-1 · max chain: 5
- Conflict → fix earliest, cascade rebase
- Each child PR needs **dependency diagram** with `📍` marking current
## Decision Gates
| Condition | Action |
|---|---|
| ≤400L focused | Single PR |
| >400L, independent slices | **Stacked PRs to main** |
| >400L, must integrate before main | **Feature Branch Chain** |
| Generated/vendor unsplittable | Ask maintainer `size:exception` |
| SDD has `delivery_strategy` | Follow it |
## Workflow: Estimate→split→branch `feat/{prefix}-{n}-{slug}`→`gh pr create --base {parent}`→`Depends on: #N`→verify→merge in order
### Stacked: `main←PR#1←PR#2←PR#3` — rebase/retarget after each parent merge
### Feature Branch Chain: tracker draft → children → merge children → merge tracker
## Rebase Cascade: `git checkout feat/{n+1}` → `git rebase main` → `git push --force-with-lease`
## Rollback: Single→`git revert` · Chain→revert end to start (last merged first)
## Output: strategy · PR order/deps · boundaries · dep diagram · review budget · any `size:exception` rationale
## Chain Context (in PR body)
```
Chain: <name> · Pos: <N/M> · Base: `<branch>` · Dep: #N · Next: #N
main └── #N Prev └── 📍 #N This └── #N Next
- [x] CI · [x] One deliverable · [x] Rollback-safe · [x] Tests/docs
```
## Deps: work-unit-commits · command-wrapper
