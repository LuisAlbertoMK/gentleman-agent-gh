---
name: visual-testing
description: "Visual verification — screenshots, visual regression, UI bug detection"
triggers: "screenshot, visual diff, visual bug, regression test, VRT, UI broken, text overflow, layout shift, responsive test, visual regression"
---
**Tool**: Playwright—`npx playwright test --project=chromium`

## Setup
```bash
npm install -D @playwright/test && npx playwright install chromium
```
```typescript
export default defineConfig({
  testDir:'./tests',
  expect:{toHaveScreenshot:{maxDiffPixelRatio:0.01,threshold:0.2,animations:'disabled'}},
  use:{baseURL:'http://localhost:3000'},
  webServer:{command:'npm run dev',port:3000,reuseExistingServer:!process.env.CI},
});
```

## Automated
```typescript
test('home',async({page})=>{await page.goto('/');await expect(page).toHaveScreenshot('home.png')});
// Multi-viewport
[{name:'mobile',w:375,h:667},{name:'tablet',w:768,h:1024},{name:'desktop',w:1440,h:900}]
  .forEach(vp=>{test('home '+vp.name,async({page})=>{await page.setViewportSize({w:vp.w,h:vp.h});
  await page.goto('/');await expect(page).toHaveScreenshot('home-'+vp.name+'.png')})});
```

## Baseline: `npx playwright test --update-snapshots` (create/update). Store in `tests/*-snapshots/`. Commit.

## Dynamic Content
```typescript
// Mask
await expect(page).toHaveScreenshot('dash.png',{mask:[page.locator('[data-testid=timestamp]')]});
// Freeze
await page.addInitScript(()=>{Date.now=()=>1700000000000});
```

## Decision Tree
Visual bug?→playwright open→screenshot→fix→verify|CI regression?→toHaveScreenshot→baseline|Responsive?→multi-viewport(375/768/1024/1440)|Dynamic?→mask/freeze|Font?→mask/fallback

## Bugs
Text overflow:screenshot diff|Alignment:pixel|Z-index:element|Responsive:multi-vp|Color contrast:a11y|Missing states:hover/focus/disabled

## Anti-Patterns
No baseline·Threshold too strict(flaky)·No viewport reset·Skip anim freeze·No CI artifacts·Ignore theme·Mask nothing dynamic·Increase threshold instead of fix

## Refs
quality-gate·performance·baseline-ui·accessibility·ui-engine
