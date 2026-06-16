---
name: sdd-tasks
description: "Break down specs into phased, actionable implementation tasks with workload forecasting and PR splitting guidance"
triggers: "Task breakdown, implementation plan"
license: MIT
metadata: author: gentleman-vMK, version: "2.2"
---

Trigger: Orchestrator launches tasks.
## GATEOrchestrator loaded this? â†’ STOP, delegate to `sdd-tasks` sub-agent.Executor sub-agent? â†’ proceed.
## PHASESPhase1:Foundation(types/interfaces/DB)Phase2:Core(business logic)Phase3:Integration(routes/UI wiring)Phase4:Testing(unit/e2e)Phase5:Cleanup(docs/dead code)
## WORKLOAD FORECASTEstimate per phase: `~{N} files | ~{N} lines added | ~{N} modified`If total >400 lines â†’ add `Chained PRs recommended: Yes` + suggest split boundaries.Include in tasks output for sdd-apply/verify to reference.
## TASK RULESSpecific|Actionable|Verifiable|SmallBAD:"Add auth"|GOOD:"Create middleware.go with JWT"
