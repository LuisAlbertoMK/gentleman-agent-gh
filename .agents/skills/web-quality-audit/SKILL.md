---
name: web-quality-audit
description: "Comprehensive web audit: performance, a11y, SEO, responsive, animation, design tokens."
triggers: "audit, review web quality, lighthouse, page quality, optimize website, design audit, ui audit, web audit, site review"
---
## Prerequisites
Target site must be **running and accessible** before audit. For local dev, start server first. For production, ensure URL is publicly accessible (no auth/CAPTCHA/WAF blocking).

## Performance (30%)
CWV: LCP<2.5s | INP<200ms | CLS<0.1. Media: WebP/AVIF, code-split, font-display:swap. Loading: preconnect, preload LCP, lazy-below-fold.
**INP**: scheduler.yield() for long tasks, compositor anim, no layout thrash. **Anim**: transform+opacity only, CSS scroll-driven.
## A11y (20%)
Perceivable: alt, contrast 4.5:1, captions. Operable: keyboard, focus visible (2px), skip links, touch ≥24×24px (rec 44×44).
**EAA 2025**: theme-switch contrast per variant, prefers-reduced-motion honored, focus in all themes. **Grid**: no `dense` on interactive, source order preserved.
## Responsive (15%)
Container queries for components · `container-type: inline-size` not `size`. Card grids: `repeat(auto-fit, minmax(280px,1fr))`. Fluid type: `clamp()` + `vw` (page) / `cqi` (containers). Subgrid for alignment · MQ for page skeleton, CQ for components.
## Animation (10%)
Compositor-only (transform+opacity) · Easing tokenized (3 max) · Duration ≤500ms · Per-element <200ms. Scroll-driven → CSS `animation-timeline`. `prefers-reduced-motion` honored · Interruptible · No decorative.
## Design Tokens (10%)
OKLCH (not HSL/RGB) · 8pt spacing · 3-tier tokens (primitive→semantic→component). Fluid type: `clamp()`. Dark mode: `light-dark()` or OKLCH inversion. Contrast ≥4.5:1 per theme, tested independently.
## SEO (15%)
robots.txt, sitemap, canonical, titles 50-60ch, meta 150-160ch, H1, HTTPS, mobile-friendly, JSON-LD. See **seo** skill for templates.
## Best Practices (15%)
HTTPS · no vuln deps (`npm audit`) · CSP headers · DOCTYPE · UTF-8 encoding · clean console (no errors) · contextual permissions · no mixed content · proper redirects (301 not 302) · clean URL structure · no broken links
## Severity: Critical(blockers/a11y) · High(CWV/contrast/CQ misuse) · Medium(perf/SEO/tokens) · Low(minor)
## Cadence: Pre-deploy(CWV/a11y 0/CQ) · Weekly(INP/deps/motion) · Monthly(full Lighthouse/token/theme)
## Targets: Perf≥90 A11y=100 BP≥95 SEO≥95 · Others=checklist
## Frameworks: Next(next/image, lazy, Suspense, VT) · Vue(nuxt/image, async, CQ) · Astro(partial hydration, VT, CQ)

## Workflow
1. **Setup**: Ensure site is running. `npx unlighthouse --site <url>` (site-wide) or `npx lighthouse <page> --view` (per-page)
2. **Scan**: Run full audit → collect scores (Perf/A11y/BP/SEO)
3. **Analyze**: Compare against targets (Perf≥90 A11y=100 BP≥95 SEO≥95)
4. **Prioritize**: Critical → High → Medium → Low (see Severity)
5. **Report**: Use Output Format below → assign fixes

## Output Format
```
AUDIT: <url> — <date>
Scores: Perf=<n> A11y=<n> BP=<n> SEO=<n>

CRITICAL (<target):
- [category] <issue> → <fix>

HIGH:
- [category] <issue> → <fix>

MEDIUM:
- [category] <issue> → <fix>
```

## CI/CD Integration
```yaml
# GitHub Actions (cross-platform, no bc dependency)
- name: Audit
  run: |
    npx unlighthouse --site ${{ vars.SITE_URL }} --reporter json > audit.json
    node -e "const s=JSON.parse(require('fs').readFileSync('audit.json')).categories.performance.score; if(s<0.9){console.error('Perf score '+s+' < 0.9'); process.exit(1)}"
```
**Score scale**: Unlighthouse outputs 0-1 floats. Lighthouse CLI outputs 0-100 integers. Adjust threshold accordingly.
Pre-deploy gate: block on Critical/High. Weekly: track trends.

## Tool Setup
```bash
# Unlighthouse (site-wide) — requires site to be accessible
npm install -g unlighthouse
npx unlighthouse --site https://example.com

# Lighthouse (per-page) — requires page to be accessible
npx lighthouse http://localhost:3000 --view

# axe (a11y) — requires page to be accessible
npx @axe-core/cli http://localhost:3000
```

## Anti-Patterns
Lighthouse once · Skip internal a11y · No anim budget · Mix CQ/MQ without strategy · No token audit · No CI gate · Ignore theme-specific a11y · Audit unreachable site · Confuse Lighthouse/unlighthouse score scales

## Refs: baseline-ui · accessibility · performance · seo · best-practices · ui-engine
