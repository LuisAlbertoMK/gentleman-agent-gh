---
name: testing-strategy
description: "Test strategy - pyramid analysis, coverage gaps, risk-based prioritization, test debt, ROI-driven investment."
triggers: "testing strategy, test plan, test coverage, test pyramid, test debt, test gap, test priority, test audit, quality strategy"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Test strategy & planning — pyramid analysis, coverage gaps, risk-based prioritization, test debt, ROI-driven investment. **Scope**: Strategy only — NOT execution (see `e2e-testing`, `api-testing`, `quality-gate`). **Mode**: READ-ONLY. Recommend, don't implement.

## Rules
1. NEVER write test files — delegate to e2e-testing/api-testing/quality-gate. 2. ALWAYS reference existing tests before recommending. 3. Risk: P0=core, P2=nice-to-have. 4. ROI estimate required.

## 1. Pyramid — Measure & Target
E2E 5-10% | Int 15-25% | Unit 60-80%. Targets: Greenfield 70/20/10 | Mature 60/25/15 | Legacy 40/30/30. Measure: count tests per layer.

## 2. Coverage Gaps — Detect
Unit: throw/catch edges | Int: supertest/contract/pact | E2E: login/auth/journey. Security: xss/sql-inject/csrf/bypass | Perf: N+1/memory/heap/response-time.

## 3. Test Debt — Quantify
1. Ratio test/src (target >0.8). 2. High-change untested: `git log --oneline --name-only -100 | grep -v test | sort | uniq -c | sort -rn`. 3. Risk = (change_freq × criticality) / coverage. 4. Priority: highest risk first.

## 4. Risk-Based Prioritization
CRITICAL (auth, payments, data integrity, security): 80%+ E2E, E2E+contract+mutation. HIGH (core logic, public APIs): 60%+ int. MEDIUM (features, internal): 40%+ unit. LOW (UI polish, admin, generated): smoke. **Rule**: Money/identity/user data → CRITICAL.

## 5. ROI
`ROI = (bug_leak_cost × catch_prob) / (test_hours × maint_hours)`. High: Auth, data, API, payments. Example: src/payments/ 3/12 (25%) → 8/12 (67%): 1.Unit PaymentProcessor(6 paths,4h) 2.Int Stripe mock(3h) 3.E2E checkout(2h) → 9h → -60% P0 risk → ROI ($50k×0.7)/(9h×2h/yr)=$1,944/h.

## 6. Testing Patterns — Verify Strategy
Monthly: `gh run list --limit 50 --json conclusion | jq failures`; `npx nyc report --reporter=lcov`. PR: map changed files to risk tier → CRITICAL=E2E+int+unit, HIGH=int+unit, else=unit. Quarterly: Wk1 Top 5 risk→unit | Wk2 Top 3 APIs→contract | Wk3 2 journeys→E2E | Wk4 CRITICAL→mutation.

## 7. Edge Cases — Pyramid FAILS
Flaky dominant→Quarantine→fix root→pyramid | Legacy zero tests→Characterization→strangle | Over-mocked→reduce mocks, real deps | Microservices→Pact | UI-heavy→Chromatic | Data/ML→property-based+statistical | Regulated→traceability req→test→evidence.

## 8. Anti-Patterns — STOP
100% coverage (diminishing >80%) · Test implementation (test behavior) · No risk diff · Plan without steps · Ignore maint cost · Mock everything · E2E for everything · Unit-test getters/DTOs · Coverage theater (assert true) · No debt budget (10-20% sprint capacity)