---
name: seo
description: "Search engine visibility & ranking — technical SEO, on-page, structured data"
triggers: "seo, search engine, meta tags, structured data, sitemap, search optimization"
license: MIT
metadata:
  tags: [growth]
  author: web-quality-skills
  version: "1.3"
  changelog: "1.3: karpathy compress"
---
## Fundamentals: Content relevance(High) · CWV(High) · Mobile-friendly(High) · Backlinks(Medium) · Structured data(Medium) · Keyword opt(Medium) · Domain authority(Medium)
## Technical
**Crawlability**: valid robots.txt · XML sitemap in Search Console · canonical URLs · `noindex` only staging/dupes · HTTPS+HSTS · hyphen URLs
**Sitemap**: `<lastmod>` over `<changefreq>`/`<priority>` · 50K URLs/50MB per file · sitemap index for >1
## On-page
Title 50-60ch keyword-first · Meta desc 150-160ch CTA · H1 primary keyword · Logical H1→H2→H3 · Alt text descriptive · Internal links descriptive anchor
## Structured Data (JSON-LD)
Organization→Home · Article→Blog · Product→Product · FAQ→FAQ · BreadcrumbList→All
Validate: [Rich Results Test](https://search.google.com/test/rich-results)
## Mobile: Responsive · `<meta name="viewport">` · tap ≥48px · font ≥16px
## International: `hreflang` · `<html lang="...">` · `<span lang="...">` for inline
## AI: `llms.txt` — emerging LLM crawler convention
## Audit
**Critical**: indexable · unique title · meta desc · H1 · canonical · HTTPS
**High**: structured data valid · sitemap submitted · robots.txt OK · alt text · internal links · clean URLs
**Medium**: heading hierarchy · OG+Twitter cards · mobile-friendly · tap ≥48px · hreflang · CWV · `llms.txt`
## Tools: Google Search Console · [Rich Results Test](https://search.google.com/test/rich-results) · Screaming Frog · Ahrefs/SEMrush · PageSpeed Insights
## Ref: [Google SEO Guide](https://developers.google.com/search/docs/fundamentals/seo-starter-guide) · [Web Audit](../web-quality-audit/SKILL.md)
