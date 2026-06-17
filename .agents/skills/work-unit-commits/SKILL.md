---
name: work-unit-commits
description: "Plan commits as reviewable work units — one deliverable per commit, tests/docs included, clean rollback"
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## When

- Splitting features into reviewable work · preparing commits · chained PRs · keeping reviewer load healthy · SDD tasks with PRs over 400 lines

## Rules

| Rule | Requirement |
|------|-------------|
| Commit by work unit | One deliverable behavior, fix, migration, or docs unit per commit |
| Do NOT commit by file type | Avoid models / services / tests in separate commits if none works alone |
| Tests with code | Same commit as the behavior they verify |
| Docs with user-visible change | Same commit as the feature/workflow they explain |
| Tell a story | Reviewer understands why each commit exists from diff + message |
| PR-ready | Each commit should be a valid chained PR candidate |
| SDD guard | >400-line forecast → group into chained PRs before implementation |

## Checklist (pre-commit)

- [ ] One clear purpose · repo works after this commit alone · tests/docs included when relevant · rollback doesn't affect unrelated work · message explains outcome, not file list

## Split Examples

| Weak | Better work-unit |
|------|------------------|
| `add models` | `feat(auth): add token validation domain model and tests` |
| `add services` | `feat(auth): wire token validation into login flow` |

## PR & SDD

1. Build smallest independent work unit → include verification → conventional commit.
2. PR approaching 400 lines? → Promote into chained PRs.
3. SDD forecast: Low=keep in one PR · Medium=monitor lines · High=follow delivery_strategy (ask-on-risk / auto-chain / size:exception).
