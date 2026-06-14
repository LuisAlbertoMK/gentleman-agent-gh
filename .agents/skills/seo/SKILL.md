---
name: seo
description: Optimize for search engine visibility and ranking. Use when asked to "improve SEO", "optimize for search", "fix meta tags", "add structured data", "sitemap optimization", or "search engine optimization".
license: MIT
metadata:
  author: web-quality-skills
  version: "1.1"
---

# SEO optimization

Checklist de optimización SEO. Para ejemplos completos (JSON-LD, hreflang, sitemap), ver `references/`.

## SEO fundamentals

| Factor | Influence |
|--------|-----------|
| Content relevance | High — core ranking signal |
| Page speed (Core Web Vitals) | High — ranking factor since 2021 |
| Mobile-friendliness | High — mobile-first indexing |
| Backlinks | Medium — still relevant |
| Structured data | Medium — enables rich results |
| Keyword optimization | Medium — declining but not dead |
| Domain age/authority | Medium — hard to change quickly |
| Social signals | Low — indirect at best |

## Technical SEO

### Crawlability
- `robots.txt` valid, doesn't block important resources
- Sitemap XML submitted to Search Console, lists all important pages
- Canonical URLs to prevent duplicate content
- `noindex` only on staging/duplicate pages (not in sitemap)
- HTTPS required. HSTS: `max-age=31536000; includeSubDomains; preload`
- URL structure: short, descriptive, hyphen-separated (`/products/blue-widget`)

### Sitemap best practices
- `<changefreq>` and `<priority>` ignored by Google (use lastmod)
- Max 50K URLs or 50MB uncompressed per sitemap
- Use sitemap index for >1 sitemap
- See `references/sitemap.xml` for format

## On-page SEO

| Element | Rule |
|---------|------|
| **Title tag** | 50-60 chars, primary keyword first, unique per page |
| **Meta description** | 150-160 chars, compelling + includes CTA, unique |
| **H1** | One per page, includes primary keyword, matches page intent |
| **Headings (H2-H6)** | Logical hierarchy, no skipping levels |
| **Image alt text** | Descriptive, includes keyword where natural |
| **Internal links** | Descriptive anchor text, not "click here" |

## Structured data (JSON-LD)

Critical for rich results. Core schemas:

| Type | Rich result | Typical page |
|------|-------------|-------------|
| Organization | Logo in Search, Knowledge Panel | Homepage |
| Article | Top stories, rich snippet | Blog/news |
| Product | Price, availability, reviews | Product page |
| FAQ | Expandable Q&A | FAQ/help page |
| BreadcrumbList | Breadcrumb in SERP | All pages |

- Validate with [Rich Results Test](https://search.google.com/test/rich-results)
- See `references/structured-data.md` for full JSON-LD examples of all schemas

## Mobile SEO
- Responsive design (no separate mobile site)
- Viewport: `<meta name="viewport" content="width=device-width, initial-scale=1">`
- Tap targets ≥48px (comfortable), Minimum ≥24px (WCAG 2.5.8)
- Font size ≥16px to prevent iOS zoom

## International SEO
- `hreflang` tags for language/regional variations
- `<html lang="...">` for each page. Mark language changes with `<span lang="...">`
- See `references/international-seo.md` for hreflang + lang examples

## AI search visibility (emerging)
- `llms.txt` — emerging convention to guide LLM crawlers. Provide structured page summaries for AI search tools.

## SEO audit checklist

### Critical
- [ ] Indexable: no `noindex` on important pages, page in sitemap
- [ ] Unique, descriptive title tag (50-60 chars)
- [ ] Meta description present and unique (150-160 chars)
- [ ] H1 present, unique, includes primary keyword
- [ ] Canonical URL set, self-referencing
- [ ] HTTPS enforced (no mixed content)

### High
- [ ] Structured data implemented and valid (Rich Results Test)
- [ ] Sitemap submitted to Google Search Console
- [ ] robots.txt valid, not blocking resources
- [ ] Images have descriptive alt text
- [ ] Internal links use descriptive anchor text
- [ ] URLs short and descriptive

### Medium
- [ ] Heading hierarchy logical (H1→H2→H3)
- [ ] Open Graph + Twitter Card meta tags
- [ ] Mobile-friendly (responsive, ≥16px font)
- [ ] Tap targets ≥48px
- [ ] Hreflang if multi-language
- [ ] Core Web Vitals passing
- [ ] `llms.txt` for AI visibility

## Tools

| Tool | Purpose |
|------|---------|
| Google Search Console | Index status, crawl errors, performance |
| Google Rich Results Test | Structured data validation |
| Screaming Frog | Technical crawl audit |
| Ahrefs / SEMrush | Backlink + keyword research |
| PageSpeed Insights | Core Web Vitals + performance |

## References

- [Google SEO Starter Guide](https://developers.google.com/search/docs/fundamentals/seo-starter-guide)
- [Search Central Blog](https://developers.google.com/search/blog)
- [Web Quality Audit](../web-quality-audit/SKILL.md)
