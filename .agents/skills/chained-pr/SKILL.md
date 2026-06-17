---
name: chained-pr
description: "Manage stacked sequential PRs — split oversized changes, declare dependencies, rebase-chain handled"
triggers: "Stacked PRs, chained PR, sequential PR, stacked branches"
license: Apache-2.0
metadata:
  tags:
    - engineering
    - git
  author: gentleman-vMK
  version: "2.0"
---

## Activation Contract

Load this skill when:
- A planned PR may exceed **400 changed lines**
- SDD forecasts `400-line budget risk: High` or `Chained PRs recommended: Yes`
- The user asks for chained/stacked PRs, review slices, or reviewer-load control
- Multi-commit features need sequential deliverable PRs

## Hard Rules

- **Split PRs over 400 changed lines** unless a maintainer explicitly accepts `size:exception`.
- **Keep each PR reviewable in ~60 minutes max.**
- **Each PR MUST pass quality gate independently.**
- **NEVER merge PR#N before PR#N-1 is merged** (in a chain).
- **Max chain length: 5** — beyond that, collapse into fewer PRs.
- If chain breaks (conflict) → fix in earliest PR, cascade rebase.
- State start, end, prior dependencies, follow-up work, and out-of-scope items in every chained PR.
- Every child PR must include a **dependency diagram** marking the current PR with `📍`.
- Do not mix chain strategies after the user chooses one.
- Treat polluted diffs as base bugs: retarget or rebase until only the current work unit appears.

## Decision Gates

| Condition | Action |
|---|---|
| PR ≤400 changed lines and focused | Keep single PR. |
| PR >400, each slice can land independently | **Stacked PRs to main** |
| PR >400, feature must integrate before main | **Feature Branch Chain** with tracker |
| Generated/vendor/migration diff cannot split cleanly | Ask maintainer for `size:exception` |
| SDD provides `delivery_strategy` | Follow it before apply/PR creation |

## Chain Structure

```
main ── PR#1 (feat/a-auth) ── PR#2 (feat/a-service) ── PR#3 (feat/a-ui)
```

Each PR depends on previous. Merge order: 1 → 2 → 3.

## Workflow

1. **Estimate** — review changed lines; identify independent work units.
2. **Ask** — if >400 lines and no cached strategy, ask user for chain strategy.
3. **Split** — from delivery-harness work units, map each to one branch.
4. **Branch** — `feat/{prefix}-{n}-{slug}` naming convention.
5. **Build chain** — each branch targets its predecessor (not main).
6. **Commit** — per work-unit-commits rules (one deliverable, tests/docs included).
7. **Open PRs** — `gh pr create --base {parent-branch} --title "..." --body "..."`
8. **Declare deps** — in PR body: `Depends on: #N` + Chain Context section.
9. **Verify** — each PR independently: CI/tests/docs/manual checks, rollback scope, clean diff.
10. **Merge in order** — never skip; after merge, rebase next PR onto updated main.

## Strategy Details

### Stacked PRs to Main

Use when each slice can land on `main` in order.

```
main ← PR 1: foundation
         └── PR 2: feature slice built on PR 1
               └── PR 3: docs/tests built on PR 2
```

After a parent PR merges, rebase/retarget the next PR so GitHub shows only the current slice.

### Feature Branch Chain

Use when the feature branch accumulates the final integration while child PRs are reviewed as focused slices.

```
main
 └── feat/my-feature              ← tracker/final integration branch
      ↑ PR #1 base: feat/my-feature
      └── feat/my-feature-01-core
           ↑ PR #2 base: feat/my-feature-01-core
           └── feat/my-feature-02-shared
```

Steps:
1. Create the feature/tracker branch from `main`.
2. Open the tracker PR to `main`; mark it draft/no-merge.
3. Create PR #1 from a child branch and target it to the tracker branch.
4. Create each later child branch from the previous PR branch and target to parent.
5. Merge/integrate children in order; merge the tracker only after chain is complete.

## Rebase Cascade

When PR#N merges:

```bash
git checkout feat/{prefix}-{n+1}-{slug}
git rebase main
# resolve conflicts in earliest PR only
git push --force-with-lease
```

## Rollback

- Single PR: `git revert <merge-commit>` on the merged PR.
- Partially merged chain: revert from end to start (last merged first).

## Output Contract

After execution, return:
- Chosen strategy
- PR order / dependency chain
- Current PR boundaries
- Dependency diagram (text)
- Review budget (additions + deletions)
- Verification plan
- Any `size:exception` rationale

## Chain Context Section

Append to PR body (do not replace repo PR template):

```markdown
## Chain Context

| Field | Value |
|-------|-------|
| Chain | <feature or stack name> |
| Tracker PR | <#NNN or "Not needed"> |
| Position | <N of total> |
| Base | `<target branch>` |
| Depends on | <PR/issue/link or "None"> |
| Follow-up | <next PR or "None"> |
| Review budget | <changed lines> / 400 |
| Starts at | <branch, PR, or state this builds on> |
| Ends with | <standalone result delivered by this PR> |

### Chain Overview

```text
main
 └── #NNN Previous PR
      └── 📍 #NNN This PR
           └── #NNN Next PR
```

### Scope
- Includes: <focused unit>
- Excludes: <deferred work>

### Autonomy
- [ ] CI is expected to pass for this PR branch
- [ ] This PR has one deliverable scope
- [ ] This PR can be rolled back without unrelated changes
- [ ] Tests, docs, or manual verification cover this unit
```

## Dependencies

- work-unit-commits (commit discipline per unit)
- command-wrapper (safe git commands)

## References

- [references/chaining-details.md](references/chaining-details.md) — strategy diagrams, branch commands, reviewer guidance.
