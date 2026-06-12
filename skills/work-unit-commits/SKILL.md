---
name: work-unit-commits
description: >
  work-unit-commits skill
triggers: "Work-unit commits, commit organization"
  Trigger: Implementation, commit splitting, chained PRs.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

## RULES
- One deliverable per commit · tests/docs with code
- Reviewer understands why each commit exists
- Each commit = candidate chained PR slice

## CHECKLIST
One purpose · repo works after ONLY this commit · tests/docs included
Rollback without reverting unrelated · message = outcome, not files

## SPLIT
`add models` → `feat(auth): add validation model + tests`
`add services` → `feat(auth): wire validation into login flow`
`add tests` → included with behavior · `update docs` → with change

## SDD
Low→one PR · Medium→monitor · High→follow `delivery_strategy`
Each unit: start → finish → verification → clean rollback

