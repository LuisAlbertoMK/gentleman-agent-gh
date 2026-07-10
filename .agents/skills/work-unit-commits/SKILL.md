---
name: work-unit-commits
description: "Plan commits as reviewable work units."
triggers: "work unit, commit splitting, commit organization, reviewable commits, split commit, stacked PR, chained PR commits"
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When
- Splitting feature into reviewable work units
- Preparing commits before PR
- Turning large change into chained/stacked PRs
- Keeping reviewer cognitive load healthy
- Applying SDD tasks without exceeding 400 lines

## Rules
| Rule | Req |
|------|-----|
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
|------|--------|
| `add models` | `feat(auth): add token validation model + tests` |
| `add services` | `feat(auth): wire token validation into login flow` |
| `add tests` | Included with each behavior commit |
| `update docs` | Included with the user-facing change |

## Chained PRs from Work Units
1. Build smallest independent unit → include verification → commit conventional
2. If PR→400 lines → promote commits into chained PRs

## SDD Relationship
From `sdd-tasks` Review Workload Forecast:
- **Low**: keep inside one PR
- **Medium**: commit by unit, monitor lines before PR
- **High**: follow `delivery_strategy` — ask on `ask-on-risk`, auto-slice on `auto-chain`, require `size:exception` on `single-pr`, record accepted on `exception-ok`

Each SDD work unit maps to commit/PR with: clear start → clear finish → verification in same unit → rollback without removing unrelated work.

## Commands
```bash
git diff --stat
git diff --cached --stat
git log --oneline -5
```

## Refs
commit-crafter · chained-pr · branch-pr · sdd · quality-gate

## Anti-Patterns
Commit by file type instead of work unit · Separate tests from code · >400 lines without chaining · Messages that list files · No SDD forecast check
