---
name: web-quality-audit
description: "Comprehensive web audit: performance, a11y, SEO, responsive, animation, design tokens."
triggers: "audit, review web quality, lighthouse, page quality, optimize website, design audit, ui audit, web audit, site review"
---
**Pre-req**: Target running+accessible. Public URL(no auth/CAPTCHA/WAF).

## Perf(30%): LCP<2.5s|INP<200ms|CLS<0.1. WebP/AVIF, code-split, font-display:swap, preconnect, preload LCP, lazy. scheduler.yield(), transform+opacity, scroll-driven
## A11y(20%): alt, contrast4.5:1, captions, keyboard, focus2px, skip, touch≥24×24(rec44×44). EAA2025: theme contrast per variant, reduced-motion, focus all themes. No `dense` on interactive
## Responsive(15%): CQ `inline-size`not`size`. `repeat(auto-fit,minmax(280px,1fr))`. `clamp()+vw(page)/cqi(containers)`. Subgrid. MQ=page, CQ=components
## Animation(10%): transform+opacity only. 3 easing max. ≤500ms, <200ms/element. scroll-driven CSS `animation-timeline`. prefers-reduced-motion. No decorative
## Design Tokens(10%): OKLCH>HSL/RGB. 8pt. 3-tier(Primitive→Semantic→Component). `clamp()` fluid. `light-dark()`/OKLCH inversion dark. ≥4.5:1 per theme
## SEO(15%): robots.txt·sitemap·canonical·title50-60·meta150-160·H1·HTTPS·mobile·JSON-LD. See **seo**
## Best Practices(15%): HTTPS·`npm audit`·CSP·DOCTYPE·UTF-8·clean console·contextual permissions·301·no broken links
## Severity: Critical(blockers/a11y)|High(CWV/contrast/CQ)|Medium(perf/SEO/tokens)|Low
## Cadence: Pre-deploy CWV/a11y=0/CQ|Weekly INP/deps/motion|Monthly Lighthouse/token/theme. Targets: Perf≥90 A11y=100 BP≥95 SEO≥95

## Workflow
1.Setup:`npx unlighthouse --site <url>`(site) or `npx lighthouse <page> --view`(page)
2.Scan→scores 3.Analyze vs targets 4.Prioritize:Critical→High→Med→Low 5.Report

## Output
```
AUDIT:<url>—<date> Scores:Perf=<n>A11y=<n>BP=<n>SEO=<n> CRITICAL:[cat]<issue>→<fix> HIGH:... MEDIUM:...
```
## CI/CD
```yaml
- run: npx unlighthouse --site ${{vars.SITE_URL}} --reporter json>audit.json && node -e "..."
```
Scale: Unlighthouse 0-1 floats, Lighthouse 0-100 ints. Pre-deploy:block Critical/High.

## Anti-Patterns
Lighthouse once·Skip a11y·No anim budget·Mix CQ/MQ without strategy·No token audit·No CI gate·Ignore theme a11y·Audit unreachable·Confuse Lighthouse/unlighthouse scales

## Refs
baseline-ui·accessibility·performance·seo·best-practices·ui-engine
