---
name: testing-strategy
description: "Test strategy - pyramid analysis, coverage gaps, risk-based prioritization, test debt, ROI-driven investment."
triggers: "testing strategy, test plan, test coverage, test pyramid, test debt, test gap, test priority, test audit, quality strategy, what to test, how to test"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Test strategy & planning — pyramid analysis, coverage gaps, risk-based prioritization, test debt assessment, ROI-driven test investment.

**Scope**: Test planning/strategy—NOT execution(see `e2e-testing`,`api-testing`,`quality-gate`).
**Output**: Strategy doc/gap analysis—NOT test files/scripts.
**Mode**: READ-ONLY. Recommend, don't implement.

## Rules
1.NEVER write test files—delegate to e2e-testing/api-testing/quality-gate
2.ALWAYS reference existing tests before recommending
3.Risk:P0=core,P2=nice-to-have
4.ROI estimate(effort vs risk reduction) required

## 1. Pyramid
E2E 5-10%(critical paths)|Integration 15-25%(contracts+API)|Unit 60-80%(business logic)

## 2. Coverage Gaps
Unit:pure logic+edges+errors?|Integration:contracts+DB?|E2E:journeys+auth?|Security:bypass+injection?|Perf:N+1+mem+response?

## 3. Test Debt
1.Ratio test/src files 2.Untested high-change modules 3.`Risk=(change_freq×criticality)/coverage` 4.Priority:highest risk first

## 4. Risk-Based
CRITICAL(auth/payments/ integrity):80%+E2E mandatory|HIGH(core logic/API):60%+integration|MEDIUM(feature):40%+unit|LOW(UI/admin):smoke

## 5. ROI
`ROI=(bug_leak_cost×catch_prob)/(test_hours×maintenance_hours)`. High:auth/data/API. Low:getters/generated/stable-legacy

## 6. Recommendations
```
Module:src/payments/ Current:3/12src(25%) Target:8/12(67%) Priority:HIGH
Steps:1.Unit PaymentProcessor(6paths) 2.Integration Stripe(mock) 3.E2E checkout
Estimate:2d→-60%P0 risk
```

## Anti-Patterns
100%coverage(diminishing>80%)·Test implementation(brittle)·No risk differentiation·Plan without steps·Ignore maintenance cost
