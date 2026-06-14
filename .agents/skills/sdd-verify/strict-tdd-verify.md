# Strict TDD Module — Verify Phase

> **Loaded ONLY when Strict TDD Mode enabled + test runner available.**
> Orchestrator verified both. Follow every instruction.

## Philosophy

Verify goes beyond "does code work?" to "was code built correctly?" — was TDD actually followed? Apply reports TDD evidence; your job validates against reality.

## Step 5a: TDD Compliance Check (includes Assertion Quality Audit)

Read `apply-progress` artifact, verify TDD was followed:

```
Find "TDD Cycle Evidence" table
FOR EACH task row:
├── RED: Must say "✅ Written". Verify test file EXISTS. CRITICAL if missing.
├── GREEN: Must say "✅ Passed". Cross-ref Step 5b — test MUST pass now.
│   CRITICAL if fails now (was it really green?)
├── TRIANGULATE: "✅ N cases" → verify N tests exist. "➖ Single" → verify spec
│   has only 1 scenario. WARNING if multiple spec scenarios but 1 test case.
├── SAFETY NET: "✅ N/N" → existing tests ran. "N/A (new)" → verify file was
│   actually NEW (not modified). WARNING if modified but shows N/A.
└── REFACTOR: Not strictly verifiable. Skip.

NO TDD Evidence table? → CRITICAL — apply didn't follow protocol.

Summary: "{N}/{total} tasks have complete TDD evidence"
```

## Step 5 Expanded: Test Layer Validation

Classify ALL test files by layer:

```
Scan test files from this change:
├── Unit: single function/class in isolation. No render(), no HTTP calls, mocked deps.
├── Integration: component interaction/user behavior. render(), screen., userEvent.
├── E2E: full system via browser/HTTP. page.goto(), playwright/cypress.
└── Unknown → report as-is

Report: Unit({N} in {N} files) Integration({N}) E2E({N}) Total({N})

Cross-ref capabilities: tests using tools not in capabilities → WARNING
Per spec scenario: which layer covers it → SUGGESTION if critical logic only unit-tested
```

## Step 5d: Changed File Coverage

```
IF coverage tool available:
├── Run: {test_command} --coverage
├── Filter to files changed (from apply-progress "Files Changed")
├── Per file: Line % / Branch % / Uncovered lines + flag
│   ├─ ≥95% → ✅ Excellent
│   ├─ ≥80% → ⚠️ Acceptable
│   └─ <80% → ⚠️ Low (list uncovered lines)
├── Aggregate: avg coverage / total uncovered lines
└── WARNING if any changed file <80%

IF NOT available: "Coverage analysis skipped — no tool detected"
(NOT a failure)
```

## Step 5e: Quality Metrics

```
IF linter available: Run on changed files. Report errors/warnings.
IF type checker available: Run, filter to changed files. Report errors.
IF neither: "Quality metrics skipped — no tools detected"
```

## Report Template (Strict TDD)

```markdown
### TDD Compliance
| Check | Result | Details |
|-------|--------|---------|
| TDD Evidence reported | ✅/❌ | Found/Missing |
| All tasks have tests | ✅/❌ | {N}/{total} |
| RED confirmed | ✅/⚠️ | {N}/{total} test files verified |
| GREEN confirmed | ✅/❌ | {N}/{total} tests pass |
| Triangulation adequate | ✅/⚠️/➖ | {N} triangulated / {N} single-case |
| Safety Net for modified | ✅/⚠️ | {N}/{total} files had safety net |

**TDD Compliance**: {N}/{total} checks passed

### Test Layer Distribution
| Layer | Tests | Files | Tools |
|-------|-------|-------|-------|
| Unit | {N} | {N} | {tool} |
| Integration | {N} | {N} | {tool} |
| E2E | {N} | {N} | {tool} |

### Changed File Coverage
| File | Line% | Branch% | Uncovered Lines | Rating |
|------|-------|---------|-----------------|--------|
| path/file.ext | 95% | 90% | — | ✅ Excellent |

### Assertion Quality
| File | Line | Assertion | Issue | Severity |
|------|------|-----------|-------|----------|

**Assertion quality**: {N} CRITICAL, {N} WARNING | OR ✅ All assertions verify real behavior

### Quality Metrics
**Linter**: ✅/⚠️/❌/➖ | **Type Checker**: ✅/❌/➖
```

## Step 5f: Assertion Quality Audit (MANDATORY)

Scan ALL test files for trivial/meaningless assertions:

```
FOR EACH test file:
├── Scan for banned patterns:
│   ├─ Tautologies: expect(true).toBe(true), assert True → CRITICAL
│   ├─ Orphan empty checks: expect(result).toEqual([]) — unless companion non-empty test → WARNING
│   ├─ Type-only alone: toBeDefined(), not.toBeNull() — OK if combined with value assertion → WARNING
│   ├─ No production code call → CRITICAL
│   ├─ Ghost loops: assertions inside for/forEach on possibly-empty collection → CRITICAL
│   ├─ Incomplete TDD: passes because setup prevents code from running → CRITICAL
│   ├─ Smoke-test-only: render + toBeInTheDocument without behavioral assertions → WARNING
│   ├─ Impl detail coupling: CSS classes, internal state, mock call counts → WARNING
│   └─ Mock/assertion ratio: mocks > 2x assertions → WARNING — wrong layer
│
├─ Check triangulation quality:
│   ├─ Only 1 test case for multi-scenario behavior → WARNING
│   ├─ All tests assert same value type → WARNING
│   └─ Well-triangulated = tests assert DIFFERENT expected values
│
└─ Summary: "{N} trivial assertions in {N} files"
```

### Assertion Quality Table

Include if issues found:

```markdown
### Assertion Quality
| File | Line | Assertion | Issue | Severity |
|------|------|-----------|-------|----------|
| path/test.ts | 15 | `expect(true).toBe(true)` | Tautology | CRITICAL |
```

If clean: "**Assertion quality**: ✅ All assertions verify real behavior"

## Rules

- ALWAYS check TDD Cycle Evidence from apply-progress (primary artifact)
- ALWAYS cross-ref reported test files against execution — don't trust blindly
- ALWAYS run Assertion Quality Audit (Step 5f) — trivial tests WORSE than missing
- NO TDD evidence? CRITICAL — protocol not followed
- Tautology assertions? CRITICAL — must rewrite
- Coverage/quality metrics = informational only → WARNING max, never CRITICAL
- Test layer distribution = SUGGESTION only
- DO NOT fix issues — only report. Orchestrator decides.
- Tools unavailable? Say so cleanly and move on — never flag as failure
