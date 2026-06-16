---
name: seo
description: Optimize for search engine visibility and ranking. Use when asked to "improve SEO", "optimize for search", "fix meta tags", "add structured data", "sitemap optimization", or "search engine optimization".
triggers: "seo, search engine, meta tags, structured data, sitemap, search optimization"
license: MIT
metadata:
  tags:
    - growth
  author: web-quality-skills
  version: "1.2"
---
## Fundamentals
| Factor | Influence |
|--------|-----------|
| Content relevance | High |
| CWV | High — ranking since 2021 |
| Mobile-friendliness | High — mobile-first index |
| Backlinks | Medium |
| Structured data | Medium — rich results |
| Keyword opt | Medium — declining |
| Domain authority | Medium |
## Technical SEO
**Crawlability**: valid robots.txt · XML sitemap in Search Console · canonical URLs · `noindex` only staging/duplicates · HTTPS+HSTS · short hyphen-separated URLs
**Sitemap**: `<lastmod>` over `<changefreq>`/`<priority>` (ignored by Google) · 50K URLs/50MB per file · sitemap index for >1
## On-page
| Element | Rule |
|---------|------|
| **Title** | 50-60 chars, primary keyword first, unique |
| **Meta desc** | 150-160 chars, compelling+CTA, unique |
| **H1** | One per page, primary keyword, matches intent |
| **Headings** | Logical H1→H2→H3, no skipping |
| **Alt text** | Descriptive, keyword where natural |
| **Internal links** | Descriptive anchor, not "click here" |
## Structured data (JSON-LD)
| Type | Rich result | Page |
|------|-------------|------|
| Organization | Logo, Knowledge Panel | Home |
| Article | Top stories | Blog |
| Product | Price, reviews | Product |
| FAQ | Expandable Q&A | FAQ |
| BreadcrumbList | Breadcrumb | All |
Validate: [Rich Results Test](https://search.google.com/test/rich-results)
## Mobile SEO
Responsive design · `<meta name="viewport">` · tap targets ≥48px · font ≥16px (prevents iOS zoom)
## International SEO
`hreflang` for language variants · `<html lang="...">` · `<span lang="...">` for inline changes
## AI visibility
`llms.txt` — emerging convention for LLM crawler guidance
## Audit checklist
**Critical**: indexable · unique title 50-60ch · meta desc 150-160ch · H1 w/ keyword · canonical URL · HTTPS
**High**: structured data valid · sitemap submitted · robots.txt OK · alt text · descriptive internal links · clean URLs
**Medium**: heading hierarchy · OG+Twitter cards · mobile-friendly · tap ≥48px · hreflang if multi-lang · CWV passing · `llms.txt`
## Tools
Google Search Console · [Rich Results Test](https://search.google.com/test/rich-results) · Screaming Frog · Ahrefs/SEMrush · PageSpeed Insights
## Refs
[Google SEO Guide](https://developers.google.com/search/docs/fundamentals/seo-starter-guide) · [Search Central](https://developers.google.com/search/blog) · [Web Audit](../web-quality-audit/SKILL.md)