---
name: sdd-verify
description: "Execute tests and prove implementation matches specs, design, and tasks."
delegate_only: true
---

> **GATE**: Loaded via `skill()` -> STOP. Delegate to `sdd-verify` sub-agent. Executor -> run directly.

## Activation
Prove completion via source inspection + REAL execution. Status from `sdd-status-contract.md` (schema, planningHome, changeRoot, artifactPaths, contextFiles, tasks, dependencies, actionContext).

## Hard Rules
- Read ALL contextFiles before judging: proposal + specs + design + tasks (partial degrades)
- All tasks complete before full verification; pending -> `blocked`
- Tests REQUIRED. Static analysis alone != verification. Runtime pass required
- Compare: specs first, design second, tasks third
- Do NOT fix issues - report only
- Persist per mode (engram/openspec/hybrid/inline for none)
- Strict TDD -> load `strict-tdd-verify.md`; else never
- Return Section D envelope (`sdd-phase-common.md`)
- Count ACTUAL requirements/scenarios - never invent totals
- Record commands, exit codes, `test_output_hash`/`build_output_hash` (strict)
- Final independent verification. Contradiction/failing -> FAIL/escalation. No 4R, Judgment Day, refuter, correction
- Use exact artifacts from status (`reviews/transaction.json`, `ledger.json`, `receipt.json`, `gate-context.json`, Engram topics). Never prompt-only

## Decision Gates
| Condition | Action |
|---|---|
| strict_tdd: true | Strict TDD; load module |
| actionContext.mode: workspace-planning | STOP |
| Tasks only | Task completion; skip spec/design |
| Tasks + specs | Completeness + correctness; skip design |
| Full artifacts | Verify all dimensions |
| Task incomplete | CRITICAL (core) / WARNING (cleanup) |
| Test non-zero | CRITICAL |
| No passing test for scenario | CRITICAL UNTESTED/FAILING |
| Design deviation | WARNING unless breaks spec |
| Unchecked tasks | ALWAYS CRITICAL |
| No runtime evidence (tasks only) | PASS WITH WARNINGS |
| Missing covering tests (required) | CRITICAL unless manual OK by config |

## Execution
1. Load skills (A); retrieve artifacts (B) or read contextFiles.
2. Resolve TDD mode; count completed/incomplete tasks.
3. Map spec requirements/scenarios -> evidence + tests.
4. Check design vs code (skip if missing; record why).
5. Run test/build/typecheck/coverage. Source inspection != spec compliance.
6. Build compliance matrix from results.
7. Persist report with skipped dimensions.

## Output
`## Verification Report`: change, mode, completeness table, build/test/coverage evidence, compliance matrix, correctness table, design coherence, issues (CRITICAL/WARNING/SUGGESTION), verdict `PASS` / `PASS WITH WARNINGS` / `FAIL`.

## References
- `references/report-format.md` · `strict-tdd-verify.md` (strict only) · `../_shared/sdd-phase-common.md`