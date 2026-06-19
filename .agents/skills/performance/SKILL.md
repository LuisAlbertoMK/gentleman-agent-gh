---
name: performance
description: Optimize web performance for faster loading and better user experience. Use when asked to "speed up my site", "optimize performance", "reduce load time", "fix slow loading", "improve page speed", or "performance audit".
triggers: "performance, speed up, load time, slow loading, page speed, performance audit"
license: MIT
metadata:
  tags:
    - performance
  author: web-quality-skills
  version: "1.2"
---

# Performance optimization

Checklist basado en Lighthouse. Priorizar por impacto en Core Web Vitals.

## Performance budget
| Resource | Budget |
|----------|--------|
| Total page | <1.5MB | JS (compressed) | <300KB | CSS | <100KB |
| Images above-fold | <500KB | Fonts | <100KB | Third-party | <200KB |

## Critical rendering path
**Server**: TTFB <800ms · Brotli > Gzip · HTTP/2 or 3 · Edge caching · Early Hints (HTTP 103)
**Loading**: preconnect origins · preload LCP image+fonts · prerender next nav (Speculation Rules) · defer non-critical CSS/JS
**JS**: `defer` non-essential, `async` independent · code-split route-based · tree-shake named imports

## Images
| Format | Use |
|--------|-----|
| AVIF | Photos (92%+ support) |
| WebP | Photos fallback (97%+) |
| PNG | Transparency |
| SVG | Icons, logos |

Responsive: `<picture>` AVIF→WebP→JPEG + `srcset`/`sizes`. LCP: `fetchpriority="high"`, `loading="eager"`. Below-fold: `loading="lazy"`.

## Fonts
`font-display: swap` (or `optional`) · preload `.woff2` + crossorigin · subset with `unicode-range` · prefer variable fonts

## Caching
`HTML: no-cache, must-revalidate` · `Static (hashed): public, max-age=31536000, immutable` · `Static (unhashed): public, max-age=86400, stale-while-revalidate=604800` · `API: private, max-age=0, must-revalidate`

## Runtime
Batch DOM reads before writes · debounce scroll/resize ≥100ms · `requestAnimationFrame` for animations · virtualize lists >100 · View Transitions API for SPA nav

## Third-party
`async` or IntersectionObserver delay · Facade pattern for embeds (YouTube, maps)

## Key metrics
LCP <2.5s · FCP <1.8s · Speed Index <3.4s · TBT <200ms · TTI <3.8s

## Framework-specific
| Stack | Key patterns |
|-------|-------------|
| React/Next | `next/image`, `React.lazy()`, Suspense boundaries for INP, `useMemo`/`useCallback` for render thrash |
| Vue/Nuxt | `nuxt/image`, async components, `v-once`, computed properties |
| Svelte | `svelte:image`, `{#await}`, reactive `$:` statements |
| Astro | `<Image>`, partial hydration (`client:load`/`idle`), View Transitions |

## Site-wide scan
`npx unlighthouse --site <url>` -- full-site Lighthouse scan with smart page sampling.
Ideal for regressions: run before/after deploy.

## Testing
`npx lighthouse https://example.com --output html --output-path report.html`

## Refs
[Core Web Vitals](../core-web-vitals/SKILL.md)
