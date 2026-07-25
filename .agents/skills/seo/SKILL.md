---
name: seo
description: "Search engine visibility & ranking — technical SEO, on-page, structured data"
triggers: "seo, search engine, meta tags, structured data, sitemap, search optimization, ranking, schema, robots.txt, meta description"
license: MIT
metadata:
  tags: [growth]
  author: web-quality-skills
  version: "2.1"
  changelog: "2.1: Breaker fixes. 2.0: Code examples, LLM guidance"
---
## Fundamentals
**LLM-auditable**: CWV · Mobile viewport · JSON-LD · Title/meta/H1 · HTTPS · Canonical URLs · Sitemap/robots.txt
**Human-only**: Content relevance · Backlinks · Domain authority · Keyword optimization

## Technical
**Crawlability**: valid robots.txt · XML sitemap in Search Console · canonical URLs · `noindex` staging/dupes only · HTTPS+HSTS · hyphen URLs
**Sitemap**: `<lastmod>` recommended · `<changefreq>`/`<priority>` optional · 50K URLs/50MB per file · sitemap index for >1

### robots.txt
```
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /api/
Sitemap: https://example.com/sitemap.xml
```

### sitemap.xml
```xml
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://example.com/</loc><lastmod>2026-07-18</lastmod><changefreq>weekly</changefreq><priority>1.0</priority></url>
</urlset>
```

## On-page
Title 50-60ch keyword-first · Meta desc 150-160ch CTA · H1 primary keyword · H1→H2→H3 logical · Alt text descriptive · Internal links descriptive anchor

## Structured Data (JSON-LD)
Organization→Home · Article→Blog · Product→Product · FAQ→FAQ · BreadcrumbList→All

### Article (Google-required fields)
```json
{"@context":"https://schema.org","@type":"Article","headline":"Title","author":{"@type":"Person","name":"Author"},"publisher":{"@type":"Organization","name":"Org","logo":{"@type":"ImageObject","url":"https://example.com/logo.png"}},"datePublished":"2026-07-18","dateModified":"2026-07-18","mainEntityOfPage":{"@type":"WebPage","@id":"https://example.com/art"},"image":"https://example.com/img.jpg"}
```

Validate: [Rich Results Test](https://search.google.com/test/rich-results)

## Mobile / International / SPA / AI
Responsive · `<meta name="viewport">` · tap ≥48px · font ≥16px · `hreflang` · `<html lang="...">` · SSR/SSG for meta/JSON-LD (client-only = invisible) · `llms.txt` at root (emerging, no spec)

## Audit (in order)
1. **Critical**: indexable · unique title · meta desc · H1 · canonical · HTTPS
2. **Validate**: structured data (JSON-LD via Rich Results Test)
3. **Verify**: sitemap submitted · robots.txt OK
4. **Performance**: CWV (Lighthouse/PageSpeed) · mobile-friendly
5. **Quality**: heading hierarchy · OG+Twitter cards · alt text · internal links · tap ≥48px · hreflang · `llms.txt`

## Tools
Google Search Console · [Rich Results Test](https://search.google.com/test/rich-results) · Screaming Frog · Ahrefs/SEMrush · PageSpeed Insights

## Anti-Patterns
Keyword-stuff · Duplicate titles · Ignore structured data · Skip mobile check · Submit without validation · Missing robots.txt/sitemap · Article JSON-LD missing publisher/dateModified
