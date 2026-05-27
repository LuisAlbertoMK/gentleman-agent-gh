---
name: pr-evidence
description: >
  Extends branch-pr with SDD evidence: attach test results, spec coverage, and verify output to PR.
  Trigger: Creating PR after SDD cycle, "pr evidence", "PR con evidencia".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When
After a SDD cycle (spec → design → apply → verify) · Before `gh pr create` · Before opening PR · User asks "PR con evidencia"

## Critical Patterns

### 1. Collect Evidence — gather SDD artifacts BEFORE creating PR
Before opening the PR, collect:
- **Spec coverage**: list of spec scenarios implemented
- **Test results**: output from running the test suite (pass/fail count)
- **TDD Evidence**: if Strict TDD was active, include the TDD Cycle Evidence table
- **Verify output**: if `sdd-verify` ran, include the verification report (TDD Compliance, Test Layer Distribution, Coverage)
- **Files changed**: list with brief description of each change

### 2. PR Body — extend branch-pr template
The PR body MUST include these additional sections AFTER the standard `branch-pr` format:

```markdown
### SDD Evidence

**Spec Coverage:**
| Scenario | Status | Test File |
|----------|--------|-----------|
| {scenario description} | ✅ Implemented | `path/to/test.ext` |
| {scenario 2} | ✅ Implemented | `path/to/test2.ext` |

**Test Results:** ✅ {N} passed, {N} failed, {N} skipped

**TDD Cycle Evidence:**
| Task | Test File | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-----|-------|-------------|----------|
| {task} | `path/to/test` | ✅ Written | ✅ Passed | ✅ 3 cases | ✅ Clean |

**Verification:**
- **TDD Compliance**: {N}/{total} checks passed
- **Coverage (changed files)**: {N}% average
- **Linter**: ✅ / ⚠️ {N} warnings
- **Type Checker**: ✅ / ❌ {N} errors
```

### 3. Skip Rules — only include what exists
- If SDD cycle was NOT used → skip SDD Evidence section entirely
- If no tests exist → report "⚠️ No tests — manual verification required"
- If verify phase did not run → report "Verification: not run"
- NEVER fabricate evidence — if data isn't available, say so

### 4. Pre-PR Quality Gate
Before creating the PR, run these checks (delegates to `quality-gate` if loaded):
1. Tests pass? → if not → DO NOT create PR
2. Linter passes? → if not → WARNING in PR body
3. Type checker passes? → if not → WARNING in PR body
4. Any secrets in diff? → if yes → BLOCK PR

## Decision Tree
```
About to create PR after implementation:
├── Was this an SDD cycle?
│   ├── YES → collect: spec coverage, test results, verify output
│   └── NO → only include test results (if any)
│
├── Loaded quality-gate?
│   ├── YES → run pre-PR checks → block if tests fail
│   └── NO → skip (PR still proceeds)
│
├── Test results available?
│   ├── YES → include pass/fail count
│   └── NO → note "Tests not run"
│
└── Verify output available?
    ├── YES → include compliance + coverage
    └── NO → skip (PR still valid)
```

## Workflow
```
SDD cycle complete (spec → design → apply → verify)
  ↓
[pr-evidence TRIGGERED]
  ↓
1. COLLECT:
   ├── Read spec scenarios implemented
   ├── Read test output (run if not cached)
   ├── Read verify report (if exists)
   └── Read files changed
  ↓
2. BUILD PR BODY:
   ├── Standard branch-pr template
   ├── + SDD Evidence section
   └── + Pre-PR quality checks
  ↓
3. RUN QUALITY GATE:
   ├── Tests pass? → continue
   └── Tests fail? → STOP — fix before PR
  ↓
4. CREATE PR:
   └── gh pr create with full body
```

## Commands
```bash
# Run tests for evidence
go test ./... 2>&1          # Go
npm test 2>&1               # Node
pnpm test 2>&1              # Fast Node

# Verify SDD artifacts exist
Test-Path -LiteralPath "openspec/"  # Spec files
Test-Path -LiteralPath "sdd-verify-output.md"  # Verify report

# Create PR with evidence
gh pr create --title "{type}({scope}): {desc}" --body "{full body with evidence}"
```

## Resources
- **PR workflow**: [branch-pr/](../branch-pr/SKILL.md) — base PR template to extend
- **TDD evidence**: [sdd-apply/strict-tdd.md](../sdd-apply/strict-tdd.md) — TDD Cycle Evidence table format
- **Verify output**: [sdd-verify/strict-tdd-verify.md](../sdd-verify/strict-tdd-verify.md) — verification report format
- **Quality gate**: [quality-gate/](../quality-gate/SKILL.md) — pre-PR checks
