---
name: work-unit-commits
description: > Plan commits as reviewable work units.
  Trigger: Implementation, commit splitting, chained PRs.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## CRITICAL RULES
| Rule | Requirement |
|------|-------------|
| Commit by work unit | One deliverable behavior/fix/docs per commit |
| Keep tests with code | Tests in SAME commit as behavior they verify |
| Keep docs with change | Docs with feature/workflow they explain |
| Tell a story | Reviewer understands why each commit exists |
| Future PR-ready | Each commit = candidate chained PR slice |

## CHECKLIST
- [ ] One clear purpose
- [ ] Repo makes sense after THIS commit only
- [ ] Tests/docs included when relevant
- [ ] Rollback possible without reverting unrelated work
- [ ] Message explains outcome, not file list

## SPLIT EXAMPLES
| Weak | Better |
|------|--------|
| `add models` | `feat(auth): add token validation model + tests` |
| `add services` | `feat(auth): wire validation into login flow` |
| `add tests` | Tests included with each behavior commit |
| `update docs` | Docs with user-facing change they explain |

## SDD RELATIONSHIP
Low risk → one PR. Medium → monitor lines. High → follow `delivery_strategy`.
Each work unit maps to a commit/PR with: clear start → clear finish → verification → clean rollback.
