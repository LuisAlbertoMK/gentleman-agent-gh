---
name: visual-testing
description: "Visual verification — screenshots, visual regression, UI bug detection"
triggers: "screenshot, visual diff, visual bug, regression test, VRT, UI broken, text overflow, layout shift, responsive test, visual regression"
license: Apache-2.0
metadata:
  tags: [testing, ui, visual]
  author: gentleman-vMK
  version: "2.1"
  changelog: "2.1: Breaker fixes — removed Peek-MCP reference, fixed flaky test advice, added config scaffold, dynamic content strategy. 2.0: Added baseline management, thresholds"
  dependencies: [command-wrapper]
  env:
    GENTLEMAN_AGENT_ROOT: "Repo root"
---

## Tools
| Tool | Use | Command |
|------|-----|---------|
| **Playwright** | CI visual regression + ad-hoc | `npx playwright test --project=chromium` |

## Ad-Hoc Debugging
```
User: "El texto se corta en mobile"
→ npx playwright open --viewport-size=375,667 <url> → analyze → "Text overflows .btn-primary"
→ read CSS → propose fix → re-screenshot → verify
```

## Setup
```bash
# Install
npm install -D @playwright/test && npx playwright install chromium

# Init config (if not exists)
npx playwright install
```

### playwright.config.ts
```typescript
import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './tests',
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.01,  // 1% pixel diff tolerance
      threshold: 0.2,           // per-pixel color threshold (0-1)
      animations: 'disabled',   // freeze animations for consistency
    },
  },
  use: {
    baseURL: 'http://localhost:3000',
  },
  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
});
```

## Automated Visual Regression
```typescript
import { test, expect } from '@playwright/test';

test('home visual', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveScreenshot('home.png');
});

// Multi-viewport
const viewports = [
  { name: 'mobile', width: 375, height: 667 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1440, height: 900 },
];

for (const vp of viewports) {
  test(`home ${vp.name}`, async ({ page }) => {
    await page.setViewportSize({ width: vp.width, height: vp.height });
    await page.goto('/');
    await expect(page).toHaveScreenshot(`home-${vp.name}.png`);
  });
}
```

## Baseline Management
```bash
# Create baselines (first run)
npx playwright test --update-snapshots

# Update after intentional changes
npx playwright test --update-snapshots

# Baselines stored in: tests/visual.spec.ts-snapshots/
# Commit baselines to git for CI comparison
```

## Threshold Configuration
```typescript
// Per-test override for flaky areas
await expect(page).toHaveScreenshot('mobile.png', {
  maxDiffPixelRatio: 0.02,  // more tolerant on mobile
});

// Per-page for dynamic content
await expect(page).toHaveScreenshot('feed.png', {
  mask: [page.locator('.timestamp'), page.locator('.avatar')],  // mask dynamic elements
});
```

## Dynamic Content Strategy
For pages with timestamps, random data, or user content:
```typescript
// Mask dynamic elements
await expect(page).toHaveScreenshot('dashboard.png', {
  mask: [
    page.locator('[data-testid="timestamp"]'),
    page.locator('[data-testid="user-avatar"]'),
    page.locator('.live-feed'),
  ],
});

// Or use CSS to freeze time
await page.addInitScript(() => {
  Date.now = () => 1700000000000;  // fixed timestamp
});
```

## Decision Tree
```
Visual bug? → playwright open → screenshot + analyze → fix → verify
CI/CD regression? → toHaveScreenshot() → compare baseline
Responsive? → multi-viewport test (375/768/1024/1440)
Dynamic content? → mask selectors or freeze time
Font differences? → mask text or use web-safe fallback
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
Test without baseline · Threshold too strict (flaky) · No viewport reset between tests · Skip animation freeze · No CI artifact storage · Ignore theme differences · Mask nothing on dynamic pages · Increase threshold instead of root-causing flakiness

## Refs
quality-gate · performance · baseline-ui · accessibility · ui-engine
