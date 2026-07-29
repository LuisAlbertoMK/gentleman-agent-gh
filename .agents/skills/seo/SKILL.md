---
name: seo
description: "Search engine visibility & ranking — technical SEO, on-page, structured data, E-E-A-T, AI Overviews"
triggers: "seo, search engine, meta tags, structured data, sitemap, search optimization, ranking, schema, robots.txt, meta description, EEAT, E-E-A-T, AI Overview, SGE, AI Mode, generative search, AEO, GEO, INP, Google Core Update, GA4, topical authority, content cluster"
license: MIT
metadata:
  tags: [growth]
  author: web-quality-skills + gentleman-vMK
  version: "3.1"
  changelog: "3.1: Compressed ~50% (Karpathy), all content preserved. 3.0: AI Overviews/SGE/AI Mode, E-E-A-T, INP, ProfilePage schema, llms.txt corrected per Google 2026 guide."
---

**WHEN**: SEO audit, meta/review, structured data, sitemap/robots.txt, ranking, Core Update response, AI Overviews, E-E-A-T, content clusters, CWV/INP.  
**WHEN NOT**: Content writing, link building execution, PPC, social media.

**Pre-reqs**: Target site public · For AI Overviews: GSC Generative AI report · For CWV: PageSpeed Insights · For schema: [Rich Results Test](https://search.google.com/test/rich-results)

## Hard Rules
1. **Indexability first** — no optimization matters if unindexed.
2. **Accuracy > completeness** — wrong structured data > missing. Validate.
3. **SEO ≠ manipulation** — no keyword-stuffing, doorways, link schemes, scaled AI content.
4. **Snippet eligibility = AI eligibility** — uncitable if no snippet.
5. **Cite Google's stance** — llms.txt, chunking, AEO/GEO debunked per Google (June 2026).

## Technical SEO
**Crawlability**: valid robots.txt · XML sitemap in GSC · canonical · noindex staging/dupes · HTTPS+HSTS · hyphens · semantic HTML.  
**Crawl budget** (>10K URLs): prioritize high-value sitemap entries, remove thin/duplicate, accurate lastmod.  
**Sitemap**: `<lastmod>` recommended · 50K URLs/50MB · index for >1 file.

robots.txt: `Allow: /` · `Disallow: /admin/ /api/` · `Sitemap: https://example.com/sitemap.xml`

## On-Page SEO (checklist)
| Field | Rule |
|-------|------|
| Title | 50-60ch, keyword-first, unique |
| Meta desc | 150-160ch, CTA, unique |
| H1 | One per page, primary keyword |
| Structure | H1→H2→H3 logical, answer-first (40-60 word direct answer) |
| Images | alt text, WebP/AVIF, responsive srcset, lazy-load |
| Internal links | Descriptive anchor, entity-rich, contextual |
| URLs | Clean, hyphens, no query params for content |

## E-E-A-T Framework
| Pillar | Signals |
|--------|---------|
| **Experience** | First-hand usage, case studies, original research, proprietary data |
| **Expertise** | Named authors + bios, ProfilePage+Person schema, depth a novice couldn't produce |
| **Authoritativeness** | Backlinks from authoritative sites, brand mentions, 3rd-party reviews, press, Wikipedia |
| **Trustworthiness** | Publish+update dates visible, corrections acknowledged, contact+privacy+ToS, HTTPS, editorial policy |

Schema: `{"@context":"https://schema.org","@type":"ProfilePage","mainEntity":{"@type":"Person","name":"Author Name","sameAs":["https://linkedin.com/in/..."]}}`

## AI Overviews / SGE / AI Mode
Google AI answers via RAG. **Win = being the cited source**, not ranking #1.

### Optimization (priority order)
1. **Answer-first**: 40-60 word direct answer, then expand
2. **High information gain**: original data, expert quotes, proprietary insights
3. **Clean structure**: H2/H3, short paragraphs, lists, semantic <table>
4. **Comparison tables** — AI Overviews imports them
5. **Step-by-step**: numbered lists for "how to"
6. **E-E-A-T**: named authors, credentials, verifiable data

### Don't (per Google)
❌ llms.txt · Content chunking · AI-specific writing · Special AI schema · Inauthentic mentions

### Monitoring
- **GSC**: Generative AI performance report
- **Manual**: monthly 20-30 queries, log citations
- **Divergence signal**: impressions up + CTR down = AI Overview impact

## Content Clusters & Topical Authority
| Component | Role |
|-----------|------|
| **Pillar page** | Broad guide → links to clusters |
| **Cluster articles** | Deep dives, link back to pillar + related clusters |
| **Entity-rich links** | Descriptive anchors defining relationships |

## Structured Data (JSON-LD)
| Type | Where | Priority |
|------|-------|----------|
| Organization | Homepage | High |
| Article | Blog posts | High |
| Product | Product pages | High |
| FAQPage | FAQ sections | Medium |
| BreadcrumbList | All pages | Medium |
| ProfilePage+Person | Author pages (E-E-A-T) | **High** |
| LocalBusiness | Local | High |
| VideoObject | Video | Medium |

Article (required): `{"@context":"https://schema.org","@type":"Article","headline":"...","author":{"@type":"Person","name":"..."},"publisher":{"@type":"Organization","name":"...","logo":{"@type":"ImageObject","url":"..."}},"datePublished":"...","dateModified":"...","mainEntityOfPage":{"@type":"WebPage","@id":"..."},"image":"..."}`

**Keep dateModified current** — AI engines favor fresh sources.

## Mobile / International / SPA
Responsive · viewport · tap ≥48px · font ≥16px · hreflang (+ x-default) · `<html lang="...">` · SSR/SSG for meta/JSON-LD

hreflang: `<link rel="alternate" hreflang="en" href="...">` + es + x-default

## Core Web Vitals
| Metric | Target | Key Fixes |
|--------|--------|-----------|
| **LCP** | < 2.5s | preconnect CDN, preload hero, code-split |
| **INP** | < 200ms | scheduler.yield(), compositor-only anim |
| **CLS** | < 0.1 | reserve ad/image dims, no late DOM insert |

## Audit Cadence
**Pre-deploy**: indexable · title+meta · H1 · canonical · HTTPS · valid JSON-LD · robots.txt+sitemap  
**Monthly**: AI Overviews visibility · CWV passing · E-E-A-T signals current · freshness · backlinks  
**Quarterly**: content cluster audit · sitemap accuracy · Core Update response · competitive gap

## Output Format
```
SEO AUDIT: <url> — <date>
CRITICAL: [tech] <issue> → <fix>
HIGH: [EEAT|schema|AI Overviews] <issue> → <fix>
MEDIUM: [clusters|links] <issue> → <fix>
AI VISIBILITY: Cited: Yes/No · Generative AI clicks/impressions: <n>/<n>
```

## Anti-Patterns
Keyword-stuff · Duplicate titles · Ignore structured data · Skip mobile · Missing robots.txt/sitemap · Article JSON-LD missing publisher/dateModified · **Mass-produced AI content** · **Ignoring E-E-A-T** · **llms.txt for AI Overviews** · **Thin affiliate** · **No monitoring** · **Measuring rankings only, not AI citations** · **Fake schema**

## Refs
web-quality-audit · performance · baseline-ui · docs-audit · Google AI guide · Search Console Generative AI report
