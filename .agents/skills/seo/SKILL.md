---
name: seo
description: "Search engine visibility & ranking — technical SEO, on-page, structured data, E-E-A-T, AI Overviews"
triggers: "seo, search engine, meta tags, structured data, sitemap, search optimization, ranking, schema, robots.txt, meta description, EEAT, E-E-A-T, AI Overview, SGE, AI Mode, generative search, AEO, GEO, Google Core Update, GA4, topical authority, content cluster"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2400
---
## When to Use
SEO audit/meta/sitemap/Core Update/AI Overviews/E-E-A-T/CWV/INP. NOT: content/link building/PPC/social. Pre-reqs: GSC·PageSpeed·RichResultsTest.
## Rules
1. Indexability first | 2. Accuracy>completeness—validate | 3. No keyword-stuffing/doorways/link-schemes/AI-scaled | 4. Snippet=AI eligibility | 5. llms.txt/chunking/AEO/GEO debunked.
## Tech
Crawlable: robots.txt·sitemap·canonical·noindex staging·HTTPS+HSTS·hyphens·semantic. Crawl budget(>10K): high-value·remove thin·lastmod. Sitemap: `<lastmod>`·50K/50MB·index>1.
## On-Page
Title 50-60ch keyword-first | Meta 150-160ch CTA | H1: 1/primary | H1→H2→H3 answer-first | Images: alt+WebP+srcset | Links: descriptive anchor | URLs: clean hyphens no query.
## E-E-A-T
Experience·Expertise·Authoritativeness·Trustworthiness — details + schema in reference.
## AI Overviews
Win = cited. 1. Answer-first 40-60w. 2. Info gain. 3. Clean H2/lists/table. 4. Comparison. 5. Step-by-step. 6. E-E-A-T. Don't: llms.txt·chunking·AI-specific·special schema·inauthentic. Monitor: GSC monthly·CTR↓+impressions↑=impact.
## Output
`SEO AUDIT:<url>—<date> CRITICAL:[tech]<issue>→<fix> HIGH:[EEAT|schema|AI]<issue>→<fix> MEDIUM:[clusters|links]<issue>→<fix> AI:Cited:Y/N·GA:<n>/<n>`
## Anti-Patterns
Keyword-stuff·Dup titles·No schema·Skip mobile·Missing robots/sitemap·Incomplete JSON-LD·Mass AI·No E-E-A-T·Thin affiliate·No monitor·Fake schema
## Cross-Refs: web-quality-audit | performance | baseline-ui | docs-audit
> docs/skills/seo/reference.md

## Verification
- Output: response matches the ## Output contract format exactly
- token_budget: total tokens within frontmatter token_budget
- frontmatter: name, description, triggers, token_budget present and stable
- cross-refs: each referenced skill exists
- anti-patterns: none of the listed anti-patterns reintroduced
