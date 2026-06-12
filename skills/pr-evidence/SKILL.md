---
name: pr-evidence
description: > Extends branch-pr with SDD evidence: test results, spec coverage, verify output.
  Trigger: Creating PR after SDD cycle, "pr evidence", "PR con evidencia".
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

## When
After SDD cycle (spec→design→apply→verify) · Before `gh pr create` · User asks "PR con evidencia"

## Collect Evidence
Before PR, gather:
- **Spec coverage**: scenarios implemented
- **Test results**: pass/fail/skip counts
- **TDD Evidence**: Cycle Evidence table (if Strict TDD active)
- **Verify output**: compliance report (if sdd-verify ran)
- **Files changed**: list + description

## PR Body — extend branch-pr
Add AFTER standard template:
```markdown
### SDD Evidence
**Spec Coverage:** | Scenario | Status | Test File |
| {scenario} | ✅ | `path` |

**Test Results:** ✅ {N} passed, {N} failed, {N} skipped

**TDD Cycle:** | Task | Test File | RED | GREEN | TRIANGULATE | REFACTOR |

**Verification:** TDD Compliance: {N}/{total} | Coverage: {N}% | Linter: ✅/⚠️
```

## Skip Rules
- No SDD cycle → skip SDD Evidence entirely
- No tests → "⚠️ No tests — manual verification required"
- Verify not run → "Verification: not run"
- NEVER fabricate evidence

## Pre-PR Gate
Before creating PR:
1. Tests pass? → NO → BLOCK
2. Linter passes? → NO → WARNING in body
3. Secrets in diff? → YES → BLOCK

## Decision Tree
```
About to create PR:
├── SDD cycle? → YES: collect spec/test/verify | NO: tests only
├── quality-gate loaded? → YES: run checks | NO: skip
├── Test results? → YES: include | NO: "not run"
└── Verify output? → YES: include | NO: skip
```

## Commands
```bash
go test ./... 2>&1           # Go
npm test 2>&1                # Node
Test-Path "openspec/"        # Spec files exist?
Test-Path "sdd-verify-output.md"
gh pr create --title "{type}({scope}): {desc}" --body "{body with evidence}"
```

## Resources
- **PR workflow**: [branch-pr/](../branch-pr/SKILL.md)
- **TDD evidence**: [sdd-apply/strict-tdd.md](../sdd-apply/strict-tdd.md)
- **Verify output**: [sdd-verify/strict-tdd-verify.md](../sdd-verify/strict-tdd-verify.md)
- **Quality gate**: [quality-gate/](../quality-gate/SKILL.md)
