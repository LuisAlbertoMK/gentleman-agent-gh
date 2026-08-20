# Testing Strategy — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/testing-strategy/SKILL.md) for the core pyramid analysis, coverage gaps, risk-based prioritization, and ROI framework.

---

## Examples

### Example 1: Strategy for a CRITICAL Module

**Trigger**: `test strategy for src/payments` (frontmatter: "testing strategy, test coverage, test gap")

```powershell
# 1. Measure pyramid — count tests per layer (section 1)
Get-ChildItem tests -Recurse -Include *.spec.js,*.test.js | Group-Object DirectoryName | Select Name, Count

# 2. Quantify debt — test/src ratio, target >0.8 (section 3.1)
$tests = (Get-ChildItem tests -Recurse -Include *.test.js,*.spec.js).Count
$src = (Get-ChildItem src/payments -Filter *.js).Count
"ratio: {0:N1}" -f ($tests / $src)

# 3. Risk tier: money/identity → CRITICAL (section 4 rule)
```

**Expected output** — debt + tier + ROI in section-5 format:

```
payments: 3/12 (25%) → Target 8/12 (67%)
Tier: CRITICAL → 80%+ E2E, E2E + contract + mutation
ROI = ($50k × 0.7) / (9h × 2h/yr) = $1,944/h
Steps: 1.Unit PaymentProcessor(6 paths,4h) 2.Int Stripe mock(3h) 3.E2E checkout(2h)
```

**Result**: recommendation only — no test files written (rule 1: READ-ONLY; execution delegated to `e2e-testing`/`api-testing`/`quality-gate`).

---

## Testing

### 1. Read-only enforced
After a strategy session, `git status --short`:
Expected: empty output (no test files created; rule 1).

### 2. Risk tiering
The recommendation for `src/payments`/`src/auth` must be CRITICAL with 80%+ E2E:
```powershell
Select-String -Path <report.md> -Pattern 'CRITICAL.*80%' -Quiet
```
Expected: `True` (rule: Money/identity/user data → CRITICAL).

### 3. ROI present
Every recommendation carries an estimate:
```powershell
Select-String -Path <report.md> -Pattern 'ROI =' -Quiet
```
Expected: `True` (rule 4: ROI estimate required).

---

## Edge Cases — Pyramid FAILS (6)

| Scenario | Resolution |
|---|---|
| **Flaky tests dominate** | Quarantine → fix root cause → pyramid |
| **Legacy, zero tests** | Characterization → strangle → pyramid |
| **Over-mocked unit** | Reduce mocks, real deps for int |
| **Microservices** | Contract testing (Pact) |
| **UI-heavy/visual** | Visual regression (Chromatic) |
| **Data/ML** | Property-based + statistical |
| **Regulated** | Traceability: req→test→evidence |

---

## Anti-Patterns (10)

1. **100% coverage** — diminishing >80%, trivial tests
2. **Test implementation** — brittle; test behavior
3. **No risk diff** — equal auth/UI investment
4. **Plan without steps** — "improve coverage" vs "add 5 unit tests for X"
5. **Ignore maint cost** — every test has carrying cost
6. **Mock everything** — tests mocks not code; real deps for int
7. **E2E for everything** — slow/flaky; critical journeys only
8. **Unit test getters/DTOs** — zero bug catch, pure burden
9. **Coverage theater** — expect(true).toBe(true); measure branch coverage
10. **No debt budget** — debt compounds; 10-20% sprint capacity

## 5. ROI
`ROI = (bug_leak_cost × catch_prob) / (test_hours × maint_hours)`. High: Auth, data, API, payments. Example: src/payments/ 3/12 (25%) → 8/12 (67%): 1.Unit PaymentProcessor(6 paths,4h) 2.Int Stripe mock(3h) 3.E2E checkout(2h) → 9h → -60% P0 risk → ROI ($50k×0.7)/(9h×2h/yr)=$1,944/h.

## 6. Testing Patterns — Verify Strategy
Monthly: `gh run list --limit 50 --json conclusion | jq failures`; `npx nyc report --reporter=lcov`. PR: map changed files to risk tier → CRITICAL=E2E+int+unit, HIGH=int+unit, else=unit. Quarterly: Wk1 Top 5 risk→unit | Wk2 Top 3 APIs→contract | Wk3 2 journeys→E2E | Wk4 CRITICAL→mutation.

## 7. Edge Cases — Pyramid FAILS
Flaky dominant→Quarantine→fix root→pyramid | Legacy zero tests→Characterization→strangle | Over-mocked→reduce mocks, real deps | Microservices→Pact | UI-heavy→Chromatic | Data/ML→property-based+statistical | Regulated→traceability req→test→evidence.