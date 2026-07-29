---
name: testing-strategy
description: "Test strategy & planning — pyramid analysis, coverage gaps, risk-based prioritization, test debt assessment, ROI-driven test investment."
triggers: "testing strategy, test plan, test coverage, test pyramid, test debt, test gap, test priority, test audit, quality strategy, what to test, how to test"
license: Apache-2.0
metadata:
  tags: [testing, quality, strategy, planning]
  author: gentleman-vMK
  version: "1.0"
  changelog: "1.0: initial — pyramid analysis, coverage gaps, test debt, risk-based prioritization"
  dependencies: [quality-gate, code-review-agent]
---

# Testing Strategy

## Activation Contract

1. **Scope**: Test planning & strategy — NOT test execution (see `e2e-testing`, `api-testing`, `quality-gate`).
2. **Output**: Actionable strategy document or gap analysis — NOT test files or scripts.
3. **Mode**: READ-ONLY analysis. Recommend, don't implement execution details.

## Hard Rules

1. NEVER write test files — delegate to `e2e-testing`, `api-testing`, or `quality-gate`.
2. ALWAYS reference existing test files before recommending new ones.
3. Risk-based: P0 = core domain, P2 = nice-to-have.
4. Coverage recommendations must include ROI estimate (effort vs risk reduction).

## Framework

### 1. Test Pyramid Assessment

```
        ╱  E2E  ╲         ← 5-10%  (critical paths only)
       ╱─────────╲
      ╱Integration╲       ← 15-25% (contracts + api)
     ╱─────────────╲
    ╱   Unit Tests   ╲    ← 60-80% (business logic)
   ╱───────────────────╲
```

### 2. Coverage Gap Analysis

| Dimension | Checklist |
|-----------|-----------|
| Unit | Pure logic tested? Edge cases? Error paths? |
| Integration | Contracts verified? DB queries tested? |
| E2E | Critical user journeys covered? Auth flows? |
| Security | Auth bypass tested? Injection vectors? |
| Performance | N+1 queries? Memory leaks? Response times? |

### 3. Test Debt Quantification

1. Count test files vs source files (baseline ratio)
2. Identify untested modules with highest change frequency
3. Score each module: `Risk = (change_freq × business_criticality) / coverage`
4. Priority queue: highest risk first

### 4. Risk-Based Prioritization

| Risk Level | Criteria | Investment |
|-----------|----------|------------|
| CRITICAL | Auth, payments, data integrity | 80%+ coverage, E2E mandatory |
| HIGH | Core business logic, API contracts | 60%+ coverage, integration required |
| MEDIUM | Feature logic, validation | 40%+ coverage, unit tests |
| LOW | UI cosmetics, admin panels | Smoke tests only |

### 5. Test ROI Calculation

```
ROI = (bug_leak_cost × catch_probability) / (test_creation_hours × maintenance_hours)
```

- High ROI: auth, data validation, API contracts
- Low ROI: trivial getters, generated code, stable legacy code

### 6. Recommendations Format

```
Module: src/payments/
Current: 3 test files / 12 source files (25%)
Target: 8 test files / 12 source files (67%)
Priority: HIGH — payment failures cost real money
Steps:
  1. Add unit tests for PaymentProcessor (6 uncovered paths)
  2. Add integration test for Stripe client (mock mode)
  3. Add E2E for checkout flow (happy path + decline)
Estimate: 2 days → reduces P0 bug risk by ~60%
```

## Anti-Patterns

- ❌ 100% coverage goal — diminishing returns past 80%
- ❌ Testing implementation details — brittle tests
- ❌ No risk differentiation — all tests treated equally
- ❌ Strategy without execution plan — needs concrete steps
- ❌ Ignoring test maintenance cost — bad tests cost more than no tests
