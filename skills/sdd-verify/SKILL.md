---
name: sdd-verify
description: > Validate impl vs specs/design/tasks.
  Trigger: Orchestrator launches verify.
license: MIT
metadata: author: gentleman-vMK, version: "3.4"
---

## GATE
Orchestrator loaded this? → STOP, delegate to `sdd-verify` sub-agent.
Executor sub-agent? → proceed.

## CONTRACT
Read proposal/spec/design/tasks. Persist:
| Mode | Action |
|------|--------|
| engram | `mem_save(topic_key:sdd/{change}/verify-report)` |
| openspec | `openspec/changes/{change}/verify-report.md` |
| hybrid | both | none | return only |

## GATES
| Condition | Action |
|---|---|
| strict_tdd:true + runner | Strict TDD verify (load strict-tdd-verify.md) |
| Test fails | CRITICAL |
| Spec scenario untested/failing | CRITICAL |
| Design deviation (non-breaking) | WARNING |

## STEPS
1. Load skills · 2. Retrieve artifacts
3. Resolve TDD mode · 4. Completeness: tasks [x]/total
5. Spec→impl→test mapping per scenario
6. Design coherence check
7. Test → build → coverage
8. Compliance: test PASS = COMPLIANT
9. Persist · 10. Return

## RETURN
```
{name} | {TDD/STANDARD}
Tasks:{N}/{total} | Build:{P/FAIL} | Tests:{Np}/{Nf} | Cov:{N}%
Compliance:{N}/{total} | CRIT:{list} | WARN:{list}
VERDICT:{PASS|PASS-WARNINGS|FAIL}
```
