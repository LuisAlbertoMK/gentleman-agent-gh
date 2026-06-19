---
name: core-web-vitals
description: "Optimize LCP, INP, CLS for better page experience and search ranking"
triggers: "core web vitals, LCP, INP, CLS, page experience, layout shifts"
license: MIT
metadata:
  tags: [performance]
  author: web-quality-skills
  version: "1.3"
  changelog: "1.3: karpathy compress"
---
Targeted optimization for LCP, INP, CLS. Google measures at **75th percentile**.
| Metric | Good | Needs work | Poor |
|--------|------|------------|------|
| LCP | ≤2.5s | 2.5–4s | >4s |
| INP | ≤200ms | 200–500ms | >500ms |
| CLS | ≤0.1 | 0.1–0.25 | >0.25 |
## LCP
**Causes**: Slow server, render-blocking, slow image, CSR
**Fixes**: TTFB<800ms · CDN · Early Hints · inline critical CSS · preload LCP img `fetchpriority="high"` · AVIF/WebP · SSR/SSG
## INP
Total = Input Delay + Processing + Presentation Delay
**Fixes**: Chunk long tasks (`setTimeout`/`scheduler.yield`) · debounce handlers · batch DOM writes · `React.memo`+virtualization · `useTransition`
| Phase | Target | Opt |
|-------|--------|-----|
| Input Delay | <50ms | Reduce main thread blocking |
| Processing | <100ms | Chunk long tasks |
| Presentation | <50ms | Minimize layout/paint |
## CLS
Formula: impact fraction × distance fraction
**Causes**: Images w/o dimensions · iframes w/o space · dynamic content · web fonts (FOIT/FOUT)
**Fixes**: Explicit `width`+`height`/`aspect-ratio` · reserved embed space · `font-display: swap` · `transform` for animations
## Measurement
Lab: Lighthouse, WebPageTest, DevTools · Field: CrUX, Search Console, `web-vitals` lib
## Refs: [web.dev/vitals](https://web.dev/vitals/) · [Perf](../performance/SKILL.md) · [Web Audit](../web-quality-audit/SKILL.md)
