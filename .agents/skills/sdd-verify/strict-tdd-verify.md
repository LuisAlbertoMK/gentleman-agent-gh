# Strict TDD — Verify Phase

> Loaded ONLY when Strict TDD Mode enabled + test runner available. Orchestrator verified both.

## TDD Compliance Check (Step 5a)
Read `apply-progress`, find "TDD Cycle Evidence" table:
- **RED**: "✅ Written" — verify test file EXISTS. CRITICAL if missing.
- **GREEN**: "✅ Passed" — cross-ref Step 5b — test MUST pass now. CRITICAL if fails.
- **TRIANGULATE**: "✅ N cases" → verify N tests exist. "➖ Single" → verify spec has 1 scenario. WARNING if multi-scenario but 1 case.
- **SAFETY NET**: "✅ N/N" → existing tests ran. "N/A (new)" → verify file was new. WARNING if modified but N/A.
- **REFACTOR**: Not verifiable. Skip.

No TDD Evidence table? → **CRITICAL** — apply didn't follow protocol.

## Test Layer Validation (Step 5 expanded)
Classify all test files:
- **Unit**: Single function/class, no render, no HTTP, mocked deps
- **Integration**: Component interaction, render()/screen/userEvent
- **E2E**: Full system, page.goto()/playwright/cypress

Cross-ref capabilities: tests using tools not in capabilities → WARNING.

## Changed File Coverage (Step 5d)
If coverage tool available: `{test_command} --coverage` on changed files.
- ≥95% → ✅ · ≥80% → ⚠️ · <80% → WARNING (list uncovered lines)
If not available: "Coverage analysis skipped — no tool detected" (not a failure)

## Quality Metrics (Step 5e)
Run linter + type checker on changed files. If unavailable: "Skipped — no tools detected".

## Assertion Quality Audit — Step 5f (MANDATORY)
Scan ALL test files for banned patterns (see strict-tdd.md Banned Patterns table):
- **Tautologies** → CRITICAL
- **Orphan empty** (empty w/o companion non-empty test) → WARNING
- **Type-only alone** — OK if combined with value assertion → WARNING
- **No production code call** → CRITICAL
- **Ghost loops** (for/forEach on possibly-empty) → CRITICAL
- **Incomplete TDD** (setup prevents code path) → CRITICAL
- **Smoke-test-only** (render+toBeInTheDocument only) → WARNING
- **Impl detail coupling** (CSS, internal state, mock counts) → WARNING
- **Mock/assertion ratio > 2** → WARNING — wrong layer

Also check triangulation quality: 1 case for multi-scenario → WARNING. All same value type → WARNING.

## Report Template
```markdown
### TDD Compliance
| Check | Result | Details |
|-------|--------|---------|
| TDD Evidence reported | ✅/❌ | Found/Missing |
| All tasks have tests | ✅/❌ | {N}/{total} |
| RED confirmed | ✅/⚠️ | {N}/{total} test files |
| GREEN confirmed | ✅/❌ | {N}/{total} tests pass |
| Triangulation adequate | ✅/⚠️/➖ | {N} triangulated / {N} single |
| Safety Net for modified | ✅/⚠️ | {N}/{total} |

**TDD Compliance**: {N}/{total} checks passed

### Test Layer Distribution | Unit:{N} | Integration:{N} | E2E:{N}

### Changed File Coverage | File | Line% | Branch% | Rating | Uncovered |

### Assertion Quality | File | Line | Assertion | Issue | Severity |
**Quality**: {N} CRITICAL, {N} WARNING OR ✅ All assertions verify real behavior

### Quality Metrics: Linter(✅/⚠️/❌/➖) TypeChecker(✅/❌/➖)
```

## Rules
- ALWAYS check TDD Cycle Evidence from apply-progress (primary artifact)
- ALWAYS cross-ref reported test files against execution — don't trust blindly
- ALWAYS run Assertion Quality Audit — trivial tests WORSE than missing
- NO TDD evidence? CRITICAL — protocol not followed
- Tautology assertions? CRITICAL — must rewrite
- Coverage/quality metrics = informational → WARNING max, never CRITICAL
- Test layer distribution = SUGGESTION only
- DO NOT fix issues — only report. Orchestrator decides.
- Tools unavailable? Say so and move on — never flag as failure
