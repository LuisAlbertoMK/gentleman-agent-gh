---
name: web-quality-audit
description: Comprehensive web quality audit covering performance, accessibility, SEO, and best practices. Use when asked to "audit my site", "review web quality", "run lighthouse audit", "check page quality", or "optimize my website".
triggers: "audit, review web quality, lighthouse, page quality, optimize website"
license: MIT
metadata:
  tags:
    - engineering
  author: web-quality-skills
  version: "1.1"
---

# Web quality audit

Comprehensive quality audit (150+ checks) across Performance, Accessibility, SEO, Best Practices.

> **Lighthouse v13 (Oct 2025+).** Performance migrated to **Performance Insight Audits**. Individual audits (First Meaningful Paint, No Document Write, Uses Passive Event Listeners, Uses Rel Preload) removed/merged. CLS audits consolidated into `cls-culprits-insight`, image audits into `image-delivery-insight`. Older JSON output is a superset, not a contradiction.

## Audit categories

### Performance — 40% of issues
**Core Web Vitals**: LCP <2.5s · INP <200ms · CLS <0.1
**Resources**: WebP/AVIF images, code-split JS, critical CSS inline, `font-display: swap`
**Loading**: Preconnect origins, preload LCP/fonts, lazy-load below-fold, immutable cache TTLs

### Accessibility — 30% of issues
**Perceivable**: alt text (deco→`alt=""`), color contrast 4.5:1 / 3:1, captions+transcripts
**Operable**: Keyboard nav, focus visible, skip links, no time limits without controls
**Understandable**: `lang` attr, consistent nav, form errors+labels
**Robust**: Valid HTML, correct ARIA (prefer native elements), accessible names+roles

### SEO — 15% of issues
**Crawlability**: robots.txt, XML sitemap, canonical URLs, no noindex on important pages
**On-Page**: Unique titles (50-60ch), meta desc (150-160ch), H1 hierarchy, descriptive link text
**Technical**: Mobile-friendly, HTTPS, fast loading, JSON-LD structured data

### Best practices — 15% of issues
**Security**: HTTPS, no vulnerable deps, CSP headers, no exposed source maps
**Standards**: No deprecated APIs, `<!DOCTYPE html>`, UTF-8 charset, clean console
**UX**: No intrusive interstitials, contextual permission requests, honest buttons

## Severity levels
| Level | Action |
|-------|--------|
| **Critical** | Security vulns, complete failures — fix immediately |
| **High** | CWV failures, major a11y barriers — fix before launch |
| **Medium** | Perf opportunities, SEO improvements — fix within sprint |
| **Low** | Minor optimizations, code quality — fix when convenient |

## Output format
When auditing, structure as:
```markdown
## Audit results
### Critical (X) · High (X) · Medium (X) · Low (X)
- **[Category]** Issue. File: `path:123` — Impact + Fix

### Summary
Perf: X (Y crit) · A11y: X (Y crit) · SEO: X · BestPrac: X

### Priority
1. [most impactful fix first]
```

## Quick checklist
**Pre-deploy**: CWV pass · a11y 0 errors · no console errors · HTTPS · meta tags
**Weekly**: Search Console · CWV trends · deps update · screen reader test
**Monthly**: Full Lighthouse · perf profile · a11y with real users · SEO keywords

## References
- [Perf](../performance/SKILL.md) · [Core Web Vitals](../core-web-vitals/SKILL.md) · [A11y](../accessibility/SKILL.md) · [SEO](../seo/SKILL.md) · [Best Prac](../best-practices/SKILL.md)
