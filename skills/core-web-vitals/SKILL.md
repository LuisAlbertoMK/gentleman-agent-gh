---
name: core-web-vitals
description: Optimize Core Web Vitals (LCP, INP, CLS) for better page experience and search ranking. Use when asked to "improve Core Web Vitals", "fix LCP", "reduce CLS", "optimize INP", "page experience optimization", or "fix layout shifts".
license: MIT
metadata:
  author: web-quality-skills
  version: "1.1"
---

# Core Web Vitals optimization

Targeted optimization for the three CWV metrics. Para ejemplos completos de cada issue, ver `references/`.

## The three metrics

| Metric | Measures | Good | Needs work | Poor |
|--------|----------|------|------------|------|
| **LCP** | Loading | ≤ 2.5s | 2.5s – 4s | > 4s |
| **INP** | Interactivity | ≤ 200ms | 200ms – 500ms | > 500ms |
| **CLS** | Visual Stability | ≤ 0.1 | 0.1 – 0.25 | > 0.25 |

Google measures at the **75th percentile** — 75% of page visits must meet "Good" thresholds.

---

## LCP: Largest Contentful Paint

LCP measures when the largest visible content element renders. Usually: hero image/video, large text block.

### Common causes & fixes
- **Slow server response** → TTFB < 800ms, CDN, early hints (HTTP 103)
- **Render-blocking resources** → inline critical CSS, defer JS
- **Slow resource load** → preload LCP image with `fetchpriority="high"`
- **Client-side rendering** → SSR/SSG for LCP content, lazy-load below-fold
- **Image optimization** → AVIF/WebP, responsive `srcset`, correct `sizes`

See `references/LCP.md` for detailed patterns, Speculation Rules, and framework-specific fixes. ✅ Already exists with 208 lines of deep reference.

Optimization checklist:
- [ ] TTFB < 800ms
- [ ] Critical CSS inlined
- [ ] LCP image preloaded (`fetchpriority="high"`)
- [ ] Images optimized (AVIF/WebP, responsive)
- [ ] No render-blocking JS above fold
- [ ] SSR/SSG for LCP content (if SPA)

---

## INP: Interaction to Next Paint

INP measures responsiveness across ALL interactions during a page visit (98th percentile for high-traffic).

### INP breakdown

Total INP = **Input Delay** + **Processing Time** + **Presentation Delay**

| Phase | Target | Optimization |
|-------|--------|--------------|
| Input Delay | < 50ms | Reduce main thread blocking |
| Processing | < 100ms | Optimize event handlers, break up long tasks |
| Presentation | < 50ms | Minimize layout/paint work |

### Common causes & fixes
- **Long tasks blocking main thread** → chunk work with `setTimeout()` or `scheduler.yield()`
- **Expensive event handlers** → debounce scroll/resize, throttle input
- **Slow DOM updates** → batch DOM writes, use `requestAnimationFrame`
- **Large component re-renders** → `React.memo`, virtualization, `useMemo`/`useCallback`

Optimization checklist:
- [ ] No long tasks > 50ms on critical path
- [ ] Event handlers debounced/throttled
- [ ] DOM writes batched (no layout thrashing)
- [ ] Lazy-load below-fold components
- [ ] React: `React.memo` + `useTransition` for heavy updates

---

## CLS: Cumulative Layout Shift

CLS measures unexpected layout shifts. **Formula:** `impact fraction × distance fraction`

### Common causes & fixes
- **Images without dimensions** → always set `width` + `height` or `aspect-ratio` in CSS
- **Embeds/iframes without dimensions** → reserve space with wrappers, set `aspect-ratio`
- **Dynamic content injected above existing content** → insert in a reserved container
- **Web fonts causing FOIT/FOUT** → `font-display: swap` or `optional`, preload woff2
- **Animations changing layout** → use `transform` instead of `width`/`height`/`top`

Optimization checklist:
- [ ] All images have explicit `width` + `height`
- [ ] Embeds (ads, iframes) have reserved space
- [ ] Dynamic content inserted in pre-reserved containers
- [ ] `font-display: swap` or `optional` on all `@font-face`
- [ ] Animations use `transform` and `opacity` only

---

## Measurement tools

| Type | Tool |
|------|------|
| **Lab** | Lighthouse, WebPageTest, DevTools Performance |
| **Field (RUM)** | CrUX (BigQuery), Search Console, `web-vitals` library |

```javascript
import {onLCP, onINP, onCLS} from 'web-vitals';
onLCP(console.log); onINP(console.log); onCLS(console.log);
```

## Framework quick fixes

See `references/frameworks.md` for Next.js, React, and Vue/Nuxt-specific patterns.

## References

- [web.dev/vitals](https://web.dev/vitals/)
- [chrome.com/web-vitals](https://chrome.com/web-vitals)
- [Performance optimization](../performance/SKILL.md)
- [Web Quality Audit](../web-quality-audit/SKILL.md)
