---
name: core-web-vitals
description: Optimize Core Web Vitals (LCP, INP, CLS) for better page experience and search ranking. Use when asked to "improve Core Web Vitals", "fix LCP", "reduce CLS", "optimize INP", "page experience optimization", or "fix layout shifts".
license: MIT
metadata:
  author: web-quality-skills
  version: "1.2"
---

# Core Web Vitals

Targeted optimization for LCP, INP, CLS. Google measures at **75th percentile**.

| Metric | Measures | Good | Needs work | Poor |
|--------|----------|------|------------|------|
| **LCP** | Loading | ≤2.5s | 2.5–4s | >4s |
| **INP** | Interactivity | ≤200ms | 200–500ms | >500ms |
| **CLS** | Visual stability | ≤0.1 | 0.1–0.25 | >0.25 |

## LCP — Largest Contentful Paint
**Causes**: slow server, render-blocking resources, slow image load, client-side rendering
**Fixes**: TTFB <800ms · CDN · Early Hints (HTTP 103) · inline critical CSS · preload LCP img `fetchpriority="high"` · AVIF/WebP · SSR/SSG
**Checklist**: TTFB <800ms · critical CSS inlined · LCP image preloaded · images optimized · no render-blocking JS above fold · SSR/SSG if SPA

## INP — Interaction to Next Paint
Total INP = Input Delay + Processing Time + Presentation Delay
| Phase | Target | Optimization |
|-------|--------|--------------|
| Input Delay | <50ms | Reduce main thread blocking |
| Processing | <100ms | Chunk long tasks (`setTimeout`/`scheduler.yield`) |
| Presentation | <50ms | Minimize layout/paint |

**Fixes**: chunk long tasks · debounce/throttle handlers · batch DOM writes · `React.memo` + virtualization
**Checklist**: no long tasks >50ms · handlers debounced · DOM writes batched · lazy-load below-fold · `useTransition` for heavy updates

## CLS — Cumulative Layout Shift
Formula: `impact fraction × distance fraction`
**Causes**: images w/o dimensions · embeds/iframes w/o space · dynamic content injection · web fonts (FOIT/FOUT) · layout animations
**Fixes**: explicit `width`+`height` or `aspect-ratio` · reserved space for embeds · `font-display: swap` · `transform` for animations
**Checklist**: all images have dimensions · embeds reserved · dynamic content in containers · `font-display: swap` · `transform`/`opacity` only

## Measurement
**Lab**: Lighthouse, WebPageTest, DevTools · **Field**: CrUX, Search Console, `web-vitals` lib
```js
import {onLCP, onINP, onCLS} from 'web-vitals';
```

## Refs
[web.dev/vitals](https://web.dev/vitals/) · [Perf](../performance/SKILL.md) · [Web Audit](../web-quality-audit/SKILL.md)
