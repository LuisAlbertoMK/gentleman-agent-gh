---
name: work-unit-commits
description: "Plan commits as reviewable work units."
triggers: "work unit, commit splitting, commit organization, reviewable commits, split commit, stacked PR, chained PR commits"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Splitting feature into reviewable work units · preparing commits before PR · large change into chained/stacked PRs · healthy reviewer cognitive load · SDD tasks without exceeding 400 lines.

## Rules
| Rule | Req |
|---|---|
| Commit by work unit | A commit = deliverable behavior/fix/migration/docs |
| NOT by file type | Avoid `models`→`services`→`tests` if none works alone |
| Tests with code | Same commit as behavior they verify |
| Docs with change | Same commit as feature/workflow they explain |
| Tell a story | Reviewer understands why each commit exists from diff+message |
| Future PR-ready | Each commit = candidate chained PR slice |
| SDD guard | >400-line forecast → chain before implementing |

## Checklist (pre-commit)
- [ ] One clear purpose
- [ ] Repo works after this commit alone
- [ ] Tests/docs included when relevant
- [ ] Rollback without reverting unrelated work
- [ ] Message explains outcome, not file list

## Split Examples
| Weak | Better |
|---|---|
| `add models` | `feat(auth): add token validation model + tests` |
| `add services` | `feat(auth): wire token validation into login flow` |
| `add tests` | Included with each behavior commit |
| `update docs` | Included with the user-facing change |

## Chained PRs from Work Units
1. Build smallest independent unit → include verification → commit conventional. 2. If PR→400 lines → promote commits into chained PRs.

## SDD Relationship
From `sdd-tasks` Review Workload Forecast: **Low**→one PR | **Medium**→commit by unit, monitor lines | **High**→follow `delivery_strategy` (ask on `ask-on-risk`, auto-slice on `auto-chain`, require `size:exception` on `single-pr`, record accepted on `exception-ok`).
Each work unit maps to commit/PR: clear start → clear finish → verification in same unit → rollback without removing unrelated work.

## Commands
```bash
git diff --stat
git diff --cached --stat
git log --oneline -5
```

## Refs
commit-crafter · chained-pr · branch-pr · sdd · quality-gate

## Anti-Patterns
Commit by file type · Separate tests from code · >400 lines without chaining · Messages that list files · No SDD forecast check

## Examples
"split commit" → `git diff --stat` (6 files, 340 lines <400 → no chain) → `git add src/auth/token-validation.ts tests/auth/token-validation.test.ts` → `git commit -m "feat(auth): add token validation model + tests"` → 1. token validation model+tests ✓ 2. wire into login flow ✓ 3. document login flow ✓ — each = candidate chained PR slice.

## Testing
1. Unit size guard: `git diff --stat HEAD~1..HEAD` ≤400 lines. 2. Tests with code: `git show --stat HEAD` → test file in same commit. 3. Message tells outcome: `git log --oneline -5` → outcome-style, not file-type lists.