---
name: e2e-testing
description: "E2E testing - hybrid: e2t CLI smoke checks + Playwright for flows, assertions, visual regression, Ollama AI analysis."
triggers: test, e2e, playwright, browser testing, interactive testing, form testing
changelog: docs/ciclos/cycle28-20260815.md
---

# E2E Testing Skill

Hybrid: **simple scripts** for quick checks + **Playwright test runner** for comprehensive testing.

## When to Use
Use for browser-level verification of user flows: smoke tests, form validation, login/dashboard flows, and visual regression. Prefer **Quick Mode** for fast smoke checks with no setup; use **Full Mode** for CI pipelines, assertions, and screenshot comparisons.

## Quick Mode (Simple Scripts)

### Flags
- `--url` / `-u` — URL to test (required)
- `--actions` / `-a` — Comma-separated actions
- `--headed` — Open browser visually
- `--analyze` — Ollama analysis on final screenshot
- `--model` / `-m` — Ollama model (default: moondream:latest)
- `--screenshot` / `-s` — Filename for final screenshot

### Commands
```powershell
e2t http://localhost:3000 --actions "click:#login"
e2t http://localhost:3000 --actions "click:#login" --headed
e2t http://localhost:3000 --actions "fill:#email=test,fill:#pass=test,click:#submit"
e2t http://localhost:3000 --actions "click:#login" --analyze
```

### Action Syntax
```
click:#selector          — Click element
fill:#selector=value     — Fill input (use = as separator)
type:#selector=value     — Type text
select:#selector=value   — Select dropdown
wait:#selector           — Wait for element
wait:1000                — Wait N ms
screenshot:name.png      — Take screenshot
```

## Full Mode (Playwright Test Runner)

### Structure
```
tests/e2e/
  login.spec.js        — Login flow tests
  dashboard.spec.js    — Dashboard tests
```

### Example
```javascript
const { test, expect } = require('@playwright/test');
test('login flow', async ({ page }) => {
  await page.goto('http://localhost:3000');
  await page.fill('#email', 'test');
  await page.click('#submit');
  await expect(page).toHaveURL(/dashboard/);
});
```

### Run
```bash
npx playwright test                    # All tests
npx playwright test tests/e2e/login.spec.js  # Specific
npx playwright test --ui               # With UI
npx playwright show-report             # View report
```

## When to Use Which
| Scenario | Mode | Why |
|----------|------|-----|
| Quick smoke test | Simple | Fast, no setup |
| Form validation | Simple | Interactive actions |
| CI/CD pipeline | Full | Assertions, reporting |
| Visual regression | Full | Screenshot comparisons |

## Requirements
- Playwright: `npm install -D playwright`
- Chromium: `npx playwright install chromium`
- Ollama (optional): For AI analysis
