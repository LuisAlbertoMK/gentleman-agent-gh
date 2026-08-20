# Web Quality Audit — Reference

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

## Categories — Detail & Fixes
**Perf(30%)**: WebP/AVIF, code-split, font-display:swap, preconnect, preload LCP, lazy, scheduler.yield(), transform+opacity. Fix LCP>2500 → `<link rel=preload as=image href=hero.webp fetchpriority=high>`; CLS>0.1 → `img{width:100%;height:auto;aspect-ratio:16/9}`; INP>200 → `await scheduler.yield()` in handlers.
**A11y(20%)**: alt, contrast 4.5:1, captions, keyboard, focus 2px, skip, touch. EAA2025: theme contrast per variant, reduced-motion, focus all themes. No `dense` on interactive. Fix contrast<4.5 → `--text:oklch(0.2 0 0)`.
**Responsive(15%)**: CQ `inline-size` not `size`; `repeat(auto-fit,minmax(280px,1fr))`; `clamp()` + vw(page)/cqi(containers); Subgrid; MQ=page, CQ=components.
**Animation(10%)**: transform+opacity only; 3 easing max; ≤500ms total, <200ms/element; scroll-driven `animation-timeline`; prefers-reduced-motion; no decorative.
**Design Tokens(10%)**: OKLCH>HSL/RGB; 8pt; 3-tier (Primitive→Semantic→Component); `clamp()` fluid; `light-dark()`/OKLCH inversion dark; ≥4.5:1 per theme.
**SEO(15%)**: robots.txt·sitemap·canonical·title 50-60·meta 150-160·H1·HTTPS·mobile·JSON-LD. See **seo**.
**Best Practices(15%)**: HTTPS·`npm audit`·CSP·DOCTYPE·UTF-8·clean console·contextual permissions·301·no broken links.

## Externalized Sections (ADR-007 compression)
## Thresholds (value→why)
LCP<2500ms→load p75|CLS<0.1→stability p75|INP<200ms→responsiveness p75|FID<100ms→legacy delay|TBT<200ms→lab INP proxy|FCP<1800ms→first paint|TTFB<800ms→server latency|contrast≥4.5:1→WCAG AA text|touch≥24×24(rec44)→WCAG 2.5.8|anim<200ms/elem→no lag

## Categories
Perf(30%): WebP/AVIF, code-split, font-display:swap, preconnect, preload LCP, lazy, scheduler.yield | A11y(20%): alt, contrast 4.5:1, captions, keyboard, focus 2px, skip, touch; EAA2025 theme contrast + reduced-motion | Responsive(15%): CQ `inline-size`, auto-fit minmax(280px,1fr), clamp(), Subgrid; MQ=page, CQ=components | Animation(10%): transform+opacity, ≤500ms, <200ms/elem, scroll-driven, reduced-motion | Tokens(10%): OKLCH, 8pt, 3-tier, light-dark() | SEO(15%): robots, sitemap, canonical, title 50-60, meta 150-160, H1, JSON-LD → **seo** | Best Practices(15%): HTTPS, npm audit, CSP, DOCTYPE, UTF-8, 301

