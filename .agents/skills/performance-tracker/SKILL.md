---
name: performance-tracker
description: "Score and track app performance — 6 dims, continuous scoring, trend analysis"
triggers: "performance score, mobile perf, desktop perf, rendimiento, app score, benchmark, perf tracking, performance trend"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2200
---
## 6 Dimensions (1-10)
Load|Render|Memory|Network|Bundle|Energy — thresholds → reference.md.

## Score Storage
`mem_save(learning,"perf-score:{app}-{platform}","Load:X|...|Avg:X.X|Platform|App")`. Trend (every 10/session end): `mem_search("perf-score:",20)` → prev5 vs recent5. Drop>0.5→gap-analysis.

## Action by Avg
≥8 Maintain · 6-7.9 Light review+profile · 4-5.9 gap-analysis+fix · <4 Critical sprint

## Hard Rules
- Score EVERY dimension from real measurement — NEVER guess
- Platform in title; NEVER mix platforms in one trend
- Unavailable→neutral 7+annotate; NEVER skip
- Trend only N≥5; regression=drop>0.5→gap-analysis; >0.2→light review
- CI: median-of-3 lighthouse; degrade gracefully on missing process

## Output
`PERF-SCORE:<app>—<date> DIMS:[Load|Render|Memory|Network|Bundle|Energy]=<1-10> AVG=<n.n> PLATFORM:<mob|desk|web> TREND:<delta>→<stable|drift|regression>`

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "score sin 6 dims" | Missing/guessed dimension | Real measurement + neutral 7 if unavailable |
| "trend sin historial" | N<5 trend | mem_save perf-score + mem_search prev5 vs recent5 |
| "mix plataformas" | Cross-platform trend | NEVER mix; median-of-3; regression>0.5→gap-analysis |

## Red Flags
- No baseline measurement → STOP
- Same rationalization 2× → force RED

## Verification
- benchmark-core.ps1 -Gate before/after + cross-ref-check.ps1 → OK
- Output matches ## Output contract exactly; frontmatter (name/description/triggers/token_budget) stable
- token_budget: total tokens within frontmatter token_budget; no anti-patterns reintroduced
- cross-refs: each referenced skill exists

→ docs/skills/performance-tracker/reference.md · Cross-Refs: performance | auto-metrics | perf-profiling
