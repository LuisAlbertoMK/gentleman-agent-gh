---
name: seo
description: "Search engine visibility & ranking — technical SEO, on-page, structured data, E-E-A-T, AI Overviews"
triggers: "seo, search engine, meta tags, structured data, sitemap, search optimization, ranking, schema, robots.txt, meta description, EEAT, E-E-A-T, AI Overview, SGE, AI Mode, generative search, AEO, GEO, INP, Google Core Update, GA4, topical authority, content cluster"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
SEO audit/meta/sitemap/Core Update/AI Overviews/E-E-A-T/CWV/INP. NOT:content writing/link building/PPC/social. Pre-reqs:GSC·PageSpeed·RichResultsTest

## Rules:1.Indexability first|2.Accuracy>completeness—validate|3.No keyword-stuffing/doorways/link-schemes/AI-scaled|4.Snippet=AI eligibility|5.llms.txt/chunking/AEO/GEO debunked

## Tech:Crawlable:robots.txt·sitemap·canonical·noindex staging·HTTPS+HSTS·hyphens·semantic. Crawl budget(>10K):high-value·remove thin·lastmod. Sitemap:`<lastmod>`·50K/50MB·index>1. `Allow:/ Disallow:/admin/ /api/`

## On-Page:Title50-60ch keyword-first|Meta150-160ch CTA|H1:1/primary|H1→H2→H3 answer-first|Images:alt WebP/AVIF srcset lazy|Links:descriptive anchor|URLs:clean hyphens no query
## E-E-A-T:Experience:first-hand/research|Expertise:named authors+bios ProfilePage+Person|Authoritativeness:backlinks press Wikipedia|Trustworthiness:dates corrections contact/privacy/ToS HTTPS
Schema:`{"@context":"https://schema.org","@type":"ProfilePage","mainEntity":{"@type":"Person","name":"...","sameAs":["..."]}}`
## AI Overviews:Win=being cited. 1.Answer-first 40-60w 2.High info gain 3.Clean H2/lists/table 4.Comparison 5.Step-by-step 6.E-E-A-T. Don't:llms.txt·chunking·AI-specific·special schema·inauthentic. Monitor:GSC monthly·CTR↓+impressions↑=impact

## Clusters:Pillar→clusters→entity-rich links

## Structured Data:Org:H|Article:H|Product:H|FAQPage:M|BreadcrumbList:M|ProfilePage+Person:H|LocalBusiness:H|VideoObject:M
Article:JSON-LD: headline+author(Person)+publisher(Org+logo)+datePublished+dateModified+mainEntityOfPage+image. Keep dateModified fresh—AI favors.

## Mobile/SPA:Responsive·viewport·tap≥48px·font≥16px·hreflang+x-default·`<html lang>`·SSR/SSG meta+JSON-LD
## CWV:LCP<2.5s:preconnect preload hero|INP<200ms:scheduler.yield() compositor|CLS<0.1:reserve dims no late DOM

## Cadence:Pre-deploy:index+title+H1+canonical+HTTPS+JSON-LD+robots+sitemap|Monthly:AI+CWV+E-E-A-T+backlinks|Q:clusters+sitemap+Core Update+competitive

## Output:`SEO AUDIT:<url>—<date> CRITICAL:[tech]<issue>→<fix> HIGH:[EEAT|schema|AI]<issue>→<fix> MEDIUM:[clusters|links]<issue>→<fix> AI:Cited:Y/N·GA:<n>/<n>`

## Examples
User: "seo audit https://example.com"
```bash
curl -s https://example.com/robots.txt   # → Allow:/ Disallow:/admin/ /api/
curl -s https://example.com/sitemap.xml | grep -c "<url>"          # → 42 (≤50K, has <lastmod>)
curl -s https://example.com/ | grep -o '<title>[^<]*</title>'      # → 50-60ch keyword-first
curl -sI https://example.com/ | grep -i "strict-transport"         # → HSTS present
```
→ Output: `SEO AUDIT:https://example.com—2026-08-16 CRITICAL:[tech]<issue>→<fix> HIGH:[EEAT|schema|AI]<issue>→<fix> AI:Cited:Y/N GA:<n>/<n>`

## Testing
1. RichResultsTest: paste Article JSON-LD → 0 errors (headline+author Person+publisher Org+logo+datePublished+dateModified+mainEntityOfPage+image)
2. GSC: post-deploy → URL "Submitted and indexed" (not excluded); monthly: CTR↓ + impressions↑ = AI impact
3. Sitemap: `grep -c "<lastmod>"` == `<url>` count; ≤50K URLs / ≤50MB

## Anti-Patterns
Keyword-stuff·Dup titles·No schema·Skip mobile·Missing robots/sitemap·Article JSON-LD incomplete·Mass AI·No E-E-A-T·llms.txt for AI·Thin affiliate·No monitor·Rankings only·Fake schema

## Refs:web-quality-audit·performance·baseline-ui·docs-audit
