# visual-testing - Reference Materials

> **Externalized from** .agents/skills/visual-testing/SKILL.md to keep the skill under the 2KB token budget (ADR-007).

## Testing
1. Baseline: change → `--update-snapshots` → `git status` shows modified snapshots, committed. 2. Deterministic: same spec twice, no changes → both pass (animations disabled, dynamic masked). 3. Regression: real CSS change → `✗` with pixel diff >0.01 — caught.


## Externalized Sections (ADR-007 compression)
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


## Dynamic Content
```typescript
// Mask
await expect(page).toHaveScreenshot('dash.png',{mask:[page.locator('[data-testid=timestamp]')]});
// Freeze
await page.addInitScript(()=>{Date.now=()=>1700000000000});
```


