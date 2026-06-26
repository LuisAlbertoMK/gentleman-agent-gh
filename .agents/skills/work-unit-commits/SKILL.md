---
name: work-unit-commits
description: "Plan commits as reviewable work units. Trigger: implementation, commit splitting, chained PRs, or keeping tests and docs with code."
triggers: "commit planning, work units, commit organization, commit split, PR slices"
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Critical Rules

| Rule | Requirement |
|------|-------------|
| Commit by work unit | A commit = deliverable behavior, fix, migration, or docs unit |
| Keep tests with code | Tests belong in same commit as the behavior they verify |
| Keep docs with change | Docs belong with the feature/flow they explain |
| Tell a story | Reviewer understands why each commit exists from diff+message |
| Future PR-ready | Each commit = candidate chained PR |
| SDD workload guard | >400 lines forecast → group into chained PR slices before impl |

## Checklist (before committing)

- [ ] One clear purpose
- [ ] Repo makes sense with only this commit applied
- [ ] Tests/docs included when relevant
- [ ] Rollback doesn't revert unrelated work
- [ ] Message explains outcome, not file list

## Split Pattern

```
Weak: "add models" → Strong: "feat(auth): add token validation model and tests"
Weak: "add services" → Strong: "feat(auth): wire token validation into login flow"
```

## PR & SDD Relationship

Each work unit → one commit or PR with: clear start state · finished state · verification in same unit · rollback isolated.

If SDD forecast = medium risk → commit by unit, monitor lines. High risk → follow `delivery_strategy`. Low risk → keep in one PR.

## Commands

```bash
git diff --stat          # review story before committing
git diff --cached --stat
git log --oneline -5     # check recent style
```
