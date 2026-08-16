---
name: sdd-tasks
description: "Break SDD change into implementation tasks. Trigger: orchestrator launches task planning."
triggers: "SDD tasks, task planning, implementation tasks, work breakdown"
changelog: docs/ciclos/cycle28-20260815.md
---

> **ORCHESTRATOR GATE**: `skill()` → STOP. Delegate to `sdd-tasks` sub-agent.

Change name, artifact store (`engram|openspec|hybrid|none`), delivery strategy (`ask-on-risk|auto-chain|single-pr|exception-ok`).

| Mode | Read | Save |
|---|---|---|
| engram | `sdd/{change}/proposal\|spec\|design` | `sdd/{change}/tasks` |
| openspec | `openspec-convention.md` | Filesystem |
| hybrid | Engram primary, fs fallback | Both |
| none | — | Return only |

1. **Load Skills** → §A of `sdd-phase-common.md`
2. **Analyze Design**: Identify files to create/modify/delete, dependency order, testing per component, every threat-matrix case + RED test (skip `N/A`).
3. **Write tasks.md**
   - openspec/hybrid: `openspec/changes/{change}/tasks.md`
   - engram/none: compose in memory → persist in Step 4

### Task Format
Header with workload forecast (changed lines, budget risk, chained PRs, split, strategy, chain strategy), suggested work units (unit, goal, PR, test cmd, runtime harness, rollback boundary), then phase sections with `- [ ] N.N {file, change}` checklists.

### Task Rules
- **Specific**: "Create `auth/middleware.go` with JWT validation" not "Add auth"
- **Actionable**: "Add `ValidateToken()` to `AuthService`" not "Handle tokens"
- **Verifiable**: "Test: `POST /login` returns 401 without token" not "Make sure it works"
- **Small**: One file/logical unit, completable in ONE session
- Concrete file paths, ordered by dependency, per-phase numbering (1.1, 2.1)
- No vague tasks; apply `openspec/config.yaml` `rules.tasks`
- TDD: RED → GREEN → REFACTOR | Size budget: <530 words
- Threat-matrix: RED-test task before each production task (skip `N/A`)

### Workload Forecast
Estimate if >400 changed lines. Signals: file count, phases, integration, tests, docs, migrations.
If **High** or likely >400:
- `Chained PRs recommended: Yes`
- Split into work units → chained PRs (each needs: start, finish, verification, scope, test cmd, runtime harness, rollback boundary)
- **Chain strategy**: `stacked-to-main` · `feature-branch-chain` · `size-exception`
- `Decision needed`: `ask-on-risk`→Yes, `auto-chain`→No, `single-pr`→Yes, `exception-ok`→No

**Guard contract** (required plain-text):
```text
Decision needed before apply: Yes|No
Chained PRs recommended: Yes|No
Chain strategy: stacked-to-main|feature-branch-chain|size-exception|pending
400-line budget risk: Low|Medium|High
```
`feature-branch-chain`: PR#1→tracker, PR#2→PR#1, PR#3→PR#2. Wrong base = retarget before review.

### Phase Organization
1. Foundation — types, interfaces, DB, config, deps
2. Core — main logic, business rules
3. Integration — connect components, routes, UI
4. Testing — unit, integration, e2e; spec scenarios
5. Cleanup — docs, dead code, polish

4. **Persist** — §C of `sdd-phase-common.md`

---

## EXAMPLES (5)

