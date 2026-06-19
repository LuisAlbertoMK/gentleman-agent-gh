---
name: performance
description: Optimize web performance — Lighthouse-based checklist prioritized by Core Web Vitals impact
triggers: "performance, speed up, load time, slow loading, page speed, performance audit"
license: MIT
metadata:
  tags: [performance]
  author: web-quality-skills
  version: "1.3"
  changelog: "1.3: karpathy compress"
---
## Budget
| Resource | Budget | Resource | Budget |
|---|---|---|---|
| Total page | <1.5MB | JS (compressed) | <300KB |
| CSS | <100KB | Images above-fold | <500KB |
| Fonts | <100KB | Third-party | <200KB |
## Critical Path
**Server**: TTFB <800ms · Brotli > Gzip · HTTP/2 or 3 · Edge caching · Early Hints
**Loading**: preconnect origins · preload LCP image+fonts · prerender next nav · defer non-critical CSS/JS
**JS**: `defer` non-essential, `async` independent · code-split route-based · tree-shake named imports
## Images
AVIF (92%+) → WebP (97%+) → PNG transparency → SVG icons.
`<picture>`, `srcset`/`sizes`, LCP: `fetchpriority="high"`, below-fold: `loading="lazy"`
## Fonts
`font-display: swap` · preload `.woff2` + crossorigin · `unicode-range` subset · prefer variable fonts
## Caching
`HTML: no-cache` · `Static hashed: public, max-age=31536000, immutable` · `Static unhashed: public, max-age=86400, stale-while-revalidate=604800` · `API: private, max-age=0`
## Runtime
Batch DOM reads · debounce scroll/resize ≥100ms · `rAF` for animations · virtualize lists >100 · View Transitions API for SPA
## Third-party
`async` or IntersectionObserver delay · Facade pattern (YouTube, maps)
## Metrics
LCP <2.5s · FCP <1.8s · Speed Index <3.4s · TBT <200ms · TTI <3.8s
## Frameworks
| Stack | Key patterns |
|---|---|
| React/Next | `next/image`, `React.lazy()`, Suspense, `useMemo`/`useCallback` for render thrash |
| Vue/Nuxt | `nuxt/image`, async components, `v-once`, computed |
| Svelte | `svelte:image`, `{#await}`, reactive `$:` |
| Astro | `<Image>`, partial hydration, View Transitions |
## Scan
`npx unlighthouse --site <url>` (full-site) · `npx lighthouse <url> --output html`
## Ref: [Core Web Vitals](../core-web-vitals/SKILL.md)
