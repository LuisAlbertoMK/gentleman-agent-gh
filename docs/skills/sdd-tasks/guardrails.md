# sdd-tasks — Testing Patterns, Edge Cases & Anti-Patterns

> **Externalized from** `.agents/skills/sdd-tasks/SKILL.md` to keep the skill under the 3KB
> token budget (ADR-007). These guardrails ensure RED-test enforcement, spec traceability,
> threat-matrix coverage, and common failure avoidance in task breakdowns.
> **Consumable by**: `sdd-tasks` sub-agent when composing `tasks.md`.

## TESTING PATTERNS (3)

### Pattern 1: RED Test Enforcement per Task

```bash
# Every production task MUST have a preceding RED test task
# Verify: grep -n "RED" tasks.md | wc -l ≥ production task count * 0.8
# Example check in CI:
# RED_TASKS=$(grep -c "RED" tasks.md)
# PROD_TASKS=$(grep -c "^\- \[ \] [0-9]" tasks.md | grep -v "RED\|test" | wc -l)
# if [ $RED_TASKS -lt $((PROD_TASKS * 80 / 100)) ]; then exit 1; fi
```
- RED test task written **before** production task in task list
- Test fails initially (RED), passes after implementation (GREEN)
- Skips allowed only for: config, docs, migration SQL, wiring-only tasks (mark `N/A`)

### Pattern 2: Spec Scenario → Task Traceability
```markdown
# Each spec scenario maps to ≥1 test task in Phase 4
# Traceability table (include in tasks.md footer):
| Spec Requirement | Scenario | Task ID | Test Type |
|------------------|----------|---------|-----------|
| REQ-001: Idempotent orders | Duplicate key returns original | 4.3 | Integration |
| REQ-002: Stripe payment | Webhook confirms payment | 4.1 | Integration |
| REQ-003: GDPR delete | Erase removes all PII | 4.4 | Integration |
```
- Verified in `sdd-verify`: spec scenario count == Phase 4 test task count
- Missing mapping → CRITICAL in verification

### Pattern 3: Threat Matrix → RED Test Mapping
```markdown
# 7 risk factors from design.md §5 → each gets RED test task
| Risk Factor | Design Section | RED Task ID | Test Focus |
|-------------|----------------|-------------|------------|
| Cross-context boundary | 5.1 Arch | 1.4 | Port contract test |
| File I/O / Network I/O | 5.2 Data | 2.4 | Adapter test w/ real DB/HTTP |
| Async / Concurrency | 5.3 | 4.2 | Concurrent request test |
| Complex branching (>60) | 5.4 | 2.2 | Branch coverage test |
| Non-testable code | 5.5 | 1.3 | Refactor to testable + test |
| Performance (N+1, cache) | 5.6 | 4.1 | Load test p95 < threshold |
| Error paths / Exceptions | 5.7 | 4.3 | Fault injection test |
```
- If design.md missing, infer from proposal's risk section
- Every HIGH/CRITICAL risk → mandatory RED test task

---

## EDGE CASES (4)

| Edge Case | Detection | Handling |
|-----------|-----------|----------|
| **Missing design.md** (tasks-only mode) | Orchestrator provides only proposal + specs/tasks | Infer phases from proposal's Affected Areas; skip architecture-specific tasks; add note `design: inferred from proposal` in header; flag `Risks: Design inferred — verify in review` |
| **Budget exceeded** (>530 words / >400 lines) | Word count or line estimate before persist | Split into multiple task files by work unit (U1-tasks.md, U2-tasks.md); each <530 words; link via `Related:` header; update workload forecast to show split |
| **Circular dependency in task order** | Phase N task depends on Phase N+2 output | Reorder phases: move dependency earlier; if impossible, create "Phase 0: Shared Contracts" for types/interfaces; document in Risks |
| **External dependency not ready** (e.g., Stripe API not accessible) | Integration task requires external service | Create adapter task with **contract test** against mock; mark integration task as `BLOCKED` with dependency; add `External dependency: Stripe test mode` to task; verify when available |

---

## ANTI-PATTERNS (2)

### Anti-Pattern 1: Vague / Non-Actionable Tasks
```markdown
# ❌ WRONG — unmeasurable, not completable in one session
- [ ] Add payment support
- [ ] Handle errors properly
- [ ] Make it fast
- [ ] Fix the bug
- [ ] Refactor auth module

# ✅ RIGHT — specific, actionable, verifiable
- [ ] 2.1 `application/payment/service.go` — Create PaymentService with Charge(cmd) returning PaymentResult
- [ ] 2.2 `application/payment/service_test.go` — RED: Test Charge rejects invalid amount, returns PaymentResult on success
- [ ] 3.1 `adapters/stripe/adapter.go` — Create StripeAdapter implementing PaymentPort.Charge()
- [ ] 4.1 `integration/payment_flow_test.go` — E2E: POST /payments → 201 + PaymentResult; webhook → status=confirmed
```
- Every task: file path + exact change + verifiable outcome
- "Handle X" → "Add XHandler with method Y returning Z"
- "Fix bug" → "Fix off-by-one in Limiter.Allow() at line 42"

### Anti-Pattern 2: Skipping RED Tests for "Simple" Code
```markdown
# ❌ WRONG — assumes simple code doesn't need tests
# Phase 2: Core
- [ ] 2.1 `internal/config/loader.go` — Load config from env (simple, no test needed)
- [ ] 2.2 `internal/util/helpers.go` — Add string utilities (pure functions, no test needed)

# ✅ RIGHT — RED test for EVERY production task (skip only with explicit N/A)
# Phase 1: Foundation
- [ ] 1.4 `internal/config/loader_test.go` — RED: Test loader parses all required env vars, fails on missing
- [ ] 1.5 `internal/util/helpers_test.go` — RED: Test helpers cover edge cases (empty, unicode, max length)
```
- TDD applies to ALL production code: config, utils, wiring, migrations
- Only skip: generated code, vendor files, pure SQL migrations (mark `N/A — migration`)
- "Simple" code often has subtle bugs (env parsing, unicode, boundary conditions)
