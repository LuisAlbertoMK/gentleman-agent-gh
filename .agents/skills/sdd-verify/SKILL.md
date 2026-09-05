---
name: sdd-verify
description: "Execute tests and prove implementation matches specs, design, and tasks. Trigger: SDD verification phase."
triggers: "SDD verify, verification, test verification, verify change, SDD verification"
delegate_only: true
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2574
---
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
1. Load skills (§A). Retrieve artifacts (§B) or read `contextFiles`.
2. Resolve TDD mode. Count completed/incomplete tasks.
3. Map spec reqs/scenarios → evidence + tests.
4. Check design vs code (skip if missing, record why).
5. Run test/build/typecheck/coverage.
6. Build compliance matrix from test results.
7. Persist report with skipped dims.
Return `
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: sdd | sdd-apply | triple-verify

## Verification Report`: change, mode, completeness, build/test/coverage, compliance matrix, correctness, design coherence, issues (CRITICAL/WARNING/SUGGESTION), verdict (`PASS`/`PASS WITH WARNINGS`/`FAIL`).
## Reference
Conditions & Actions matrix → docs/skills/sdd-verify/reference.md

