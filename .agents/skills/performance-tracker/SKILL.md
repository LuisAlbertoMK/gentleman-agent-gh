---
name: performance-tracker
description: "Score and track app performance — 6 dims, continuous scoring, trend analysis"
triggers: "performance score, mobile perf, desktop perf, rendimiento, app score, benchmark, perf tracking, performance trend"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 4054
---

## When to Use
Score and track app performance — 6 dims, continuous scoring. Scope: app PERFORMANCE (not agent — use `auto-metrics`). Mobile, Desktop, Web.

## 6 Dimensions (1-10)
| Dim | 9-10 | 7-8 | 5-6 | 3-4 | 1-2 |
|---|---|---|---|---|---|
| **Load** | M<1.5s/D<1s/W LCP<1.5 TTI<2 | <2.5/<2/<2.5/<3.5 | <4/<3.5/<4/<5 | <6/<5/<6/<7 | >6/>5/>6/>7 |
| **Render** | 60fps/0drop/CLS<0.1 INP<200 | 55fps/<2%/<0.25 <350 | 45fps/<5%/<0.5 <500 | 30fps/<10%/<0.75 <700 | <30fps/freeze/>0.75 >700 |
| **Memory** | <50MB/<100/<30 | <100/<200/<60 | <200/<400/<100 | <350/OOM/<800/<200 | >350/>800/>200 |
| **Network** | p95<200ms payload<50KB cache>80% | <500ms/<150KB/>60% | <1s/<500KB/>40% | <2s/<1MB/>20% | >2s/>1MB/<20% |
| **Bundle** | APK<30MB/S<50MB/JS<100KB | <50/<100/<200 | <80/<200/<400 | <120/<400/<800 | >120/>400/>800KB |
| **Energy** | 1%/hr CPU<10% / idle<2% | 2%/hr<20% / <5% | 4%/hr<30% / <10% | 8%/hr<50% / <20% | >8%/>50%/>20%/const |

## Quick Checks
```powershell
Get-ChildItem build/static/js/*.js -Recurse | Measure-Object -Property Length -Sum
npx lighthouse http://localhost:3000 --output json | ConvertFrom-Json | Select-Object -ExpandProperty categories
Get-ChildItem build/static/js/*.js | Sort-Object Length -Descending | Select-Object -First 5 Name, @{N="KB";E={$_.Length/1KB -as [int]}}
```

## Score Storage & Trend
`mem_save(type="learning", title="perf-score:{app}-{platform}", content="**Load**:X|**Render**:X|**Memory**:X|**Network**:X|**Bundle**:X|**Energy**:X|**Avg**:X.X|**Platform**:{mob|desk|web}|**App**:{name}")`. Trend (every 10 or session end): `mem_search(query="perf-score:", limit=20)` → prev(5) vs recent(5). Drop >0.5 → gap-analysis.

## Action by Avg
≥8 Maintain · 6-7.9 Light review + profile · 4-5.9 gap-analysis + fix · <4 Critical perf sprint

## Hard Rules
- Score EVERY dimension from real measurement — NEVER guess ("feels fast") or placeholder
- Platform in mem_save title (`perf-score:{app}-{platform}`); NEVER mix platforms in one trend
- NEVER skip a dimension — unavailable → neutral 7 + annotate
- Trend only at N≥5; regression = drop >0.5 (prev 5 vs recent 5) → gap-analysis; >0.2 → light review
- CI: median-of-3 lighthouse runs (not mean); never crash on missing process — degrade to static-only
- Scope: app performance only — agent perf → `auto-metrics`

## Output
`PERF-SCORE:<app>—<date> DIMS:[Load|Render|Memory|Network|Bundle|Energy]=<1-10> AVG=<n.n> PLATFORM:<mob|desk|web> TREND:<delta>→<stable|drift|regression>`

## Anti-Patterns
Score without real data · cross-platform in same trend · skip bundle/cache · score once

## Reference
Worked examples (5) → docs/skills/performance-tracker/reference.md