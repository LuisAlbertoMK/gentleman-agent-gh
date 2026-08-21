---
name: web-quality-audit
description: "Comprehensive web audit: performance, a11y, SEO, responsive, animation, design tokens."
triggers: "audit, review web quality, lighthouse, page quality, optimize website, design audit, ui audit, web audit, site review"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1468
---
## When to Use
Full web audit: perf, a11y, SEO, responsive, anim. **Pre-req**: Target running+accessible. Public URL (no auth/CAPTCHA/WAF).
## Severity
Critical(blockers/a11y)|High(CWV/contrast/CQ)|Med(perf/SEO/tokens)|Low
## Cadence
Pre-deploy CWV/a11y=0/CQ|Weekly INP/deps/motion|Monthly LH/token/theme. Targets: Perf≥90 A11y=100 BP≥95 SEO≥95
## Hard Rules
- Target MUST be running + publicly reachable (no auth/CAPTCHA/WAF)
- Compare EVERY score vs Thresholds table
- ANY Critical/High → block pre-deploy gate; NEVER ship with a11y failures
- Report MUST use severity buckets + Output format; targets Perf≥90 A11y=100 BP≥95 SEO≥95
- CQ uses `inline-size` (never `size`); MQ=page, CQ=components
## Output
`AUDIT:<url>—<date> Scores:Perf=<n>A11y=<n>BP=<n>SEO=<n> CRITICAL:[cat]<issue>→<fix> HIGH:... MEDIUM:...`
## Anti-Patterns
Lighthouse once·Skip a11y·No anim budget·Mix CQ/MQ without strategy·No token audit·No CI gate·Ignore theme a11y·Audit unreachable·Confuse Lighthouse/unlighthouse scales
## Cross-Refs: baseline-ui | accessibility | performance | seo | best-practices | ui-engine
> docs/skills/web-quality-audit/reference.md