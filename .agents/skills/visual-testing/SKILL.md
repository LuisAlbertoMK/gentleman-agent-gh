---
name: visual-testing
description: "Visual verification - screenshots, visual regression, UI bug detection via Playwright. See vision-analyze for LLM."
triggers: "screenshot, visual diff, visual bug, regression test, VRT, UI broken, text overflow, layout shift, responsive test, visual regression"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 596
---

## When to Use
Visual verification — screenshots, visual regression, UI bug detection. **Tool**: Playwright — `npx playwright test --project=chromium`.

## Automated
```typescript
test('home',async({page})=>{await page.goto('/');await expect(page).toHaveScreenshot('home.png')});
[{name:'mobile',w:375,h:667},{name:'tablet',w:768,h:1024},{name:'desktop',w:1440,h:900}]
  .forEach(vp=>{test('home '+vp.name,async({page})=>{await page.setViewportSize({w:vp.w,h:vp.h});
  await page.goto('/');await expect(page).toHaveScreenshot('home-'+vp.name+'.png')})});
```

## Baseline
`npx playwright test --update-snapshots` (create/update). Store in `tests/*-snapshots/`. Commit.

## Decision Tree
Visual bug?→playwright open→screenshot→fix→verify | CI regression?→toHaveScreenshot→baseline | Responsive?→multi-viewport(375/768/1024/1440) | Dynamic?→mask/freeze | Font?→mask/fallback

## Bugs
Text overflow:screenshot diff | Alignment:pixel | Z-index:element | Responsive:multi-vp | Color contrast:a11y | Missing states:hover/focus/disabled

## Output
`VRT:<spec>—<date> RESULT:<pass|fail> DIFF:<pixel-ratio> BASELINE:<match|updated> VIEWPORTS:[375/768/1024/1440]`

## Anti-Patterns
No baseline·Threshold too strict(flaky)·No viewport reset·Skip anim freeze·No CI artifacts·Ignore theme·Mask nothing dynamic·Increase threshold instead of fix

## Cross-Refs: quality-gate | performance | baseline-ui | accessibility | ui-engine

## Reference
> docs/skills/visual-testing/reference.md

## Verification
- Output: response matches the ## Output contract format exactly
- token_budget: total tokens within frontmatter token_budget
- frontmatter: name, description, triggers, token_budget present and stable
- cross-refs: each referenced skill exists
- anti-patterns: none of the listed anti-patterns reintroduced
