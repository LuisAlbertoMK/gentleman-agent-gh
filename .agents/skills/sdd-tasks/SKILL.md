---
name: sdd-tasks
description: "Break down specs into phased, actionable implementation tasks with workload forecasting and PR splitting guidance"
triggers: "Task breakdown, implementation plan"
license: MIT
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.2"
---

Trigger: Orchestrator launches tasks.
## GATEOrchestrator loaded this? → STOP, delegate to `sdd-tasks` sub-agent.Executor sub-agent? → proceed.
## PHASESPhase1:Foundation(types/interfaces/DB)Phase2:Core(business logic)Phase3:Integration(routes/UI wiring)Phase4:Testing(unit/e2e)Phase5:Cleanup(docs/dead code)
## WORKLOAD FORECASTEstimate per phase: `~{N} files | ~{N} lines added | ~{N} modified`If total >400 lines → add `Chained PRs recommended: Yes` + suggest split boundaries.Include in tasks output for sdd-apply/verify to reference.
## TASK RULESSpecific|Actionable|Verifiable|SmallBAD:"Add auth"|GOOD:"Create middleware.go with JWT"
## EXAMPLE TASK
```markdown
### Phase 2: Core (business logic)
**Estimate:** ~3 files | ~180 lines added | ~20 modified

### Task 2.1: Create profile update handler
- **Description:** Implement PUT /profile/name validation + persistence
- **Files:** src/handlers/profile.ts, src/validators/profile.ts
- **Verify:** `curl -X PUT localhost:3000/profile/name -d '{"name":"New"}'` → 200
- **Deps:** Phase 1 (types + DB schema)
```
## TASK SIZING RULES
- Single task: <50 lines changed ideally, <100 max
- If >400 lines total across all phases → split into stacked PRs
- Each task = 1 commit in the final PR (reviewable unit)
- Dependencies MUST be explicit between tasks/phases
