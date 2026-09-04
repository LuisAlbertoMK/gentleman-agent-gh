---
name: seo
description: "Search engine visibility & ranking — technical SEO, on-page, structured data, E-E-A-T, AI Overviews"
triggers: "seo, search engine, meta tags, structured data, sitemap, search optimization, ranking, schema, robots.txt, meta description, EEAT, E-E-A-T, AI Overview, SGE, AI Mode, generative search, AEO, GEO, Google Core Update, GA4, topical authority, content cluster"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2928
---
## When to Use
SEO audit/meta/sitemap/Core Update/AI Overviews/E-E-A-T/CWV/INP. NOT: content/link building/PPC/social. Pre-reqs: GSC·PageSpeed·RichResultsTest.
## Rules
1. Indexability first | 2. Accuracy>completeness—validate | 3. No keyword-stuffing/doorways/link-schemes/AI-scaled | 4. Snippet=AI eligibility | 5. llms.txt/chunking/AEO/GEO debunked.
## Tech
Crawlable: robots.txt·sitemap·canonical·noindex staging·HTTPS+HSTS·hyphens·semantic. Crawl budget(>10K): high-value·remove thin·lastmod. Sitemap: `<lastmod>`·50K/50MB·index>1.
## On-Page
Title 50-60ch keyword-first | Meta 150-160ch CTA | H1: 1/primary | H1→H2→H3 answer-first | Images: alt+WebP+srcset | Links: descriptive anchor | URLs: clean hyphens no query.
## E-E-A-T + AI Overviews (summary)
Win=cited. Answer-first 40-60w + info gain + clean H2/lists + comparison + steps + E-E-A-T signals. Detalles completos → reference.md
## Output
`SEO AUDIT:<url>—<date> CRITICAL:[tech]<issue>→<fix> HIGH:[EEAT|schema|AI]<issue>→<fix> MEDIUM:[clusters|links]<issue>→<fix> AI:Cited:Y/N·GA:<n>/<n>`
## Anti-Patterns
Keyword-stuff·Dup titles·No schema·Skip mobile·Missing robots/sitemap·Incomplete JSON-LD·Mass AI·No E-E-A-T·Thin affiliate·No monitor·Fake schema
## Examples
Audit: `/seo https://example.com/blog` → `SEO-AUDIT:... CRITICAL:[title,canonical]→ HIGH:[sitemap]→ VERIFY:[GSC]` · Schema → reference.md
## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "SEO can wait" | No structured data / E-E-A-T | seo checklist + Lighthouse SEO audit |
| "E-E-A-T es solo para YMYL" | Autor anónimo, sin ProfilePage/Person | ProfilePage+Person sameAs + RichResultsTest |
| "AI Overviews es hype" | Sin answer-first ni info gain | Answer-first 40-60w + tablas/listas + GSC CTR/impressions |
## Red Flags
- No structured data / E-E-A-T → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone
## Verification
- seo checklist + Lighthouse SEO
- cross-ref-check.ps1 → SKILL.md OK
## Cross-Refs: web-quality-audit | performance | baseline-ui | docs-audit
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-048).
Consult these when the skill needs detailed worked examples or guardrails:

- **E-E-A-T, Structured Data, Mobile/SPA, Cadence, AI Overviews detail**
  → docs/skills/seo/reference.md

---
