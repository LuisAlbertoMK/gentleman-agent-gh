---
name: work-unit-commits
description: "Plan commits as reviewable work units. Trigger: implementation, commit splitting, chained PRs, or keeping tests and docs with code."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use
Split features into reviewable work units — commit splitting, chained PRs, SDD task grouping, cognitive load management.

## Critical Rules
- **Commit by work unit**: a commit = deliverable behavior, fix, migration, or docs unit
- **No commit-by-file-type**: avoid `models`, then `services`, then `tests` if none works alone
- **Keep tests with code**: tests belong in same commit as the behavior they verify
- **Keep docs with user-visible change**: docs belong with the feature they explain
- **Tell a story**: reviewer should understand each commit from its diff + message alone
- **Future PR-ready**: each commit should be a candidate chained PR slice
- **SDD workload guard**: if SDD forecasts >400 lines, group commits into chained PRs first

## Work Unit Checklist
- [ ] One clear purpose per commit
- [ ] Repo still makes sense after this commit alone
- [ ] Tests/docs included when relevant
- [ ] Rollback possible without reverting unrelated work
- [ ] Message explains the outcome, not the file list

## PR & SDD Relationship
Work-unit commits → foundation for chained PRs:
1. Smallest independent unit with verification included
2. Conventional Commit message per unit
3. If PR approaches 400 lines → promote groups into chained PRs

SDD forecast mapping:
- **Low risk** → single PR with work-unit commits
- **Medium** → monitor line count during implementation
- **High** → follow SDD `delivery_strategy` (ask/auto-chain/exception)

Each SDD work unit maps to commit/PR with: clear start state, clear finished state, verification in same unit, clean rollback.

## Commands
```bash
# Review before committing
git diff --stat
git diff --cached --stat

# Check recent commit style
git log --oneline -5
```
