---
name: web-quality-audit
description: "200+ checks: performance, a11y, SEO, responsive, animation, design tokens."
triggers: "audit, review web quality, lighthouse, page quality, optimize website, design audit, ui audit"
license: MIT
metadata:
  tags: [engineering]
  author: web-quality-skills + gentleman-vMK
  version: "2.0"
  changelog: "2.0: 3 new categories (responsive/animation/tokens), Karpathy compressed (4.7→3.1KB)"
---
<!-- karpathy-compressed: 2026-07-09 -->
## Performance (30%)
CWV: LCP<2.5s | INP<200ms | CLS<0.1. Media: WebP/AVIF, code-split, font-display:swap. Loading: preconnect, preload LCP, lazy-below-fold.
**INP**: scheduler.yield() for long tasks, compositor anim, no layout thrash. **Anim**: transform+opacity only, CSS scroll-driven.
## A11y (20%)
Perceivable: alt, contrast 4.5:1, captions. Operable: keyboard, focus visible (2px), skip links, touch ≥24×24px (rec 44×44).
**EAA 2025**: theme-switch contrast per variant, prefers-reduced-motion honored, focus in all themes. **Grid**: no `dense` on interactive, source order preserved.
## Responsive (15%) 🆕
Container queries for components · `container-type: inline-size` not `size`. Card grids: `repeat(auto-fit, minmax(280px,1fr))`. Fluid type: `clamp()` + `cqi`. Subgrid for alignment · MQ for page skeleton, CQ for components.
## Animation (10%) 🆕
Compositor-only (transform+opacity) · Easing tokenized (3 max) · Duration ≤500ms · Motion <800ms. Scroll-driven → CSS `animation-timeline`. `prefers-reduced-motion` honored · Interruptible · No decorative.
## Design Tokens (10%) 🆕
OKLCH (not HSL/RGB) · 8pt spacing · 3-tier tokens (primitive→semantic→component). Fluid type: `clamp()`. Dark mode: `light-dark()` or OKLCH inversion. Contrast ≥4.5:1 per theme, tested independently.
## SEO (15%): robots.txt, sitemap, canonical, titles 50-60ch, meta 150-160ch, H1, HTTPS, mobile-friendly, JSON-LD.
## Best Practices (15%): HTTPS, no vuln deps, CSP, DOCTYPE, UTF-8, clean console, contextual permissions.
## Severity: Critical(blockers/a11y) · High(CWV/contrast/CQ misuse) · Medium(perf/SEO/tokens) · Low(minor)
## Cadence: Pre-deploy(CWV/a11y 0/CQ) · Weekly(INP/deps/motion) · Monthly(full Lighthouse/token/theme)
## Targets: Perf≥90 A11y=100 BP≥95 SEO≥95 · Others=checklist
## Frameworks: Next(next/image, lazy, Suspense, VT) · Vue(nuxt/image, async, CQ) · Astro(partial hydration, VT, CQ)
## Site-wide: `npx unlighthouse --site <url>`
## Anti-Patterns: Lighthouse once · Skip internal a11y · No anim budget · Mix CQ/MQ without strategy · No token audit
## Refs: baseline-ui · accessibility · performance · seo · best-practices · ui-engine
