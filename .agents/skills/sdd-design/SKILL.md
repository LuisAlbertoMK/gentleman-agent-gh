---
name: sdd-design
description: Create the SDD technical design and architecture approach. Trigger: orchestrator launches design for a change.
author: Gentle AI
version: 1.1.0-local
mode: primary
delegate_only: true
priority: standard
triggers: "SDD design, design phase, technical design, architecture design, sdd-design"
allow_comments: true
changelog: docs/ciclos/cycle28-20260815.md
---

# SDD — Design Phase

Creates the technical design and architecture approach for a change. Triggered by the orchestrator when moving from proposal to implementation.

## Protocol

Follow **Section A** (skill loading) + **Section C** (persistence) from `skills/_shared/sdd-phase-common.md`.

**Do NOT launch sub-agents** — this is an EXECUTOR phase. Do the design work yourself.

## Input Artifacts (load in parallel)

- `sdd/{change-name}/proposal` — the approved change proposal
- `sdd/{change-name}/exploration` — (optional) exploration artifacts if a discovery phase ran
- Project standards from orchestrator (if injected)

## What to Produce

### 1. Architecture Decision

- Document the chosen architecture approach (Clean, Hexagonal, Screaming Layers, etc.)
- Define bounded contexts, modules, and dependency flow
- Choose: ports-and-adapters, event-driven, CQRS, or monolithic-with-modules
- Justify the choice against alternatives considered

### 2. Data Design

- Schema changes needed (if any)
- Migration strategy — backward compatible vs. breaking
- Data validation layers and boundaries

### 3. API Design

- Endpoints/APIs affected
- Request/response shape (OpenAPI-style or schema)
- Error handling conventions for the change

### 4. Security & Compliance

- Trust boundaries crossed
- Authentication/authorization changes needed
- Secrets/credentials handling
- Privacy impact (GDPR/CPPA) if data touched

### 5. Testing Strategy

- Unit test plan — key edge cases to cover
- Integration test plan — boundaries between services/modules
- Risk-based coverage of the 7 risk factors:
  1. Cross-context boundary (shared mutable state)
  2. File I/O, network I/O
  3. Async or concurrent execution
  4. Complex branching / cyclomatic >60
  5. Non-testable code (singletons, global state, private methods)
  6. Performance-critical paths (caching, N+1, loops)
  7. Error path / exception handling

## Actionable Examples (use as templates)

### 5.1 Design Document Template

```markdown
# Design: {Change Title}

## Context
{Link to proposal, exploration. One paragraph: why this design.}

## Architecture Decision
**Chosen**: {e.g., Hexagonal with ports-and-adapters}
**Alternatives considered**: {Clean, Modular monolith, Event-driven} — why rejected
**Dependency rule**: {e.g., domain → ports → adapters; no reverse}

## Module Map
| Module | Responsibility | Public API | Depends On |
|---|---|---|---|
| `domain/order` | Core order logic | `OrderService`, `OrderRepository` | — |
| `ports/payment` | Payment abstraction | `PaymentPort` | `domain/order` |
| `adapters/stripe` | Stripe implementation | `StripeAdapter` | `ports/payment` |

## Data Flow (Happy Path)
```mermaid
sequenceDiagram
  Client->>API: POST /orders
  API->>OrderService: create(cmd)
  OrderService->>PaymentPort: charge(cmd.payment)
  PaymentPort-->>OrderService: PaymentResult
  OrderService->>OrderRepository: save(order)
```

## Data Migration (if applicable)
| Phase | Strategy | Rollback |
|---|---|---|
| 1. Expand | Add new columns, dual-write | Drop columns |
| 2. Migrate | Backfill historical data | Revert backfill |
| 3. Contract | Remove old columns | Restore from backup |

## API Surface
| Endpoint | Method | Request | Response | Errors |
|---|---|---|---|---|
| `/orders` | POST | `CreateOrderReq` | `OrderRes` | 400, 402, 500 |

## Security Boundaries
- Trust boundary: `API` → `Domain` (validated DTOs only)
- Auth: JWT on API; domain receives `UserContext` (no tokens)
- Secrets: Stripe key in adapter only; never in domain

## Open Questions / Risks
- {Risk}: {Likelihood} — {Mitigation}
```

### 5.2 Architecture Decision Record (ADR) Template

```markdown
# ADR-{NNN}: {Title}

**Status**: {Proposed | Accepted | Superseded}
**Date**: {YYYY-MM-DD}
**Context**: {What forces us to decide?}
**Decision**: {What we chose}
**Consequences**:
- Positive: {benefits}
- Negative: {tradeoffs, costs}
- Neutral: {follow-up work}
**Alternatives**: {A: ..., B: ...} — why rejected
**Links**: proposal, design, related ADRs
```

### 5.3 Layering Pattern — Ports & Adapters (Hexagonal)

```text
src/
├── domain/           # Pure business logic, zero deps
│   ├── order.ts
│   └── ports/        # Interfaces (outbound)
│       └── PaymentPort.ts
├── application/      # Use cases, orchestrates domain
│   └── CreateOrderUseCase.ts
├── adapters/         # Implement ports (inbound/outbound)
│   ├── http/         # Inbound: Express/Fastify controllers
│   └── stripe/       # Outbound: StripePaymentAdapter.ts
└── config/           # Wiring: DI container, env
```

**Rule**: Domain imports nothing external. Adapters import domain. Application imports domain + ports.

### 5.4 API Design — Versioned, Typed, Documented

