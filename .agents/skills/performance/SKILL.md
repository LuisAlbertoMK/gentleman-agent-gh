---
name: performance
description: "Web performance — CWV/INP, compositor animation, scroll-driven, content-visibility."
triggers: "performance, speed up, load time, slow loading, page speed, performance audit, INP, animation performance, scroll performance, compositor"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 673
---
<!-- karpathy-compressed: 2026-07-10 -->
## Budget
| Resource | Budget | | Resource | Budget |
|---|---|---|---|---|
| Total | <1.5MB | | JS (gz) | <300KB |
| CSS | <100KB | | Images | <500KB |
| Fonts | <100KB | | 3rd-party | <200KB |
## Critical Path + Caching
TTFB<800ms · Brotli · HTTP/2+ · Edge · preload LCP · defer · code-split · tree-shake
`HTML: no-cache` · `Static: public,max-age=31536000,immutable` · `API: private,no-cache`
## Media + Runtime
AVIF→WebP→PNG→SVG, `<picture>` srcset, LCP `fetchpriority="high"`, lazy. Fonts: `font-display:swap`, preload .woff2, unicode-range, variable.
Batch DOM reads · debounce scroll≥100ms · rAF · virtualize >100 · View Transitions · 3rd-party: async/IObserver/Facade
## Metrics
LCP<2.5s · FCP<1.8s · TBT<200ms · CLS: explicit w/h or `aspect-ratio` · `font-display:swap`
## INP (<200ms)
| Phase | Target | How |
|---|---|---|
| Input Delay | <50ms | Reduce main thread blocking |
| Processing | <100ms | **`scheduler.yield()`** |
| Presentation | <50ms | Compositor anim, `content-visibility:auto` |
```js
async function handleHeavy() {
  updateImmediately(); await scheduler.yield();
  sendAnalytics(); await scheduler.yield();
  processRemaining();
}
```
## Compositor
| Property | Thread | OK? |
|---|---|---|
| `transform`, `opacity` | **Compositor** GPU 60fps | ✅ |
| `filter` | Compositor GPU | ⚠️ |
| `width/height/top/left` | Main Layout+Paint | ❌ |
| `margin/padding` | Main Layout+cascades | ❌ |
Animate ONLY `transform`+`opacity`. One layout prop → poisons to main thread.
## Output
`PERF-AUDIT:<url>—<date> CRITICAL:[LCP\|CLS\|FCP\|TBT\|INP]<actual>/<budget>→<fix> HIGH:[img\|font\|JS\|CSS]<kb>→<fix> INP:<ms>→<proc>/<present> VERIFY:[lighthouse\|web-vitals]→PASS/FAIL`
## Reference
> docs/skills/performance/reference.md
## Refs
Cross-Refs: performance-tracker | baseline-ui

## Verification
- Output: response matches the ## Output contract format exactly
- token_budget: total tokens within frontmatter token_budget
- frontmatter: name, description, triggers, token_budget present and stable
- cross-refs: each referenced skill exists
- anti-patterns: none of the listed anti-patterns reintroduced
