---
name: visual-testing
description: "Visual verification — screenshots, visual regression, UI bug detection"
triggers: "screenshot, visual diff, visual bug, regression test, VRT, UI broken, text overflow, layout shift, responsive test, visual regression"
license: Apache-2.0
metadata:
  tags: [testing, ui, visual]
  author: gentleman-vMK
  version: "2.0"
  changelog: "2.0: Added baseline management, thresholds, expanded examples. 1.1: Karpathy compression"
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

# Test file: tests/visual.spec.ts
import { test, expect } from '@playwright/test';

test('home visual', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveScreenshot('home.png');
});

test('dashboard visual', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page).toHaveScreenshot('dashboard.png');
});

# Run
npx playwright test --project=chromium
```

## Baseline Management
```bash
# Create baselines (first run)
npx playwright test --project=chromium --update-snapshots

# Update after intentional changes
npx playwright test --project=chromium --update-snapshots

# Baselines stored in: tests/visual.spec.ts-snapshots/
# Commit baselines to git for CI comparison
```

## Threshold Configuration
```typescript
// playwright.config.ts
expect: {
  toHaveScreenshot: {
    maxDiffPixelRatio: 0.01,  // 1% pixel diff tolerance
    threshold: 0.2,           // per-pixel color threshold (0-1)
    animations: 'disabled',   // freeze animations for consistency
  },
}

// Per-test override
await expect(page).toHaveScreenshot('mobile.png', {
  maxDiffPixelRatio: 0.02,  // more tolerant on mobile
});
```

## Decision Tree
```
Visual bug? → screenshot + analyze → fix → verify
CI/CD regression? → toHaveScreenshot() → compare baseline
Responsive? → viewports 375/768/1024/1440 → compare each
Flaky test? → increase threshold + disable animations
```

## Viewport Matrix
| Viewport | Width | Use Case |
|----------|-------|----------|
| Mobile | 375px | iPhone SE, small phones |
| Tablet | 768px | iPad portrait |
| Laptop | 1024px | iPad landscape, small laptops |
| Desktop | 1440px | Standard desktop |

## Bugs Detected
| Bug | Method |
|-----|--------|
| Text overflow | Screenshot diff at viewport |
| Alignment shifts | Pixel comparison |
| Z-index issues | Element capture |
| Responsive breaks | Multi-viewport diff |
| Color contrast | Visual diff + a11y check |
| Missing states | Screenshot hover/focus/disabled |

## Anti-Patterns
Test without baseline · Threshold too strict (flaky) · No viewport reset between tests · Skip animation freeze · No CI artifact storage · Ignore theme differences

## Refs
quality-gate · performance · baseline-ui · accessibility · ui-engine
