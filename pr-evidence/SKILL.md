---
name: pr-evidence
description: >
  Extends branch-pr with SDD evidence: attach test results, spec coverage, and verify output to PR.
  Trigger: Creating PR after SDD cycle, "pr evidence", "PR con evidencia".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## When
After SDD cycle (spec→design→apply→verify) · Before `gh pr create` · User asks "PR con evidencia"

## Collection — gather BEFORE PR
- **Spec coverage**: scenarios implemented
- **Test results**: pass/fail/skip counts
- **TDD evidence**: RED→GREEN→TRIANGULATE→REFACTOR per task
- **Verify output**: compliance, test layer dist, coverage
- **Files changed**: path + description

## PR Body — extends branch-pr template
Add AFTER standard `branch-pr` sections:

```
### SDD Evidence
**Spec Coverage:** | Scenario | Status | Test File |
**Test Results:** ✅ {N} passed, {N} failed
**TDD Cycle:** | Task | RED | GREEN | TRIANGULATE | REFACTOR |
**Verification:** TDD Compliance, Coverage, Linter, Type Checker
```

## Skip Rules
- No SDD cycle → skip SDD Evidence entirely
- No tests → "⚠️ No tests — manual verification required"
- No verify phase → "Verification: not run"
- NEVER fabricate — if data missing, say so

## Pre-PR Quality Gate
Before `gh pr create`:
1. Tests pass? → NO → BLOCK PR
2. Linter passes? → NO → WARNING in PR body
3. Secrets in diff? → YES → BLOCK PR
(Delegates to `quality-gate` if loaded)

## Decision Tree
```
PR after implementation:
├── SDD cycle?
│   ├── YES → collect spec coverage + test results + verify output
│   └── NO → only test results (if any)
├── quality-gate loaded?
│   ├── YES → run pre-PR checks → block if tests fail
│   └── NO → skip (PR proceeds)
├── Test results?
│   ├── YES → include counts
│   └── NO → "Tests not run"
└── Verify output?
    ├── YES → include compliance + coverage
    └── NO → skip (PR valid)
```

## Resources
- **PR workflow**: [branch-pr/](../branch-pr/SKILL.md)
- **TDD evidence**: [sdd-apply/strict-tdd.md](../sdd-apply/strict-tdd.md)
- **Verify output**: [sdd-verify/strict-tdd-verify.md](../sdd-verify/strict-tdd-verify.md)
- **Quality gate**: [quality-gate/](../quality-gate/SKILL.md)
