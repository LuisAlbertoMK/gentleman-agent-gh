---
name: sdd-verify
description: "Validate implementation against specs — compliance checking, build verification, scenario mapping, and structured reports"
triggers: "Validate vs specs, verify"
license: MIT
metadata: author: gentleman-vMK, version: "3.4"
---

Trigger: Orchestrator launches verify.
## GATEOrchestrator loaded this? â†’ STOP, delegate to `sdd-verify` sub-agent.Executor sub-agent? â†’ proceed.
## CONTRACTRead proposal/spec/design/tasks. Persist:| Mode | Action ||------|--------|| engram | `mem_save(topic_key:sdd/{change}/verify-report)` || openspec | `openspec/changes/{change}/verify-report.md` || hybrid | both | none | return only |
## GATES| Condition | Action ||---|---|| strict_tdd:true + runner | Strict TDD verify (load strict-tdd-verify.md) || Test fails | CRITICAL || Spec scenario untested/failing | CRITICAL || Design deviation (non-breaking) | WARNING |
## STEPS1. Load skills Â· 2. Retrieve artifacts3. Resolve TDD mode Â· 4. Completeness: tasks [x]/total5. Specâ†’implâ†’test mapping per scenario6. Design coherence check7. Test â†’ build â†’ coverage8. Compliance: test PASS = COMPLIANT9. Persist Â· 10. Return
## RETURN
```{name} | {TDD/STANDARD}Tasks:{N}/{total} | Build:{P/FAIL} | Tests:{Np}/{Nf} | Cov:{N}%Compliance:{N}/{total} | CRIT:{list} | WARN:{list}VERDICT:{PASS|PASS-WARNINGS|FAIL}```
