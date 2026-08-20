# seo — Reference Materials

> **Externalized from** .agents/skills/seo/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains structured-data guidance, E-E-A-T detail, mobile/cadence, and validation steps.

## E-E-A-T
Experience: first-hand/research | Expertise: named authors+bios ProfilePage+Person | Authoritativeness: backlinks press Wikipedia | Trustworthiness: dates corrections contact/privacy/ToS HTTPS.

Schema:
```json
{"@context":"https://schema.org","@type":"ProfilePage","mainEntity":{"@type":"Person","name":"...","sameAs":["..."]}}
```

## Structured Data
Org:H|Article:H|Product:H|FAQPage:M|BreadcrumbList:M|ProfilePage+Person:H|LocalBusiness:H|VideoObject:M. Article JSON-LD: headline+author(Person)+publisher(Org+logo)+datePublished+dateModified+mainEntityOfPage+image. Keep dateModified fresh — AI favors.

## Mobile/SPA
Responsive·viewport·tap≥48px·font≥16px·hreflang+x-default·`<html lang>`·SSR/SSG meta+JSON-LD.

## Cadence
Pre-deploy: index+title+H1+canonical+HTTPS+JSON-LD+robots+sitemap | Monthly: AI+CWV+E-E-A-T+backlinks | Quarterly: clusters+sitemap+Core Update+competitive.

## Testing
1. RichResultsTest: Article JSON-LD → 0 errors. 2. GSC post-deploy → "Submitted and indexed"; monthly CTR↓+impressions↑ = AI impact. 3. Sitemap: `grep -c "<lastmod>"` == url count; ≤50K/50MB.