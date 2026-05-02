---
name: sdd-verify
description: > Validate implementation vs specs, design, tasks. Quality gate.
  Trigger: Orchestrator launches verify of completed change.
license: MIT
metadata: author: gentleman-programming, version: "3.0"
---

## CONTRACT
- engram: read proposal/spec/design/tasks → save verify-report
- openspec: save to openspec/changes/{change}/verify-report.md
- hybrid: both
- none: inline only

## STEPS
1. Load skills (sdd-phase-common.md A)
2. TDD mode: cached caps → strict_tdd? TRUE→load strict-tdd-verify.md / FALSE→standard
3. Completeness: count tasks total/[x]/incomplete
4. Correctness: structural evidence per spec scenario
5. Coherence: design decisions followed?
6. TDD check (strict only)
7. Testing: static analysis → run tests (EXECUTE) → build/type → coverage
8. Compliance matrix: test PASS = COMPLIANT
9. Persist report
10. Return summary

## RETURN
```
VERIFY
Change: {name} | Mode: {TDD/STANDARD}
COMPLETENESS: {N}/{total} tasks
BUILD: PASS/FAIL | TESTS: {N}passed/{N}failed/{N}skipped
COVERAGE: {N}% → threshold {N}%
COMPLIANCE: {N}/{total} scenarios → {table}
CORRECTNESS: {table} | COHERENCE: {table}
ISSUES: CRITICAL:{list} WARNING:{list} SUGGESTION:{list}
VERDICT: PASS/PASS-WARNINGS/FAIL
```