### Example 1: Feature Addition — Payment Integration (Full Design Provided)
```markdown
# Tasks: Add Stripe Payment Integration

## Workload Forecast
- Estimated changed lines: ~480
- File count: 12 (4 new, 6 modified, 2 deleted)
- 400-line budget risk: **High**
- Chained PRs recommended: **Yes**
- Chain strategy: **feature-branch-chain**

## Work Units
| Unit | Goal | PR | Test Cmd | Runtime Harness | Rollback Boundary |
|------|------|----|----------|-----------------|-------------------|
| U1 | Foundation: types, ports, config | PR#1 | `go test ./domain/...` | Domain unit tests | Revert U1 files |
| U2 | Core: PaymentService, StripeAdapter | PR#2 | `go test ./application/...` | Integration w/ Stripe mock | Revert U2 files |
| U3 | Integration: HTTP routes, webhooks | PR#3 | `go test ./adapters/http/...` | E2E test against test Stripe | Revert U3 files |
| U4 | Cleanup: docs, dead code | PR#3 | `make lint && make test` | Full suite | Revert U4 files |

Decision needed before apply: **Yes** (High risk → ask-on-risk triggers)

## Phase 1: Foundation
- [ ] 1.1 `domain/payment/types.go` — Create `PaymentMethod`, `PaymentIntent`, `PaymentResult` types
- [ ] 1.2 `domain/payment/ports.go` — Create `PaymentPort` interface (Charge, Refund, GetStatus)
- [ ] 1.3 `config/payment.go` — Add Stripe config (API key, webhook secret, idempotency config)
- [ ] 1.4 `domain/payment/ports_test.go` — **RED**: Test PaymentPort contract with mock (fail until impl)

## Phase 2: Core
- [ ] 2.1 `application/payment/service.go` — Create `PaymentService` implementing business rules (idempotency, validation, retry)
- [ ] 2.2 `application/payment/service_test.go` — **RED**: Test PaymentService logic with mocked PaymentPort
- [ ] 2.3 `adapters/stripe/adapter.go` — Create `StripeAdapter` implementing PaymentPort
- [ ] 2.4 `adapters/stripe/adapter_test.go` — **RED**: Test StripeAdapter against Stripe test mode

## Phase 3: Integration
- [ ] 3.1 `adapters/http/payment_handler.go` — Create HTTP handlers (POST /payments, POST /payments/webhook)
- [ ] 3.2 `adapters/http/payment_handler_test.go` — **RED**: Test handlers with httptest + mocked service
- [ ] 3.3 `cmd/server/main.go` — Wire PaymentService, StripeAdapter, HTTP handlers into DI container
- [ ] 3.4 `migrations/004_add_payment_tables.sql` — Create payments, payment_intents tables with indexes

## Phase 4: Testing
- [ ] 4.1 `integration/payment_flow_test.go` — E2E: create payment → webhook confirmed → status updated
- [ ] 4.2 `integration/webhook_retry_test.go` — E2E: webhook failure → exponential backoff retry → max retries alert
- [ ] 4.3 `integration/idempotency_test.go` — E2E: duplicate idempotency key returns original payment

## Phase 5: Cleanup
- [ ] 5.1 `docs/payments.md` — Document payment flow, webhook handling, error codes
- [ ] 5.2 `internal/legacy/payment.go` — Delete legacy payment code (replaced by new domain)
```

### Example 2: Bug Fix — Rate Limiter Off-by-One (No Design, Tasks Only)
```markdown
# Tasks: Fix Rate Limiter Off-by-One Error

## Workload Forecast
- Estimated changed lines: ~35
- File count: 2 (1 modified, 1 test added)
- 400-line budget risk: **Low**
- Chained PRs recommended: **No**
- Chain strategy: **pending** (single PR)

Decision needed before apply: **No**

## Phase 1: Foundation
- [ ] 1.1 `internal/ratelimit/limiter.go` — Fix off-by-one: change `if count >= limit` to `if count > limit`
- [ ] 1.2 `internal/ratelimit/limiter_test.go` — **RED**: Add test for exact limit boundary (100 req allowed, 101st rejected)

## Phase 2: Core
- [ ] 2.1 `internal/ratelimit/limiter.go` — Add `Reset()` method for test cleanup

## Phase 3: Integration
- [ ] 3.1 `cmd/server/main.go` — Verify rate limiter wired correctly (no code change, verification only)

## Phase 4: Testing
- [ ] 4.1 `internal/ratelimit/limiter_test.go` — Add test: burst at limit boundary passes, one over fails
- [ ] 4.2 `integration/ratelimit_test.go` — E2E: 100 rapid requests pass, 101st returns 429

## Phase 5: Cleanup
- [ ] 5.1 `CHANGELOG.md` — Add fix entry under [Unreleased]
```

