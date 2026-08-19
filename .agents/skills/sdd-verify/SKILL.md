---
name: sdd-verify
description: "Execute tests and prove implementation matches specs, design, and tasks. Trigger: SDD verification phase."
triggers: "SDD verify, verification, test verification, verify change, SDD verification"
delegate_only: true
changelog: docs/ciclos/cycle28-20260815.md
---

> **ORCHESTRATOR GATE**: `skill()` → ORCHESTRATOR STOP. Delegate to `sdd-verify` sub-agent. Executors skip gate.

Artifacts default to English; Spanish neutral/professional if requested. Comments follow target context.

Run when orchestrator launches verification. Prove completion via source inspection + real execution. Use status from `sdd-status-contract.md`.

- Read all `contextFiles` before judging. Full: proposal + specs + design + tasks. Partial degrades.
- All tasks complete before full verification. Pending → `blocked`.
- Tests required. Static analysis ≠ verification. Runtime pass required.
- Compare: specs → design → tasks.
- Do not fix. Report only.
- Persist per mode: Engram, openspec, hybrid, inline for `none`.
- Strict TDD → load `strict-tdd-verify.md`; else never.
- Return §D envelope from `../_shared/sdd-phase-common.md`.
- Count actual requirements/scenarios. Never invent totals.
- Record commands, exit codes, `test_output_hash`/`build_output_hash`.
- Final independent verification. Contradiction/failing → FAIL/escalation.
- Use exact artifacts from status (`transaction.json`, `ledger.json`, `receipt.json`, `gate-context.json`, Engram topics). Never prompt-only.

### Conditions & Actions
- `strict_tdd: true` → Strict TDD; load module
- `workspace-planning` → STOP
- Tasks only → Task completion; skip spec/design
- Tasks + specs → Completeness + correctness; skip design
- Full artifacts → Verify all dimensions
- Task incomplete → CRITICAL (core) / WARNING (cleanup)
- Test non-zero / No passing test → CRITICAL `UNTESTED`/`FAILING`
- Design deviation → WARNING unless breaks spec
- Unchecked tasks / No runtime evidence → CRITICAL / `PASS WITH WARNINGS`
- Missing covering tests → CRITICAL (unless manual OK)

1. Load skills (§A). Retrieve artifacts (§B) or read `contextFiles`.
2. Resolve TDD mode. Count completed/incomplete tasks.
3. Map spec reqs/scenarios → evidence + tests.
4. Check design vs code (skip if missing, record why).
5. Run test/build/typecheck/coverage.
6. Build compliance matrix from test results.
7. Persist report with skipped dims.

Return `## Verification Report`: change, mode, completeness, build/test/coverage, compliance matrix, correctness, design coherence, issues (CRITICAL/WARNING/SUGGESTION), verdict (`PASS`/`PASS WITH WARNINGS`/`FAIL`).

---
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/sdd-verify/reference.md

---