---
name: seo
description: "Search engine visibility & ranking — technical SEO, on-page, structured data, E-E-A-T, AI Overviews"
triggers: "seo, search engine, meta tags, structured data, sitemap, search optimization, ranking, schema, robots.txt, meta description, EEAT, E-E-A-T, AI Overview, SGE, AI Mode, generative search, AEO, GEO, INP, Google Core Update, GA4, topical authority, content cluster"
license: MIT
metadata:
  tags: [growth]
  author: web-quality-skills + gentleman-vMK
  version: "3.0"
  changelog: "3.0: AI Overviews/SGE/AI Mode, E-E-A-T framework, INP (replaces FID), ProfilePage schema, Content clusters, llms.txt corrected per Google 2026 guide, modern skill structure. 2.1: Breaker fixes. 2.0: Code examples, LLM guidance"
---

## Activation Contract

**WHEN**: SEO audit, meta/review, structured data setup, sitemap/robots.txt, ranking investigation, Google Core Update response, AI Overviews visibility check, E-E-A-T assessment, content cluster planning, CWV/INP analysis.

**WHEN NOT**: Content writing (create the content, then audit SEO), link building execution (evaluate existing links only), PPC/paid search, social media strategy.

## Prerequisites

- Target site running and publicly accessible (no auth/CAPTCHA/WAF).
- For AI Overviews: Google Search Console access (Generative AI report).
- For CWV: PageSpeed Insights URL or CrUX data.
- For schema: [Rich Results Test](https://search.google.com/test/rich-results).

## Hard Rules

1. **Indexability first.** No optimization matters if the page isn't indexed.
2. **Accuracy before completeness.** Wrong structured data > missing data. Validate.
3. **SEO ≠ manipulation.** No keyword-stuffing, doorway pages, link schemes, scaled AI content.
4. **Snippet eligibility = AI eligibility.** Can't be cited if no snippet.
5. **Cite Google's official stance.** llms.txt, chunking, AEO/GEO claims — Google (June 2026) debunked them.

## Technical SEO

**Crawlability**: valid robots.txt · XML sitemap in GSC · canonical URLs · 
oindex only staging/dupes · HTTPS+HSTS · hyphen URLs · semantic HTML.

**Crawl budget** (>10K URLs): prioritize high-value pages in sitemap, remove thin/duplicate, accurate lastmod.

**Sitemap**: <lastmod> recommended · <changefreq>/<priority> optional · 50K URLs/50MB per file · sitemap index for >1.

### robots.txt
`
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /api/
Sitemap: https://example.com/sitemap.xml
`

### sitemap.xml
`xml
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://example.com/</loc><lastmod>2026-07-18</lastmod></url>
</urlset>
`

## On-page SEO

**Title**: 50-60ch, keyword-first, unique.
**Meta desc**: 150-160ch, CTA, unique.
**H1**: one per page, primary keyword.
**Heading hierarchy**: H1→H2→H3 logical.
**Content**: answer-first — open with 40-60 word direct answer, then expand.
**Images**: alt text descriptive, WebP/AVIF, responsive (srcset), lazy-load below fold.
**Internal links**: descriptive anchor, entity-rich, contextual.
**URLs**: clean, hyphen-separated, no query params for content.

## E-E-A-T (Experience, Expertise, Authoritativeness, Trustworthiness)

Google's quality framework — also the filter AI engines use to select citations.

### Experience
- First-hand usage, case studies, original research, proprietary data.

### Expertise
- Named authors with credentials, author bios on every article.
- Author schema (ProfilePage + Person with sameAs).
- Content depth a novice couldn't produce.

### Authoritativeness
- Backlinks from authoritative sites, brand mentions (linked + unlinked).
- Third-party reviews (Trustpilot, G2, Capterra).
- Press, guest posts, podcast appearances.
- Wikipedia/Wikidata (when eligible).

### Trustworthiness
- Publish + last-updated date visible on every article.
- Corrections acknowledged, clear contact info, privacy policy, ToS.
- HTTPS, no deceptive patterns, editorial policy.

### Schema for E-E-A-T
`json
{"@context":"https://schema.org","@type":"ProfilePage","mainEntity":{"@type":"Person","name":"Author Name","sameAs":["https://linkedin.com/in/..."]}}
`

## AI Overviews / SGE / AI Mode

Google's AI generates answers via RAG (Retrieval-Augmented Generation). **Win condition: being the cited source**, not ranking #1.

### How it works
- Runs on core ranking + query fan-out.
- Only indexed, snippet-eligible pages qualify.
- Structured data NOT required for AI citation.
- Google: "optimizing for AI = still SEO."

### Optimization (priority order)
1. **Answer-first**: 40-60 word direct answer, then expand.
2. **High information gain**: original data, expert quotes, proprietary insights.
3. **Clean structure**: H2/H3, short paragraphs, lists, semantic tables.
4. **Comparison tables**: semantic <table> — AI Overviews imports them.
5. **Step-by-step**: numbered lists for "how to".
6. **E-E-A-T**: named authors, credentials, verifiable data.

### What NOT to do (per Google)
- ❌ llms.txt — not needed for Google Search AI.
- ❌ Content chunking.
- ❌ AI-specific writing (synonyms work fine).
- ❌ Special AI schema markup.
- ❌ Inauthentic mentions.

### Monitoring AI visibility
- **GSC**: Generative AI performance report.
- **Manual spot checks**: monthly, 20-30 queries, log citations.
- **CTR vs impressions divergence**: impressions up + CTR down = AI Overview impact.

## Content Clusters & Topical Authority

| Component | Description |
|-----------|-------------|
| **Pillar page** | Broad guide, links to all clusters |
| **Cluster articles** | Deep dives on sub-topics, link back to pillar |
| **Entity-rich internal links** | Descriptive anchors defining relationships |
| **Cross-linking** | Clusters link to pillar AND related clusters |

## Structured Data (JSON-LD)

| Type | Where | Priority |
|------|-------|----------|
| Organization | Homepage | High |
| Article | Blog posts | High |
| Product | Product pages | High |
| FAQPage | FAQ sections | Medium |
| BreadcrumbList | All pages | Medium |
| ProfilePage + Person | Author pages (E-E-A-T) | **High** |
| LocalBusiness | Local pages | High |
| VideoObject | Video content | Medium |

### Article (Google-required fields)
`json
{"@context":"https://schema.org","@type":"Article","headline":"Title","author":{"@type":"Person","name":"Author"},"publisher":{"@type":"Organization","name":"Org","logo":{"@type":"ImageObject","url":"https://example.com/logo.png"}},"datePublished":"2026-07-18","dateModified":"2026-07-18","mainEntityOfPage":{"@type":"WebPage","@id":"https://example.com/art"},"image":"https://example.com/img.jpg"}
`

**Keep dateModified current** — AI engines favor fresh sources.

## Mobile / International / SPA

Responsive · <meta name="viewport"> · tap ≥48px · font ≥16px · hreflang (+ x-default) · <html lang="..."> · SSR/SSG for meta/JSON-LD.

**hreflang**:
`html
<link rel="alternate" hreflang="en" href="https://example.com/">
<link rel="alternate" hreflang="es" href="https://example.com/es/">
<link rel="alternate" hreflang="x-default" href="https://example.com/">
`

## Core Web Vitals

| Metric | Target | Replaced | Key Fixes |
|--------|--------|----------|-----------|
| **LCP** | < 2.5s | — | preconnect CDN, preload hero, code-split |
| **INP** | < 200ms | FID (Mar 2024) | scheduler.yield(), compositor-only anim |
| **CLS** | < 0.1 | — | reserve ad/image dims, no late DOM insert |

## Audit Cadence

### Pre-deploy (required)
1. Indexable · 2. Unique title + meta desc · 3. One H1 · 4. Canonical · 5. HTTPS+HSTS · 6. Valid JSON-LD · 7. robots.txt + sitemap

### Monthly
- AI Overviews visibility (GSC report + spot checks)
- CWV passing (INP, LCP, CLS)
- E-E-A-T signals current (author pages, schema valid)
- Content freshness (update dateModified, refresh stale)
- Backlink profile check

### Quarterly
- Content cluster audit (pillar + cluster links intact)
- Sitemap accuracy (no 404s, no redirect chains)
- Core Update response analysis
- Competitive gap analysis

## Tool Setup
`ash
npx lighthouse https://example.com --view
# Rich Results Test: https://search.google.com/test/rich-results
# GSC URL Inspection: Search Console → URL Inspection
`

## Output Format
`
SEO AUDIT: <url> — <date>

CRITICAL:
- [tech] <issue> → <fix>

HIGH:
- [EEAT] <issue> → <fix>
- [schema] <issue> → <fix>
- [AI Overviews] <issue> → <fix>

MEDIUM:
- [clusters] <issue> → <fix>
- [links] <issue> → <fix>

AI VISIBILITY:
- Cited in AI Overviews: Yes/No
- Generative AI clicks/impressions: <n>/<n>
`

## Anti-Patterns

Keyword-stuff · Duplicate titles · Ignore structured data · Skip mobile · Missing robots.txt/sitemap · Article JSON-LD missing publisher/dateModified · **Mass-produced AI content** (scaled abuse) · **Ignoring E-E-A-T** · **llms.txt for AI Overviews** (unnecessary per Google) · **Thin affiliate** · **No monitoring cadence** · **Measuring rankings only, not AI citations** · **Fake schema** (marking invisible content)

## Refs

web-quality-audit · performance · aseline-ui · docs-audit · Google AI guide · Search Console Generative AI report
