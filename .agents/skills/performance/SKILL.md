---
name: performance
description: "Optimize web performance — Lighthouse/CWV checklist. NOT app scoring (see performance-tracker)."
triggers: "performance, speed up, load time, slow loading, page speed, performance audit"
license: MIT
metadata:
  tags: [performance]
  author: web-quality-skills
  version: "2.1"
  changelog: "2.1: Karpathy compression (2.8→1.5KB), merged CWV inline"
---
## Budget
| Resource | Budget | Resource | Budget |
|---|---|---|---|
| Total | <1.5MB | JS (gz) | <300KB |
| CSS | <100KB | Above-fold images | <500KB |
| Fonts | <100KB | Third-party | <200KB |
## Critical Path
**Server**: TTFB <800ms · Brotli > Gzip · HTTP/2+ · Edge cache · Early Hints
**Loading**: preconnect origins · preload LCP img+fonts · prerender next nav · defer non-critical CSS/JS
**JS**: `defer` non-essential, `async` independent · code-split routes · tree-shake imports
## Media
AVIF→WebP→PNG→SVG. `<picture>`, `srcset`, LCP `fetchpriority="high"`, below-fold `loading="lazy"`.
Fonts: `font-display: swap` · preload `.woff2`+crossorigin · `unicode-range` subset · variable fonts preferred.
## Caching
`HTML: no-cache` · `Static hashed: public, max-age=31536000, immutable` · `Static unhashed: public, max-age=86400, stale-while-revalidate=604800` · `API: private, no-cache`
## Runtime
Batch DOM reads · debounce scroll/resize ≥100ms · `rAF` for animations · virtualize lists >100 · View Transitions API
Third-party: `async`/IObserver delay · Facade pattern (YT, maps)
## Metrics
LCP <2.5s · FCP <1.8s · SI <3.4s · TBT <200ms · TTI <3.8s
### INP (Input Delay+Processing+Presentation): chunk long tasks, debounce handlers, batch DOM writes
| Phase | Target | How |
|---|---|---|
| Input Delay | <50ms | Reduce main thread blocking |
| Processing | <100ms | Chunk tasks (`setTimeout`/`scheduler.yield`) |
| Presentation | <50ms | Minimize layout/paint |
### CLS: explicit w/h or `aspect-ratio` · reserved embed space · `font-display: swap` · `transform` for animations
## Frameworks
React: `next/image`, `lazy()`, Suspense, `useMemo`/`useCallback` · Vue: `nuxt/image`, async components, `v-once` · Svelte: `svelte:image`, `{#await}` · Astro: `<Image>`, partial hydration
## Scan: `npx unlighthouse --site <url>` · `npx lighthouse <url> --output html`
