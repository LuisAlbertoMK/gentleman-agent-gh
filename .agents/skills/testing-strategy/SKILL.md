---
name: testing-strategy
description: "Test strategy - pyramid analysis, coverage gaps, risk-based prioritization, test debt, ROI-driven investment."
triggers: "testing strategy, test plan, test coverage, test pyramid, test debt, test gap, test priority, test audit, quality strategy"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 3100
---
## When to Use
Test strategy & planning — pyramid analysis, coverage gaps, risk-based prioritization, test debt, ROI-driven investment. Scope: strategy only — NOT execution (`e2e-testing`, `api-testing`, `quality-gate`). READ-ONLY — recommend, don't implement.
## Rules
1. NEVER write test files — delegate to e2e-testing/api-testing/quality-gate. 2. ALWAYS reference existing tests before recommending. 3. Risk: P0=core, P2=nice-to-have. 4. ROI estimate required.
## 1. Pyramid — Measure & Target
E2E 5-10% | Int 15-25% | Unit 60-80%. Targets: Greenfield 70/20/10 | Mature 60/25/15 | Legacy 40/30/30.
## 2. Coverage Gaps — Detect
Unit: throw/catch edges | Int: supertest/contract/pact | E2E: login/auth/journey. Security: xss/sql-inject/csrf/bypass | Perf: N+1/memory/heap/response-time.
## 3. Test Debt — Quantify
1. Ratio test/src (>0.8). 2. High-change untested (`git log --name-only` − tests). 3. Risk=(freq×criticality)/coverage. 4. Highest first.
## 4. Risk-Based Prioritization
CRITICAL (auth, payments, data integrity, security): 80%+ E2E + contract + mutation. HIGH (core, public APIs): 60%+ int. MEDIUM (features, internal): 40%+ unit. LOW (UI polish, admin, generated): smoke. **Rule**: money/identity/user data → CRITICAL.
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "We need 100% coverage" | Target >80% without ROI | ROI est required (rule 4): est cost vs bug cost; >80% diminishing |
| "Add E2E for everything" | E2E proposed for unit-testable logic | Check pyramid rule 1: if behavior isolable → unit, not E2E |
| "Quick plan without steps" | Plan w/o numbered steps + owners | Every plan must have `## Steps` with owner + estimate |

## Red Flags
- 100% coverage theater (`assert true`) or mock-everything → no bug caught
- No risk diff: all features same priority (rule 3: money/identity→CRITICAL)

## Verification
- Strategy output must cite `git log --name-only` gap + existing tests reference (rules 2-3)
- Post-plan: `scripts/tests/*.Tests.ps1` count vs recommendation — gap closure measurable

## 8. Anti-Patterns — STOP
100% coverage (>80% diminishing) · Test implementation, not behavior · No risk diff · Plan w/o steps · Ignore maint cost · Mock everything · E2E for everything · Unit-test getters/DTOs · Coverage theater (assert true) · No debt budget (10-20% sprint)
## Reference
ROI (sec 5) + Testing Patterns (sec 6) + Edge Cases (sec 7) → docs/skills/testing-strategy/reference.md
## Refs
Cross-Refs: e2e-testing | api-testing
