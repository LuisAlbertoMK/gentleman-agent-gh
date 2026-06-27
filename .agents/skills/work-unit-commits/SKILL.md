---
name: work-unit-commits
description: "Plan commits as reviewable work units. Trigger: implementation, commit splitting, chained PRs, or keeping tests and docs with code."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
  changelog: "1.1: karpathy compress"
---

## When to Use
- Splitting a feature into reviewable work units
- Preparing commits before opening a PR
- Turning large changes into chained/stacked PRs
- Keeping reviewer cognitive load healthy
- Applying SDD tasks without exceeding 400 changed lines

## Critical Rules
| Rule | Requirement |
|------|-------------|
| Commit by work unit | A commit = deliverable behavior, fix, migration, or docs unit |
| Do not commit by file type | Avoid `models`→`services`→`tests` if none works alone |
| Keep tests with code | Tests in same commit as behavior they verify |
| Keep docs with change | Docs with feature/workflow they explain |
| Tell a story | Reviewer understands why each commit exists from diff + message |
| Future PR-ready | Each commit = candidate chained PR when change grows |
| SDD workload guard | >400 lines → group commits into chained PRs before impl |

## Work Unit Checklist
- [ ] One clear purpose
- [ ] Repo makes sense after this commit alone
- [ ] Tests/docs included when relevant
- [ ] Rollback reasonable without reverting unrelated work
- [ ] Message explains outcome, not file list

## Split Examples
| Weak | Better |
|------|--------|
| `add models` | `feat(auth): add token validation domain model and tests` |
| `add services` | `feat(auth): wire token validation into login flow` |
| `add tests` | Included with each behavior commit |
| `update docs` | Included with the user-facing change |

## PR Relationship
1. Build smallest independent work unit
2. Include verification for that unit
3. Commit with Conventional Commit message
4. If PR approaches 400 lines → promote commits into chained PRs

## SDD Relationship
When `sdd-tasks` produces a Review Workload Forecast:
- **Low risk**: keep work-unit commits inside one PR
- **Medium risk**: commit by work unit, monitor lines before PR
- **High risk**: follow SDD `delivery_strategy` — ask/auto-slice/require `size:exception`

Each SDD work unit maps to a commit or PR with: clear start state, clear finished state, verification in same unit, rollback safe.

## Commands
```bash
git diff --stat
git diff --cached --stat
git log --oneline -5
```
