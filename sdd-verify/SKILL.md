---
name: sdd-verify
description: > Validate impl vs specs/design/tasks.
  Trigger: Orchestrator launches verify.
license: MIT
metadata: author: gentleman-programming, version: "3.3"
---

## CONTRACT
engram: read proposal/spec/design/tasks→save verify-report
openspec: save to `openspec/changes/{change}/verify-report.md`
hybrid: both | none: inline

## STEPS
1. Load skills
2. TDD strict? → load strict-tdd-verify.md
3. Completeness: tasks total/[x]/remaining
4. Correctness: spec scenarios evidence
5. Coherence: design decisions followed?
6. TDD check (strict)
7. Testing: static→run→build→coverage
8. Compliance: test PASS = COMPLIANT
9. Persist
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
