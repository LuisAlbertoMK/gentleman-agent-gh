---
name: web-quality-audit
description: "Comprehensive web audit: performance, a11y, SEO, responsive, animation, design tokens."
triggers: "audit, review web quality, lighthouse, page quality, optimize website, design audit, ui audit, web audit, site review"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2603
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
## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Audit parcial = audit completo" | Solo Lighthouse Perf sin a11y/SEO | Audit 4 dims: Perf≥90 A11y=100 BP≥95 SEO≥95 + severity buckets |
| "4 dims por separado sin síntesis" | Reportes aislados sin severity | Síntesis `AUDIT:<url> Scores` + CRITICAL/HIGH/MEDIUM + block gate |
| "Target no reachable igual audito" | Audit con auth/CAPTCHA/WAF | Target must running+public reachable; si no → aborta |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Cross-Refs: baseline-ui | accessibility | performance | seo | best-practices | ui-engine
> docs/skills/web-quality-audit/reference.md

## Verification
- Output: response matches the ## Output contract format exactly
- token_budget: total tokens within frontmatter token_budget
- frontmatter: name, description, triggers, token_budget present and stable
- cross-refs: each referenced skill exists
- anti-patterns: none of the listed anti-patterns reintroduced

