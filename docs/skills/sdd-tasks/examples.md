# sdd-tasks — Worked Examples

> **Externalized from** `.agents/skills/sdd-tasks/SKILL.md` to keep the skill under the 3KB
> token budget (ADR-007). These 5 worked examples cover the task breakdown format end-to-end.
> **Consumable by**: `sdd-tasks` sub-agent when composing `tasks.md`.

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
- [ ] (None — trivial change)
```
