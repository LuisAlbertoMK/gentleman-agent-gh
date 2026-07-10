---
name: performance
description: "Web performance — CWV/INP, compositor animation, scroll-driven, content-visibility."
triggers: "performance, speed up, load time, slow loading, page speed, performance audit, INP, animation performance, scroll performance, compositor"
license: MIT
metadata:
  tags: [performance]
  author: web-quality-skills + gentleman-vMK
  version: "2.2"
  changelog: "2.1: Karpathy compression. 2.2: INP+scheduler.yield, scroll-driven CSS, compositor table, content-visibility. Karpathy compressed (6.4→3.3KB)"
---
<!-- karpathy-compressed: 2026-07-09 -->
## Budget
| Resource | Budget | | Resource | Budget |
|---|---|---|---|---|
| Total | <1.5MB | | JS (gz) | <300KB |
| CSS | <100KB | | Above-fold images | <500KB |
| Fonts | <100KB | | Third-party | <200KB |

## Critical Path: TTFB<800ms · Brotli · HTTP/2+ · Edge cache · Early Hints · preconnect · preload LCP · defer non-critical · code-split · tree-shake
## Media: AVIF→WebP→PNG→SVG, `<picture>` srcset, LCP `fetchpriority="high"`, lazy `loading="lazy"`. Fonts: `font-display:swap`, preload .woff2, unicode-range, variable fonts.
## Caching: `HTML: no-cache` · `Static hashed: public,max-age=31536000,immutable` · `API: private,no-cache`
## Runtime: Batch DOM reads · debounce scroll≥100ms · rAF for anim · virtualize >100 · View Transitions API · Third-party: async/IObserver/Facade
## Metrics: LCP<2.5s · FCP<1.8s · TBT<200ms
### INP Deep Guide (<200ms target)
| Phase | Target | How |
|---|---|---|
| Input Delay | <50ms | Reduce main thread blocking |
| Processing | <100ms | **`scheduler.yield()`** |
| Presentation | <50ms | Compositor anim, batch DOM, `content-visibility:auto` |
```js
async function handleHeavy() { updateImmediately(); await scheduler.yield(); sendAnalytics(); await scheduler.yield(); processRemaining(); }
```
### CLS: explicit w/h or `aspect-ratio` · reserved space · `font-display:swap` · `transform` for anim
## Animation — Compositor vs Main Thread
| Property | Thread | Cost | OK? |
|---|---|---|---|
| `transform`, `opacity` | **Compositor** | GPU 60fps | ✅ Always |
| `filter` | Compositor | GPU | ⚠️ With care |
| `width`, `height`, `top`, `left` | Main thread | Layout+Paint 5-20ms | ❌ NEVER |
| `margin`, `padding` | Main thread | Layout+cascades | ❌ NEVER |

Animate ONLY `transform`+`opacity`. One layout prop in @keyframes → poisons to main thread. `will-change` sparingly.
## Scroll-Driven + Visibility (CSS, 0KB bundle)
```css
.reveal { animation: fade-up 0.5s ease-out; animation-timeline: view(); animation-range: entry 0% entry 100%; }
@supports not (animation-timeline:view()) { .reveal { opacity:1; transform:none; } }
.lazy-section { content-visibility: auto; contain-intrinsic-size: 500px; }
```
Scroll: JS only for GSAP-level choreography. Visibility: skips off-screen rendering + `contain-intrinsic-size`. `contain: layout style paint` = render boundaries.
## Refs: [web.dev CWV](https://web.dev/learn-core-web-vitals) · [MDN INP](https://developer.mozilla.org/en-US/docs/Web/Performance/Guides/INP) · ui-engine · web-quality-audit · baseline-ui
