---
name: sdd-verify
description: > Validate impl vs specs/design/tasks.
  Trigger: Orchestrator launches verify.
license: MIT
metadata: author: gentleman-programming, version: "3.4"
---

## GATE
Orchestrator loaded this? → STOP, delegate to `sdd-verify` sub-agent.
Executor sub-agent? → proceed.

## CONTRACT
Read proposal/spec/design/tasks before judging. Persist per mode:
- **engram**: `mem_save(topic_key: sdd/{change}/verify-report)`
- **openspec**: save to `openspec/changes/{change}/verify-report.md`
- **hybrid**: both | **none**: return only

## DECISION GATES
| Condition | Action |
|---|---|
| Orchestrator says `STRICT TDD MODE IS ACTIVE` | Load strict-tdd-verify.md |
| strict_tdd:true + runner exists | Strict TDD verify |
| Test exits non-zero | CRITICAL |
| Spec scenario no passing test | CRITICAL (UNTESTED/FAILING) |
| Design deviation (non-breaking) | WARNING |

## STEPS
1. Load skills
2. Retrieve artifacts (proposal/spec/design/tasks)
3. Resolve TDD mode
4. Completeness: tasks total/[x]/remaining
5. Correctness: map EACH spec scenario → implementation evidence + test result
6. Coherence: design decisions followed?
7. Testing: run tests → build → coverage
8. Compliance: test PASS = COMPLIANT (not static analysis)
9. Persist verify-report
10. Return summary

## RETURN
```
VERIFY | {name} | {TDD/STANDARD}
DONE: {N}/{total} tasks
BUILD: {PASS/FAIL} | TESTS: {N}p/{N}f | COVERAGE: {N}%
COMPLIANCE: {N}/{total}
ISSUES: CRITICAL:{list} WARNING:{list}
VERDICT: {PASS/PASS-WARNINGS/FAIL}
```
