---
name: e2e-testing
description: "E2E testing - hybrid: e2t CLI smoke checks + Playwright for flows, assertions, visual regression, Ollama AI analysis."
triggers: test, e2e, playwright, browser testing, interactive testing, form testing
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1925
---
## When to Use
Browser-level verification of user flows: smoke, forms, login/dashboard, visual regression. Quick Mode = fast smoke; Full Mode = CI pipelines, assertions, screenshots.
## Quick Mode (e2t CLI)
Flags: `-u` (required) · `-a` comma-separated · `--headed` · `--analyze` (Ollama on final screenshot) · `-m` (default moondream:latest) · `-s`.
```powershell
e2t http://localhost:3000 --actions "click:#login"
e2t http://localhost:3000 --actions "fill:#email=test,fill:#pass=test,click:#submit"
e2t http://localhost:3000 --actions "click:#login" --analyze
```
Actions: `click:#sel` · `fill:#sel=value` · `type` · `select` · `wait:#sel`/`wait:1000` · `screenshot:name.png`.
## Full Mode (Playwright Test Runner)
Structure: `tests/e2e/login.spec.js`, `dashboard.spec.js`.
```javascript
const { test, expect } = require('@playwright/test');
test('login flow', async ({ page }) => {
  await page.goto('http://localhost:3000');
  await page.fill('#email', 'test');
  await page.click('#submit');
  await expect(page).toHaveURL(/dashboard/);
});
```
Run: `npx playwright test` · single file · `--ui` · `show-report`.
## When to Use Which
| Scenario | Mode | Why |
|---|---|---|
| Quick smoke test | Simple | Fast, no setup |
| Form validation | Simple | Interactive actions |
| CI/CD pipeline | Full | Assertions, reporting |
| Visual regression | Full | Screenshot comparisons |
## Requirements
Playwright: `npm i -D playwright` · Chromium: `npx playwright install chromium` · Ollama (optional): AI analysis.
## Reference
Worked examples, testing patterns, edge cases, anti-patterns → docs/skills/e2e-testing/reference.md