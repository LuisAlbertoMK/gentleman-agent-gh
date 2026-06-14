---
name: performance
description: Optimize web performance for faster loading and better user experience. Use when asked to "speed up my site", "optimize performance", "reduce load time", "fix slow loading", "improve page speed", or "performance audit".
license: MIT
metadata:
  author: web-quality-skills
  version: "1.1"
---

# Performance optimization

Performance checklist basado en Lighthouse. Priorizar por impacto en Core Web Vitals.

## Performance budget

| Resource | Budget |
|----------|--------|
| Total page weight | < 1.5 MB |
| JavaScript (compressed) | < 300 KB |
| CSS (compressed) | < 100 KB |
| Images (above-fold) | < 500 KB |
| Fonts | < 100 KB |
| Third-party | < 200 KB |

## Critical rendering path

### Server response
- **TTFB < 800ms.** CDN, caching, efficient backends
- **Enable compression.** Brotli > Gzip (15-20% smaller)
- **HTTP/2 or HTTP/3** for multiplexing
- **Edge caching** for HTML at CDN
- **Early Hints (HTTP 103):** `Link: </hero.webp>; rel=preload; as=image` for slow origins

### Resource loading
- `preconnect` to third-party origins
- `preload` critical LCP image + fonts
- `prerender` likely-next navigations (Speculation Rules API)
- Defer non-critical CSS + JS

### JavaScript
- `defer` non-essential scripts, `async` for independent ones
- Code splitting: route-based > component-based > feature-based
- Tree shaking: prefer named imports over full library imports

## Image optimization

| Format | Use case |
|--------|----------|
| AVIF | Photos (92%+ support, best compression) |
| WebP | Photos fallback (97%+) |
| PNG | Graphics with transparency |
| SVG | Icons, logos, illustrations |

- Responsive images: `<picture>` with AVIF → WebP → JPEG fallback + `srcset`/`sizes`
- LCP image: `fetchpriority="high"`, `loading="eager"`, `decoding="sync"`
- Below-fold: `loading="lazy"`, `decoding="async"`

## Font optimization
- `font-display: swap` (or `optional` for non-critical)
- Preload `.woff2` with `crossorigin`
- Subset to Latin (`unicode-range`)
- Prefer variable fonts (one file for all weights)

## Caching strategy

```
# HTML
Cache-Control: no-cache, must-revalidate
# Static assets with hash (immutable)
Cache-Control: public, max-age=31536000, immutable
# Static assets without hash
Cache-Control: public, max-age=86400, stale-while-revalidate=604800
# API
Cache-Control: private, max-age=0, must-revalidate
```

## Runtime performance

- **Avoid layout thrashing:** batch DOM reads, then batch writes
- **Debounce** scroll/resize handlers (≥100ms)
- **`requestAnimationFrame`** for animations (not `setInterval`)
- **Virtualize** lists >100 items with `content-visibility: auto`
- **View Transitions API** for SPA/MPA navigations (GPU-composited, no CLS cost)

## Third-party scripts
- `async` or delay until interaction (IntersectionObserver)
- Facade pattern for embeds (YouTube, maps, widgets)

## Key metrics

| Metric | Target |
|--------|--------|
| LCP | < 2.5s |
| FCP | < 1.8s |
| Speed Index | < 3.4s |
| TBT | < 200ms |
| TTI | < 3.8s |

## Testing
```bash
npx lighthouse https://example.com --output html --output-path report.html
```

## References

- [Core Web Vitals](../core-web-vitals/SKILL.md)
