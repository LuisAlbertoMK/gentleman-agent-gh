---
name: web-quality-audit
description: "Comprehensive web audit: performance, a11y, SEO, responsive, animation, design tokens."
triggers: "audit, review web quality, lighthouse, page quality, optimize website, design audit, ui audit, web audit, site review"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1117
---

## When to Use
Full web audit: perf, a11y, SEO, responsive, anim.

**Pre-req**: Target running+accessible. Public URL(no auth/CAPTCHA/WAF).

## Thresholds (value→why)
LCP<2500ms→load p75|CLS<0.1→stability p75|INP<200ms→responsiveness p75|FID<100ms→legacy delay|TBT<200ms→lab INP proxy|FCP<1800ms→first paint|TTFB<800ms→server latency|contrast≥4.5:1→WCAG AA text|touch≥24×24(rec44)→WCAG 2.5.8|anim<200ms/elem→no lag

## Remediation (fail→fix)
LCP>2500→`<link rel=preload as=image href=hero.webp fetchpriority=high>`|CLS>0.1→`img{width:100%;height:auto;aspect-ratio:16/9}`|INP>200→`await scheduler.yield()` in handlers|contrast<4.5→`--text:oklch(0.2 0 0)`

## Categories
Perf(30%): WebP/AVIF, code-split, font-display:swap, preconnect, preload LCP, lazy, scheduler.yield(), transform+opacity
A11y(20%): alt, contrast4.5:1, captions, keyboard, focus2px, skip, touch. EAA2025: theme contrast per variant, reduced-motion, focus all themes. No `dense` on interactive
Responsive(15%): CQ `inline-size`not`size`. `repeat(auto-fit,minmax(280px,1fr))`. `clamp()+vw(page)/cqi(containers)`. Subgrid. MQ=page, CQ=components
Animation(10%): transform+opacity only. 3 easing max. ≤500ms total, <200ms/element. scroll-driven `animation-timeline`. prefers-reduced-motion. No decorative
Design Tokens(10%): OKLCH>HSL/RGB. 8pt. 3-tier(Primitive→Semantic→Component). `clamp()` fluid. `light-dark()`/OKLCH inversion dark. ≥4.5:1 per theme
SEO(15%): robots.txt·sitemap·canonical·title50-60·meta150-160·H1·HTTPS·mobile·JSON-LD. See **seo**
Best Practices(15%): HTTPS·`npm audit`·CSP·DOCTYPE·UTF-8·clean console·contextual permissions·301·no broken links

## Severity: Critical(blockers/a11y)|High(CWV/contrast/CQ)|Med(perf/SEO/tokens)|Low
## Cadence: Pre-deploy CWV/a11y=0/CQ|Weekly INP/deps/motion|Monthly LH/token/theme. Targets: Perf≥90 A11y=100 BP≥95 SEO≥95

## Workflow
1.Setup:`npx unlighthouse --site <url>`(site) or `npx lighthouse <page> --view`(page)
2.Scan→scores 3.Analyze vs thresholds 4.Prioritize by severity 5.Report

## Hard Rules
- Target MUST be running + publicly reachable (no auth/CAPTCHA/WAF) before audit
- Compare EVERY score vs Thresholds table: LCP<2500ms, CLS<0.1, INP<200ms, TTFB<800ms, contrast≥4.5:1, touch≥24×24
- ANY Critical/High → block pre-deploy gate; NEVER ship with a11y failures
- Report MUST use severity buckets (CRITICAL/HIGH/MEDIUM/LOW) + Output format; targets Perf≥90 A11y=100 BP≥95 SEO≥95
- Never audit once — cadence pre-deploy/weekly/monthly; never skip a11y category
- CQ uses `inline-size` (never `size`); MQ=page, CQ=components

## Output
```
AUDIT:<url>—<date> Scores:Perf=<n>A11y=<n>BP=<n>SEO=<n> CRITICAL:[cat]<issue>→<fix> HIGH:... MEDIUM:...
```
## CI/CD
Tools: unlighthouse(site,0-1)|lhci(PR diff,0-100)|web-vitals(RUM p75)
Where: PR job→block Critical/High|pre-deploy→CWV gate|nightly→full audit
```yaml
- run: npx unlighthouse --site ${{vars.SITE_URL}} --reporter json>audit.json && node -e "..."
```

## Anti-Patterns
Lighthouse once·Skip a11y·No anim budget·Mix CQ/MQ without strategy·No token audit·No CI gate·Ignore theme a11y·Audit unreachable·Confuse Lighthouse/unlighthouse scales

## Refs
baseline-ui·accessibility·performance·seo·best-practices·ui-engine

---

## Examples

### Example 1: Pre-Deploy Audit of Staging

**Trigger**: `web audit https://staging.example.com` (frontmatter: audit, web audit, lighthouse, page quality)

```bash
# Workflow step 1: Setup (site scan)
npx unlighthouse --site https://staging.example.com --reporter json > audit.json
```

**Expected output** (Output format, severity-ordered):

```
AUDIT:https://staging.example.com—2026-08-16 Scores:Perf=92 A11y=88 BP=95 SEO=97
CRITICAL:[a11y] contrast 3.1:1 → --text:oklch(0.2 0 0) (≥4.5:1)
HIGH:[perf] LCP=3100ms → <link rel=preload as=image href=hero.webp fetchpriority=high>
MEDIUM:[seo] title 42 chars → 50-60
```

**Result**: CRITICAL/HIGH block pre-deploy (CI/CD gate); targets Perf≥90 A11y=100 BP≥95 SEO≥95.

## Testing

1. **Audit produced** — `npx unlighthouse --site <url> --reporter json`:
   Expected: `audit.json` exists and contains per-category scores.

2. **Threshold compare** — parse scores against the Thresholds table (LCP<2500ms, CLS<0.1, INP<200ms, contrast≥4.5:1):
   ```powershell
   (Get-Content audit.json -Raw | ConvertFrom-Json).categories.performance.score -ge 0.9
   ```
   Expected: `True` (Perf ≥90 target) or a documented fail→fix from Remediation.

3. **Severity buckets** — report lists CRITICAL/HIGH/MEDIUM/LOW; a passing pre-deploy gate shows 0 CRITICAL + 0 HIGH:
   Expected: gate blocks on any CRITICAL/HIGH (CI/CD section).