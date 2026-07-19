---
name: seo
description: "Search engine visibility & ranking — technical SEO, on-page, structured data"
triggers: "seo, search engine, meta tags, structured data, sitemap, search optimization, ranking, schema, robots.txt, meta description"
license: MIT
metadata:
  tags: [growth]
  author: web-quality-skills
  version: "2.1"
  changelog: "2.1: Breaker fixes — Article template complete, FAQ/Breadcrumb templates added, sitemap contradiction fixed, unauditable fundamentals clarified. 2.0: Added code examples, LLM guidance"
---
## Fundamentals (auditable by LLM)
**Can audit**: CWV(Lighthouse) · Mobile-friendly(viewport) · Structured data(JSON-LD) · Title/meta/H1(on-page) · HTTPS · Canonical URLs · Sitemap/robots.txt
**Cannot audit** (needs human/third-party): Content relevance · Backlinks · Domain authority · Keyword optimization

## Technical
**Crawlability**: valid robots.txt · XML sitemap in Search Console · canonical URLs · `noindex` only staging/dupes · HTTPS+HSTS · hyphen URLs
**Sitemap**: `<lastmod>` recommended, `<changefreq>`/`<priority>` optional (not deprecated, just less important) · 50K URLs/50MB per file · sitemap index for >1

### robots.txt Template
```
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /api/

Sitemap: https://example.com/sitemap.xml
```

### sitemap.xml Template
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2026-07-18</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
</urlset>
```

## On-page
Title 50-60ch keyword-first · Meta desc 150-160ch CTA · H1 primary keyword · Logical H1→H2→H3 · Alt text descriptive · Internal links descriptive anchor

## Structured Data (JSON-LD)
Organization→Home · Article→Blog · Product→Product · FAQ→FAQ · BreadcrumbList→All

### Organization Template
```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Company Name",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "sameAs": ["https://twitter.com/company"]
}
```

### Article Template (Google-required fields)
```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Article Title",
  "author": {"@type": "Person", "name": "Author"},
  "publisher": {"@type": "Organization", "name": "Org", "logo": {"@type": "ImageObject", "url": "https://example.com/logo.png"}},
  "datePublished": "2026-07-18",
  "dateModified": "2026-07-18",
  "mainEntityOfPage": {"@type": "WebPage", "@id": "https://example.com/article"},
  "image": "https://example.com/article-image.jpg"
}
```

### FAQ Template
```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "Question text?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Answer text."
      }
    }
  ]
}
```

### BreadcrumbList Template
```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {"@type": "ListItem", "position": 1, "name": "Home", "item": "https://example.com"},
    {"@type": "ListItem", "position": 2, "name": "Category", "item": "https://example.com/category"}
  ]
}
```

Validate: [Rich Results Test](https://search.google.com/test/rich-results)
## Mobile: Responsive · `<meta name="viewport">` · tap ≥48px · font ≥16px
## International: `hreflang` · `<html lang="...">` · `<span lang="...">` for inline
## AI: `llms.txt` — emerging convention, no formal spec yet. Place at root: `https://example.com/llms.txt` with site description and key pages.
## SPA Note: For SPAs, ensure meta tags and JSON-LD are rendered server-side (SSR/SSG). Client-only rendering is invisible to crawlers.

## Audit
**Critical**: indexable · unique title · meta desc · H1 · canonical · HTTPS
**High**: structured data valid · sitemap submitted · robots.txt OK · alt text · internal links · clean URLs
**Medium**: heading hierarchy · OG+Twitter cards · mobile-friendly · tap ≥48px · hreflang · CWV · `llms.txt`
## Tools: Google Search Console · [Rich Results Test](https://search.google.com/test/rich-results) · Screaming Frog · Ahrefs/SEMrush · PageSpeed Insights
## AUDIT ORDER
1. Check indexable + title + meta desc + H1 (critical)
2. Validate structured data (JSON-LD via Rich Results Test)
3. Verify sitemap + robots.txt
4. Run Lighthouse for CWV
5. Check mobile-friendliness
6. Review internal linking structure

## LLM Guidance
When SEO skill activates:
1. **First**: Check `robots.txt` and `sitemap.xml` exist and are valid
2. **Then**: Validate structured data (JSON-LD) on key pages
3. **Then**: Check title/meta/H1 on all pages
4. **Finally**: Run CWV audit (Lighthouse/PageSpeed)
Output: Use AUDIT ORDER format, report by severity

## Refs
web-quality-audit · performance · best-practices · research · accessibility

## Anti-Patterns
Keyword-stuff · Duplicate titles across pages · Ignore structured data · Skip mobile check · Submit without validation · Missing robots.txt · No sitemap · Article JSON-LD missing publisher/dateModified
