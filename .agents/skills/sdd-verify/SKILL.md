---
name: sdd-verify
description: "Execute tests and prove implementation matches specs, design, and tasks. Trigger: SDD verification phase."
triggers: "SDD verify, verification, test verification, verify change, SDD verification"
delegate_only: true
---

> **ORCHESTRATOR GATE**: `skill()` → ORCHESTRATOR STOP. Delegate to `sdd-verify` sub-agent. Executors skip gate.

## Language
Artifacts default to English; Spanish neutral/professional if requested. Comments follow target context.

## Activation
Run when orchestrator launches verification. Prove completion via source inspection + real execution. Use status from `sdd-status-contract.md`.

## Hard Rules
- Read all `contextFiles` before judging. Full: proposal + specs + design + tasks. Partial degrades.
- All tasks must be complete before full verification. Pending → `blocked`.
- Tests required. Static analysis alone �� verification. Runtime pass required for spec compliance.
- Compare: specs first, design second, tasks third.
- Do not fix issues. Report only.
- Persist per mode: Engram, openspec, hybrid, or inline for `none`.
- Strict TDD → load `strict-tdd-verify.md`; else never.
- Return §D envelope from `../_shared/sdd-phase-common.md`.
- Count actual requirements/scenarios. Never invent totals.
- Record commands, exit codes, `test_output_hash`/`build_output_hash` in strict envelope.
- Final independent verification. Contradiction/failing → FAIL/escalation. No 4R, Judgment Day, refuter, correction.
- Use exact artifacts from status (`reviews/transaction.json`, `ledger.json`, `receipt.json`, `gate-context.json`, Engram topics). Never prompt-only.

## Decision Gates
| Condition | Action |
|---|---|
| `STRICT TDD MODE IS ACTIVE` / `strict_tdd: true` | Strict TDD; load module |
| `actionContext.mode: workspace-planning` | STOP |
| Tasks only | Task completion; skip spec/design |
| Tasks + specs | Completeness + correctness; skip design |
| Full artifacts | Verify all dimensions |
| Task incomplete | CRITICAL (core) / WARNING (cleanup) |
| Test non-zero | CRITICAL |
| No passing test for scenario | CRITICAL `UNTESTED`/`FAILING` |
| Design deviation | WARNING unless breaks spec |
| Unchecked tasks | Always CRITICAL |
| No runtime evidence (tasks only) | `PASS WITH WARNINGS` |
| Missing covering tests (required) | CRITICAL (unless manual OK by config) |

## Execution
1. Load skills (§A). Retrieve artifacts (§B) or read `contextFiles`.
2. Resolve TDD mode. Count completed/incomplete tasks.
3. Map spec requirements/scenarios → evidence + tests.
4. Check design vs code (skip if missing, record why).
5. Run test/build/typecheck/coverage. Source inspection �� spec compliance.
6. Build compliance matrix from test results.
7. Persist report with skipped dimensions.

## Output
Return `## Verification Report`: change, mode, completeness table, build/test/coverage evidence, compliance matrix, correctness table, design coherence, issues (CRITICAL/WARNING/SUGGESTION), verdict (`PASS` / `PASS WITH WARNINGS` / `FAIL`).

## References
- `references/report-format.md` — report template, compliance statuses
- `strict-tdd-verify.md` — load only when Strict TDD active
- `../_shared/sdd-phase-common.md` — loading, retrieval, persistence, envelope