```typescript
// contracts/orders/v1/create-order.ts
export interface CreateOrderRequest {
  customerId: CustomerId;        // Branded type
  items: ReadonlyArray<OrderItem>;
  payment: PaymentMethod;        // Discriminated union
  idempotencyKey: IdempotencyKey;
}

export interface CreateOrderResponse {
  orderId: OrderId;
  status: 'created' | 'payment_pending';
  expiresAt: ISO8601;
}

export type CreateOrderError =
  | { code: 'VALIDATION_ERROR'; details: ValidationError[] }
  | { code: 'PAYMENT_DECLINED'; reason: string }
  | { code: 'IDEMPOTENCY_CONFLICT'; existingOrderId: OrderId };
```

### 5.5 Data Migration — Expand/Contract Pattern

```sql
-- Phase 1: Expand (backward compatible)
ALTER TABLE orders ADD COLUMN payment_intent_id VARCHAR(255);
CREATE INDEX idx_orders_payment_intent ON orders(payment_intent_id);

-- Phase 2: Migrate (dual-write in code, backfill script)
UPDATE orders SET payment_intent_id = pi.id
FROM payment_intents pi WHERE pi.order_id = orders.id;

-- Phase 3: Contract (after verification)
ALTER TABLE orders DROP COLUMN legacy_payment_ref;
```

## Testing Patterns (verify design before implementation)

### 6.1 Design Review Checklist

- [ ] **Traceability**: Every requirement in proposal has ≥1 design decision addressing it
- [ ] **Completeness**: All 5 sections (Arch, Data, API, Security, Testing) filled or explicit "N/A"
- [ ] **Alternatives**: ≥2 alternatives documented with rejection rationale for each major decision
- [ ] **Dependencies**: No cycles in module dependency graph (verify with `madge --circular`)
- [ ] **Testability**: Domain has zero external deps; ports defined for all outbound calls
- [ ] **Rollback**: Explicit migration rollback steps for every schema change
- [ ] **Observability**: Logging/metrics/tracing points identified per module boundary

### 6.2 Requirements Traceability Matrix

| Proposal Requirement | Design Section | Decision | Verification Method |
|---|---|---|---|
| REQ-001: Idempotent orders | API Design | IdempotencyKey in request | Integration test: duplicate POST returns same order |
| REQ-002: Stripe payment | Arch Decision | Ports & Adapters | Unit test: PaymentPort mock; E2E: Stripe webhook |
| REQ-003: GDPR delete | Security | Data port + erase endpoint | Integration test: erase removes all PII |

### 6.3 Risk-Based Verification Gates

| Risk Factor | Gate | Pass Criteria |
|---|---|---|
| Cross-context boundary | Contract test | Consumer-driven contract (Pact) passes |
| Async/concurrency | Chaos test | No data loss under 100 concurrent creates |
| Performance (N+1) | Load test | p95 < 200ms at 10x expected load |
| Error paths | Fault injection | All 5xx paths return structured error, no crashes |

## Edge Cases (when to adapt or skip)

### 7.1 Trivial Changes — Skip Design Phase

**Criteria**: Single file, <50 lines changed, no API/schema/security impact, no new dependencies.
**Action**: Orchestrator routes directly to `sdd-tasks` with proposal as input.
**Document**: Add `design: skipped — trivial change` to proposal.

### 7.2 Legacy Migration — Strangler Fig Pattern

**Context**: Replacing legacy module incrementally.
**Design additions**:
- Legacy adapter implementing new port (wraps old code)
- Feature flag to route traffic: `useNewOrderModule: boolean`
- Parallel run: both paths execute, compare results, log discrepancies
- Cutover: flip flag, monitor, remove legacy after N releases

### 7.3 Distributed Systems Boundaries

**Additional design sections required**:
- **Service contract**: Consumer-driven contract (Pact) or gRPC protobuf
- **Failure modes**: Timeout, retry, circuit breaker config per downstream
- **Consistency**: Eventual vs. strong — saga vs. 2PC, compensation logic
- **Observability**: Distributed trace headers (W3C trace-context), correlation IDs

### 7.4 Hotfix / Expedited Path

**Criteria**: Production incident, <4 hour fix window.
**Process**:
1. 15-min design sketch (arch decision + risk + rollback only)
2. Verbal review with 1 peer (async if needed)
3. Implement → verify → deploy
4. **Within 48h**: Expand to full design doc, add missing sections, link ADR

## Anti-Patterns (STOP doing these)

### 8.1 Over-Engineering / Design by Committee

**Symptoms**: 3+ design reviews for a 2-file change; "future-proofing" for hypothetical requirements; abstract factory for single implementation.
**Fix**: Time-box design to 2h max. Default to simplest architecture that satisfies current requirements. Add abstraction only when second implementation exists (Rule of Three).

### 8.2 Design Without Implementation Path

**Symptoms**: Beautiful architecture diagram but no migration plan, no adapter wiring, no test strategy; "we'll figure it out in tasks."
**Fix**: Design MUST include: module wiring (DI config), migration phases with rollback, and test strategy per risk factor. If any missing → design is incomplete, return `partial`.

## Output Envelope

```markdown
**Status**: success | partial | blocked
**Summary**: [1-3 sentences of what was designed]
**Artifacts**: Engram `sdd/{change-name}/design` | `openspec/changes/{change-name}/design.md`
**Next**: sdd-spec or sdd-tasks
**Risks**: [risks discovered, or "None"]
**Skill Resolution**: injected | fallback-registry | fallback-path | none
```

## Constraints

- Output must be implementation-ready — the `sdd-tasks` phase should be able to consume it directly
- Do NOT write implementation code — only design
- Flag any unknowns as risks, do NOT make assumptions
- Size budget: design doc ≤ 2KB; ADR ≤ 500 words per decision
- Time budget: 2h max for design phase (triggers escalation if exceeded)

(End of file - total ~2800 bytes)