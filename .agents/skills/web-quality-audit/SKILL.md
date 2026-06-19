---
name: web-quality-audit
description: Comprehensive web quality audit covering performance, accessibility, SEO, and best practices.
triggers: "audit, review web quality, lighthouse, page quality, optimize website"
license: MIT
metadata:
  tags:
    - engineering
  author: web-quality-skills
  version: "1.1"
---
# Web quality audit — 150+ checks: Perf, A11y, SEO, Best Practices
Note: Lighthouse v13 (Oct 2025+). Perf migrated to Performance Insight Audits. FMP/NoDocWrite/PassiveListeners removed/merged. CLS->cls-culprits-insight. Images->image-delivery-insight.
## Performance (40% of issues)
CWV: LCP<2.5s | INP<200ms | CLS<0.1. Resources: WebP/AVIF, code-split, critical CSS inline, font-display:swap. Loading: Preconnect, preload LCP/fonts, lazy-below-fold, immutable cache.
## A11y (30%)
Perceivable: alt text, contrast 4.5:1/3:1, captions. Operable: Keyboard, focus visible, skip links. Understandable: lang, consistent nav, form labels+errors. Robust: Valid HTML, correct ARIA.
## SEO (15%)
Crawlability: robots.txt, sitemap, canonical, no noindex on important. On-page: unique titles(50-60ch), meta desc(150-160ch), H1. Technical: Mobile-friendly, HTTPS, fast, JSON-LD.
## Best Practices (15%)
Security: HTTPS, no vuln deps, CSP, no exposed maps. Standards: No deprecated APIs, DOCTYPE, UTF-8, clean console. UX: No interstitials, contextual permissions.
## Severity: Critical(security/failures->fix now) | High(CWV/a11y barriers->pre-launch) | Medium(perf/SEO->this sprint) | Low(minor->convenient)
## Output: Issues by severity | Category:File:line - Impact+Fix | Summary: Perf/N A11y/N SEO/N BestPrac/N | Priority: most impactful first
## Quick Checks: Pre-deploy(CWV/a11y 0 errors/HTTPS/meta) | Weekly(Search Console/CWV/deps/screen reader) | Monthly(full Lighthouse/real a11y/SEO)
## Score targets
Perf >=90 | A11y =100 | BP >=95 | SEO >=95
## Framework patterns
Next: next/image, React.lazy, Suspense for INP
Vue/Nuxt: nuxt/image, async components
Svelte: {#await}, reactive statements
Astro: partial hydration, view transitions
## Site-wide scan
For full-site audit: `npx unlighthouse --site <url>` -- scans all routes with smart sampling
## Refs: Performance | Core Web Vitals | A11y | SEO | Best-Practices skills (../)