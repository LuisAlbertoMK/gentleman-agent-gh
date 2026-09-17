---
name: testing-strategy
description: "Test strategy - pyramid analysis, coverage gaps, risk-based prioritization, test debt, ROI-driven investment."
triggers: "testing strategy, test plan, test coverage, test pyramid, test debt, test gap, test priority, test audit, quality strategy"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2200
---
## Rules
1. NEVER write test files — delegate to e2e-testing/api-testing/quality-gate
2. ALWAYS reference existing tests before recommending
3. Risk: P0=core, P2=nice-to-have
4. ROI estimate required

## Pyramid
E2E 5-10% | Int 15-25% | Unit 60-80%. Greenfield 70/20/10 | Mature 60/25/15 | Legacy 40/30/30.

## Coverage Gaps
Unit: throw/catch · Int: supertest/contract/pact · E2E: login/auth/journey · Security: xss/sql-inject/csrf · Perf: N+1/memory/heap

## Test Debt
1. Ratio test/src (>0.8) 2. High-change untested (`git log --name-only` − tests) 3. Risk=(freq×criticality)/coverage 4. Highest first

## Risk-Based Prioritization
CRITICAL (auth/payments/data/security): 80%+ E2E+contract+mutation. HIGH (core/APIs): 60%+ int. MEDIUM (features): 40%+ unit. LOW (UI/admin): smoke. **Rule**: money/identity→CRITICAL.

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "cobertura como meta" | >80% sin ROI | ROI est required; >80% diminishing returns |
| "priorizar por facilidad" | No risk-based P0→LOW | money/identity→CRITICAL 80%+ |
| "E2E para todo" | E2E for unit-testeable logic | Pyramid 60-80/15-25/5-10 |

## Anti-Patterns
100% coverage theater · Test implementation not behavior · No risk diff · Plan w/o steps · Mock everything · Unit-test getters/DTOs · No debt budget

## Verification
- Cite `git log --name-only` gap + existing tests reference
- Post-plan: `scripts/tests/*.Tests.ps1` count vs recommendation

→ docs/skills/testing-strategy/reference.md · Cross-Refs: e2e-testing | api-testing | ci-cd
