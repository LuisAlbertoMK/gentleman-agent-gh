---
name: sdd-tasks
description: > Task breakdown: concrete actionable steps.
  Trigger: Orchestrator launches tasks.
license: MIT
metadata: author: gentleman-programming, version: "2.0"
---

## PHASES
Phase1:Foundation(types/interfaces/DB)
Phase2:Core(business logic)
Phase3:Integration(routes/UI wiring)
Phase4:Testing(unit/e2e)
Phase5:Cleanup(docs/dead code)

## TASK RULES
Specific|Actionable|Verifiable|Small
BAD:"Add auth"|GOOD:"Create middleware.go with JWT"