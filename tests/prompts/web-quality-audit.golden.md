# web-quality-audit golden prompt

## Skill
web-quality-audit (comprehensive: perf, a11y, SEO, responsive, animation, tokens)

## Trigger
audit, lighthouse, page quality, design audit, ui audit, web audit

## Input
Full web quality audit of https://app.ejemplo.com: LCP 3.4s, color contrast 3.1:1, missing meta title.

## Expected Output
AUDIT:https://app.ejemplo.com--2026-08-21 Scores:Perf=42 A11y=68 BP=91 SEO=73 CRITICAL:[perf]LCP 3.4s->preloads+img-cdn HIGH:[a11y]contrast 3.1->oklch

## Assertion
- Response matches AUDIT:<url>--<date> Scores:<n>x4> contract
- Catches: Lighthouse score gaps plus CRITICAL and HIGH issue-fix pairs
- Within token_budget 1900
