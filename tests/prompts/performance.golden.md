# performance golden prompt

## Skill
performance (CWV: LCP, CLS, FCP, TBT, INP; compositor animation; content-visibility)

## Trigger
performance, INP, LCP, CLS, compositor, slow loading, page speed

## Input
Site https://tienda.ejemplo.com reports INP 480ms, LCP 3.2s, CLS 0.25. Optimize within budget INP<200.

## Expected Output
PERF-AUDIT:https://tienda.ejemplo.com--2026-08-21 CRITICAL:[INP]480/200->reduce-JS-inp HIGH:[img|JS]<kb>-><fix> INP:480->reduce/optimize VERIFY:[lighthouse|web-vitals]->PAS

## Assertion
- Response matches PERF-AUDIT:<url>--<date> CRITICAL:[corewebvital]<actual>/<budget>-><fix> contract
- Catches: INP over budget, LCP slow, CLS unstable, JS/font/css bloat
- Within token_budget 2500
