---
name: web-quality-audit
description: "Comprehensive web audit: performance, a11y, SEO, responsive, animation, design tokens."
triggers: "audit, review web quality, lighthouse, page quality, optimize website, design audit, ui audit, web audit, site review"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1117
---

## When to Use
Full web audit: perf, a11y, SEO, responsive, anim. **Pre-req**: Target running+accessible. Public URL (no auth/CAPTCHA/WAF).

## Thresholds (value→why)
LCP<2500ms→load p75|CLS<0.1→stability p75|INP<200ms→responsiveness p75|FID<100ms→legacy delay|TBT<200ms→lab INP proxy|FCP<1800ms→first paint|TTFB<800ms→server latency|contrast≥4.5:1→WCAG AA text|touch≥24×24(rec44)→WCAG 2.5.8|anim<200ms/elem→no lag

## Remediation (fail→fix)
LCP>2500→`<link rel=preload as=image href=hero.webp fetchpriority=high>`|CLS>0.1→`img{width:100%;height:auto;aspect-ratio:16/9}`|INP>200→`await scheduler.yield()` in handlers|contrast<4.5→`--text:oklch(0.2 0 0)`

## Categories
Perf(30%): WebP/AVIF, code-split, font-display:swap, preconnect, preload LCP, lazy, scheduler.yield(), transform+opacity
A11y(20%): alt, contrast4.5:1, captions, keyboard, focus2px, skip, touch. EAA2025: theme contrast per variant, reduced-motion, focus all themes. No `dense` on interactive
Responsive(15%): CQ `inline-size` not `size`; `repeat(auto-fit,minmax(280px,1fr))`; `clamp()`+vw(page)/cqi(containers); Subgrid; MQ=page, CQ=components
Animation(10%): transform+opacity only; 3 easing max; ≤500ms total, <200ms/element; scroll-driven `animation-timeline`; prefers-reduced-motion; no decorative
Design Tokens(10%): OKLCH>HSL/RGB; 8pt; 3-tier (Primitive→Semantic→Component); `clamp()` fluid; `light-dark()`/OKLCH inversion dark; ≥4.5:1 per theme
SEO(15%): robots.txt·sitemap·canonical·title50-60·meta150-160·H1·HTTPS·mobile·JSON-LD. See **seo**
Best Practices(15%): HTTPS·`npm audit`·CSP·DOCTYPE·UTF-8·clean console·contextual permissions·301·no broken links

## Severity
Critical(blockers/a11y)|High(CWV/contrast/CQ)|Med(perf/SEO/tokens)|Low
## Cadence
Pre-deploy CWV/a11y=0/CQ|Weekly INP/deps/motion|Monthly LH/token/theme. Targets: Perf≥90 A11y=100 BP≥95 SEO≥95

## Hard Rules
- Target MUST be running + publicly reachable (no auth/CAPTCHA/WAF)
- Compare EVERY score vs Thresholds table
- ANY Critical/High → block pre-deploy gate; NEVER ship with a11y failures
- Report MUST use severity buckets + Output format; targets Perf≥90 A11y=100 BP≥95 SEO≥95
- CQ uses `inline-size` (never `size`); MQ=page, CQ=components

## Output
`AUDIT:<url>—<date> Scores:Perf=<n>A11y=<n>BP=<n>SEO=<n> CRITICAL:[cat]<issue>→<fix> HIGH:... MEDIUM:...`

## Anti-Patterns
Lighthouse once·Skip a11y·No anim budget·Mix CQ/MQ without strategy·No token audit·No CI gate·Ignore theme a11y·Audit unreachable·Confuse Lighthouse/unlighthouse scales

## Cross-Refs: baseline-ui | accessibility | performance | seo | best-practices | ui-engine