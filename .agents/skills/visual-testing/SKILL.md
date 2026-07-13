---
name: visual-testing
description: "Visual verification — screenshots, visual regression, UI bug detection"
triggers: "screenshot, visual diff, visual bug, regression test, VRT, UI broken, text overflow, layout shift, responsive test"
license: Apache-2.0
metadata:
  tags: [testing, ui, visual]
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.1: Karpathy compression (<2.5KB)"
  dependencies: [command-wrapper]
  env:
    GENTLEMAN_AGENT_ROOT: "Repo root"
---

## Tools
| Tool | Use | Command |
|------|-----|---------|
| **Peek-MCP** | Ad-hoc debug | MCP: `screenshot(url)` |
| **Playwright** | CI visual regression | `npx playwright test --project=chromium` |

## Ad-Hoc Debugging
```
User: "El texto se corta en mobile"
→ screenshot(url) at 375px → analyze → "Text overflows .btn-primary"
→ read CSS → propose fix → re-screenshot → verify
```

## Automated Visual Regression
```bash
# Setup
npm install -D @playwright/test && npx playwright install chromium

# Test: test('home visual', async ({ page }) => {
#   await page.goto('/'); await expect(page).toHaveScreenshot('home.png'); });

# Run
npx playwright test --project=chromium
```

## Decision Tree
```
Visual bug? → screenshot + analyze → fix → verify
CI/CD regression? → toHaveScreenshot() → compare baseline
Responsive? → viewports 375/768/1024/1440 → compare each
```

## Bugs Detected
| Bug | Method |
|-----|--------|
| Text overflow | Screenshot diff at viewport |
| Alignment shifts | Pixel comparison |
| Z-index issues | Element capture |
| Responsive breaks | Multi-viewport diff |

## Anti-Patterns
Test without baseline · Threshold too strict (flaky) · No viewport reset between tests

## Refs
quality-gate · performance · baseline-ui · accessibility