### Example 3: Refactor — Extract Order Domain to Hexagonal (Design Provided)
```markdown
# Tasks: Extract Order Domain (Hexagonal Refactor)

## Workload Forecast
- Estimated changed lines: ~620
- File count: 18 (8 new, 7 modified, 3 deleted)
- 400-line budget risk: **High**
- Chained PRs recommended: **Yes**
- Chain strategy: **stacked-to-main**

## Work Units
| Unit | Goal | PR | Test Cmd | Runtime Harness | Rollback Boundary |
|------|------|----|----------|-----------------|-------------------|
| U1 | Domain layer: entities, ports, events | PR#1 | `go test ./domain/order/...` | Domain unit tests | Revert U1 |
| U2 | Application: use cases, commands | PR#2 | `go test ./application/order/...` | Use case tests w/ mocks | Revert U2 |
| U3 | Adapters: HTTP, DB, Event bus | PR#3 | `go test ./adapters/...` | Integration tests | Revert U3 |
| U4 | Migration: strangler fig, feature flag | PR#4 | `go test ./...` | Parallel run verification | Feature flag off |
| U5 | Cleanup: remove legacy, docs | PR#4 | `make test && make lint` | Full suite | Revert U5 |

Decision needed before apply: **Yes**

## Phase 1: Foundation
- [ ] 1.1 `domain/order/entity.go` — Create `Order`, `OrderItem`, `OrderStatus` entities
- [ ] 1.2 `domain/order/ports.go` — Create `OrderRepository`, `PaymentPort`, `InventoryPort`, `EventPublisher`
- [ ] 1.3 `domain/order/events.go` — Create `OrderCreated`, `OrderPaid`, `OrderCancelled` domain events
- [ ] 1.4 `domain/order/ports_test.go` — **RED**: Test port contracts with mocks

## Phase 2: Core
- [ ] 2.1 `application/order/create_use_case.go` — Create `CreateOrderUseCase` (validate, persist, publish event)
- [ ] 2.2 `application/order/create_use_case_test.go` — **RED**: Test use case with all ports mocked
- [ ] 2.3 `application/order/pay_use_case.go` — Create `PayOrderUseCase` (payment + inventory reservation)
- [ ] 2.4 `application/order/cancel_use_case.go` — Create `CancelOrderUseCase` (compensating transactions)

## Phase 3: Integration
- [ ] 3.1 `adapters/db/order_repository.go` — Create `SQLOrderRepository` implementing OrderRepository
- [ ] 3.2 `adapters/stripe/payment_adapter.go` — Create `StripePaymentAdapter` implementing PaymentPort
- [ ] 3.3 `adapters/inventory/adapter.go` — Create `InventoryAdapter` implementing InventoryPort
- [ ] 3.4 `adapters/eventbus/publisher.go` — Create `KafkaEventPublisher` implementing EventPublisher
- [ ] 3.5 `adapters/http/order_handler.go` — Create HTTP handlers (POST /orders, POST /orders/{id}/pay, POST /orders/{id}/cancel)
- [ ] 3.6 `config/di.go` — Wire all adapters into DI container with feature flag `useNewOrderModule`

## Phase 4: Testing
- [ ] 4.1 `integration/order_create_test.go` — E2E: create order → verify event published
- [ ] 4.2 `integration/order_pay_test.go` — E2E: pay order → payment + inventory reserved → event published
- [ ] 4.3 `integration/strangler_test.go` — Parallel run: old + new paths execute, compare results, log discrepancies
- [ ] 4.4 `integration/cancel_compensation_test.go` — E2E: cancel paid order → refund + inventory release

## Phase 5: Cleanup
- [ ] 5.1 `internal/legacy/order.go` — Delete legacy order module (after feature flag 100% new for 2 releases)
- [ ] 5.2 `docs/architecture/order-domain.md` — Document new hexagonal structure
- [ ] 5.3 `migrations/005_order_domain.sql` — Add order_events table for event sourcing
```

