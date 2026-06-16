---
name: work-unit-commits
description: "Organize implementation into focused work-unit commits — one deliverable per commit, tests/docs included, clean rollback capability"
triggers: "Work-unit commits, commit organization"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

Trigger: Implementation, commit splitting, chained PRs.
## RULES- One deliverable per commit Â· tests/docs with code- Reviewer understands why each commit exists- Each commit = candidate chained PR slice
## CHECKLISTOne purpose Â· repo works after ONLY this commit Â· tests/docs includedRollback without reverting unrelated Â· message = outcome, not files
## SPLIT`add models` â†’ `feat(auth): add validation model + tests``add services` â†’ `feat(auth): wire validation into login flow``add tests` â†’ included with behavior Â· `update docs` â†’ with change
## SDDLowâ†’one PR Â· Mediumâ†’monitor Â· Highâ†’follow `delivery_strategy`Each unit: start â†’ finish â†’ verification â†’ clean rollback
