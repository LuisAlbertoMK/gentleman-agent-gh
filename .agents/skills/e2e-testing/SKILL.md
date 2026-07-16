---
name: e2e-testing
description: |
  E2E testing toolkit — hybrid approach: simple scripts for quick checks + Playwright test runner for comprehensive testing.
  
  Triggers: test, e2e, playwright, browser testing, interactive testing, form testing, click test, navigate test.
  
  Usage:
  - Quick check: `e2t http://localhost:3000 --actions "click:#login,fill:#email,test.com"`
  - Full test: `npx playwright test` with custom test files
  
  Requires: Playwright (npm install -D playwright), Ollama (optional for AI analysis)
---

# E2E Testing Skill

Hybrid approach: **simple scripts** for quick checks + **Playwright test runner** for comprehensive testing.

## Quick Mode (Simple Scripts)

Like vision-analyze but interactive. Good for quick checks.

### Commands

```powershell
# Basic interactive test
e2t http://localhost:3000 --actions "click:#login"

# With form filling
e2t http://localhost:3000 --actions "fill:#email,user@test.com,fill:#password,pass123,click:#submit"

# With AI analysis
e2t http://localhost:3000 --actions "click:#login" --analyze

# Screenshot after actions
e2t http://localhost:3000 --actions "click:#login" --screenshot after-login.png
```

### Action Syntax

```
click:#selector          — Click element
fill:#selector=value     — Fill input field (use = as separator)
type:#selector=value     — Type text (keyboard events)
select:#selector=value   — Select dropdown option
wait:#selector           — Wait for element to appear
wait:1000                — Wait N milliseconds
screenshot:name.png      — Take screenshot
```

## Full Mode (Playwright Test Runner)

For comprehensive testing with assertions, parallel execution, and reporting.

### Structure

```
tests/
  e2e/
    login.spec.js        — Login flow tests
    dashboard.spec.js    — Dashboard tests
    api.spec.js          — API response tests
    visual.spec.js       — Visual regression tests
```

### Example Test

```javascript
// tests/e2e/login.spec.js
const { test, expect } = require('@playwright/test');

test('login flow', async ({ page }) => {
  await page.goto('http://localhost:3000');
  
  // Fill form
  await page.fill('#email', 'user@test.com');
  await page.fill('#password', 'pass123');
  
  // Click submit
  await page.click('#submit');
  
  // Assert redirect
  await expect(page).toHaveURL(/dashboard/);
  
  // Assert element visible
  await expect(page.locator('.welcome')).toBeVisible();
});
```

### Run Tests

```bash
# All tests
npx playwright test

# Specific file
npx playwright test tests/e2e/login.spec.js

# With UI
npx playwright test --ui

# Generate report
npx playwright show-report
```

## When to Use Which

| Scenario | Mode | Why |
|----------|------|-----|
| Quick smoke test | Simple | Fast, no setup |
| Form validation | Simple | Interactive actions |
| CI/CD pipeline | Full | Assertions, reporting |
| Visual regression | Full | Screenshot comparisons |
| API testing | Full | Response assertions |
| Multi-step workflow | Full | Complex scenarios |

## AI Analysis (Optional)

Add `--analyze` to any simple command for Ollama analysis:

```powershell
e2t http://localhost:3000 --actions "click:#login" --analyze
```

Uses moondream by default. Add `--model llava:7b` for better quality (slower).

## Requirements

- Playwright: `npm install -D playwright`
- Chromium: `npx playwright install chromium`
- Ollama (optional): For AI analysis