### Example 4: Security Hardening — JWT Refresh Rotation (Spec + Design Provided)
```markdown
# Tasks: Implement JWT Refresh Token Rotation

## Workload Forecast
- Estimated changed lines: ~280
- File count: 7 (3 new, 4 modified)
- 400-line budget risk: **Medium**
- Chained PRs recommended: **Yes** (security change → auto-chain)
- Chain strategy: **feature-branch-chain**

Decision needed before apply: **No** (auto-chain)

## Phase 1: Foundation
- [ ] 1.1 `domain/auth/types.go` — Add `RefreshToken`, `TokenFamily`, `RotationConfig` types
- [ ] 1.2 `domain/auth/ports.go` — Add `RefreshTokenStore` port (Store, Validate, Revoke, Rotate)
- [ ] 1.3 `config/auth.go` — Add rotation config (max family age, reuse detection window)
- [ ] 1.4 `domain/auth/ports_test.go` — **RED**: Test RefreshTokenStore contract

## Phase 2: Core
- [ ] 2.1 `application/auth/refresh_use_case.go` — Create `RefreshTokenUseCase` (validate, detect reuse, rotate, revoke family)
- [ ] 2.2 `application/auth/refresh_use_case_test.go` — **RED**: Test reuse detection → revoke all family tokens
- [ ] 2.3 `application/auth/logout_use_case.go` — Update `LogoutUseCase` to revoke refresh token family

## Phase 3: Integration
- [ ] 3.1 `adapters/db/refresh_token_store.go` — Create `SQLRefreshTokenStore` with family tracking
- [ ] 3.2 `adapters/http/auth_handler.go` — Update POST /auth/refresh, POST /auth/logout handlers
- [ ] 3.3 `migrations/006_refresh_tokens.sql` — Create refresh_tokens table with family_id, revoked_at, replaced_by

## Phase 4: Testing
- [ ] 4.1 `integration/refresh_rotation_test.go` — E2E: valid refresh → new access+refresh, old refresh revoked
- [ ] 4.2 `integration/reuse_detection_test.go` — E2E: reused refresh → 401 + entire family revoked
- [ ] 4.3 `integration/logout_revokes_family_test.go` — E2E: logout → all family tokens invalidated

## Phase 5: Cleanup
- [ ] 5.1 `docs/security/jwt-rotation.md` — Document rotation flow, reuse detection, monitoring
- [ ] 5.2 `internal/auth/legacy_tokens.go` — Remove legacy single-refresh-token code
```

### Example 5: Trivial Change — Add Health Check Endpoint (Skip Design, Single File)
```markdown
# Tasks: Add Health Check Endpoint

## Workload Forecast
- Estimated changed lines: ~25
- File count: 1 (1 new)
- 400-line budget risk: **Low**
- Chained PRs recommended: **No**
- Chain strategy: **pending**

Decision needed before apply: **No**

## Phase 1: Foundation
- [ ] 1.1 `adapters/http/health_handler.go` — Create `HealthHandler` with GET /health returning `{status: "ok", version: "x.y.z"}`

## Phase 2: Core
- [ ] 2.1 `adapters/http/health_handler_test.go` — **RED**: Test health endpoint returns 200 + correct JSON

## Phase 3: Integration
- [ ] 3.1 `cmd/server/main.go` — Register GET /health route

## Phase 4: Testing
- [ ] 4.1 `integration/health_test.go` — E2E: GET /health returns 200 + expected schema

## Phase 5: Cleanup
- (None — trivial change)
```

---

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

---

## OUTPUT ENVELOPE

```markdown
**Status**: success | partial | blocked
**Summary**: [1-3 sentences: what was planned, workload, chaining decision]
**Artifacts**: Engram `sdd/{change-name}/tasks` | `openspec/changes/{change-name}/tasks.md`
**Next**: sdd-apply or sdd-verify (if tasks-only)
**Risks**: [risks discovered, or "None"]
**Skill Resolution**: injected | fallback-registry | fallback-path | none
```

---

## CONSTRAINTS

- Output must be implementation-ready — `sdd-apply` phase should consume tasks directly without clarification
- Do NOT write implementation code — only task breakdown
- Flag any unknowns as risks, do NOT make assumptions
- Size budget: tasks.md ≤ 530 words (excluding examples/templates)
- Time budget: 1h max for task planning phase (triggers escalation if exceeded)
- Every production task must have a preceding RED test task (threat-matrix coverage ≥80%)
- Work units must be independently verifiable (test cmd + runtime harness + rollback boundary)