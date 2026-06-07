---
name: sdd-tasks
description: > Task breakdown: concrete actionable steps.
  Trigger: Orchestrator launches tasks.
license: MIT
metadata: author: gentleman-programming, version: "2.2"
---

## GATE
Orchestrator loaded this? → STOP, delegate to `sdd-tasks` sub-agent.
Executor sub-agent? → proceed.

## PHASES
Phase1:Foundation(types/interfaces/DB)
Phase2:Core(business logic)
Phase3:Integration(routes/UI wiring)
Phase4:Testing(unit/e2e)
Phase5:Cleanup(docs/dead code)

## WORKLOAD FORECAST
Estimate per phase: `~{N} files | ~{N} lines added | ~{N} modified`
If total >400 lines → add `Chained PRs recommended: Yes` + suggest split boundaries.
Include in tasks output for sdd-apply/verify to reference.

## TASK RULES
Specific|Actionable|Verifiable|Small
BAD:"Add auth"|GOOD:"Create middleware.go with JWT"