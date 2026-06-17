---
name: chained-pr
description: "Manage stacked sequential PRs — split >400 lines, declare deps, rebase-chain handled"
triggers: "Stacked/Chained/Sequential PRs, stacked branches"
license: Apache-2.0
metadata:
  tags: [engineering, git]
  author: gentleman-vMK
  version: "2.1"
---

## When
PR >400 lines · SDD `400-line budget risk: High` · user asks for stacked PRs · multi-commit sequential deliverables

## Hard Rules
- **Split PRs over 400 lines** unless maintainer accepts `size:exception`
- **Each PR reviewable in ≤60 min** · each passes quality gate independently
- **NEVER merge PR#N before PR#N-1** · max chain: **5**
- Conflict → fix in earliest PR, cascade rebase
- Every child PR needs **dependency diagram** with `📍` marking current PR
- No mixing strategies · polluted diff = base bug (retarget/rebase)

## Decision Gates
| Condition | Action |
|---|---|
| PR ≤400 lines focused | Single PR |
| >400, slices can land independently | **Stacked PRs to main** |
| >400, feature must integrate before main | **Feature Branch Chain** with tracker |
| Generated/vendor diff unsplittable | Ask maintainer for `size:exception` |
| SDD has `delivery_strategy` | Follow it |

## Workflow
Estimate → split → branch `feat/{prefix}-{n}-{slug}` targeting predecessor → `gh pr create --base {parent}` → declare `Depends on: #N` + Chain Context → verify each PR → merge in order → rebase cascade

### Stacked PRs to Main
```
main ← PR 1: foundation
         └── PR 2: built on PR 1
               └── PR 3: built on PR 2
```
After parent merges, rebase/retarget next PR.

### Feature Branch Chain
```
main └── feat/my-feature (tracker, draft/no-merge)
        ↑ PR#1 base: feat/my-feature
        └── feat/my-feature-01-core
             ↑ PR#2 base: feat/my-feature-01-core
             └── feat/my-feature-02-shared
```
Create tracker branch → open draft PR → create children targeting parent → merge children in order → merge tracker last.

## Rebase Cascade
```bash
git checkout feat/{prefix}-{n+1}-{slug}
git rebase main
git push --force-with-lease
```

## Rollback
- Single PR: `git revert <merge-commit>`
- Chain: revert from end to start (last merged first)

## Output Contract
Return: chosen strategy · PR order/deps · boundaries · dependency diagram · review budget (+/-) · verification plan · any `size:exception` rationale

## Chain Context (append to PR body)
```markdown
## Chain Context
| Field | Value | | Field | Value |
|-------|-------|-------|-------|
| Chain | <name> | Tracker PR | <#NNN or "none"> |
| Position | <N/M> | Base | `<branch>` |
| Depends on | <#N or none> | Follow-up | <#N or none> |
| Budget | <lines>/400 | | |

### Overview
main └── #N Prev └── 📍 #N This └── #N Next

### Scope
- Includes: <unit> · Excludes: <deferred>
- [x] CI passes · [x] One deliverable · [x] Rollback-safe · [x] Tests/docs
```

## Deps
- work-unit-commits · command-wrapper

## Refs
- [references/chaining-details.md](references/chaining-details.md)
