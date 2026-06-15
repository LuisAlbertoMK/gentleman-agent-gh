---
name: performance-tracker
description: Score and track mobile/desktop/web app performance across 6 dimensions. Continuous scoring with trend analysis.
license: Apache-2.0
metadata: version: "1.2"
triggers: "performance score, mobile perf, desktop perf, rendimiento, performance-tracker, app score, lighthouse, benchmark"
---

## Scope
Score app PERFORMANCE (not agent behavior — use `auto-metrics` for that).
Covers: Mobile (Android/iOS), Desktop (Win/Mac/Linux), Web.

## 6 Dimensions (1-10)

### Load
Score 9-10: M <1.5s / D <1s / W LCP<1.5 TTI<2 | 7-8: <2.5s/<2s/<2.5/<3.5 | 5-6: <4s/<3.5/<4/<5 | 3-4: <6s/<5/<6/<7 | 1-2: >6s/>5/>6/>7

### Render
9-10: M 60fps/0drop / D 60fps vsync / W CLS<0.1 INP<200 | 7-8: 55fps/<2% / smooth / <0.25 <350 | 5-6: 45fps/<5% / jank / <0.5 <500 | 3-4: 30fps/<10% / jank / <0.75 <700 | 1-2: <30fps / freeze / >0.75 >700

### Memory
9-10: M <50MB / D <100MB / W <30MB | 7-8: <100 / <200 / <60 | 5-6: <200 / <400 / <100 | 3-4: <350/OOM / <800 / <200 | 1-2: >350 / >800 / >200

### Network
9-10: p95<200ms payload<50KB cache>80% | 7-8: <500ms/<150KB/>60% | 5-6: <1s/<500KB/>40% | 3-4: <2s/<1MB/>20% | 1-2: >2s/>1MB/<20%

### Bundle
9-10: M APK<30MB / D <50MB / W JS<100KB | 7-8: <50 / <100 / <200 | 5-6: <80 / <200 / <400 | 3-4: <120 / <400 / <800 | 1-2: >120/>400/>800KB

### Energy/CPU
9-10: M 1%/hr CPU<10% / D idle<2% / W no throttle<10% | 7-8: 2%/hr<20% / <5% / min | 5-6: 4%/hr<30% / <10% / occ | 3-4: 8%/hr<50% / <20% / freq | 1-2: >8%/>50% / >20% / const

## Quick Checks
**Bundle**: `Get-ChildItem build/static/js/*.js -Recurse | Measure-Object -Property Length -Sum` · `Get-ChildItem *.apk,*.aab,*.ipa`
**Lighthouse**: `npx lighthouse http://localhost:3000 --quiet --output json | ConvertFrom-Json | Select-Object -ExpandProperty categories`
**Render-blocking**: `Select-String -Path build/index.html -Pattern "script|link|style" | Select-Object -First 10`
**Source map**: `Get-ChildItem build/static/js/*.js | Sort-Object Length -Descending | Select-Object -First 5 Name, @{N="KB";E={$_.Length/1KB -as [int]}}`

## Score Storage & Trend
**Save**: `mem_save(type="learning", title="perf-score:{app}", content="**Load**:X/10|**Render**:X/10|**Memory**:X/10|**Network**:X/10|**Bundle**:X/10|**Energy**:X/10|**Avg**:X.X/10|**Platform**:{mobile|desktop|web}|**App**:{name}")`

**Trend** (every 10 scores OR session end): `mem_search(query="perf-score:", limit=20)` → compare prev(5) vs recent(5). If dim drop >0.5 → `gap-analysis`.

Template:
```
## Trend: {date} | {N} scores
| Dim | Prev | Recent | Delta |
| Load | X.X | X.X | +X.X | ... | **Avg** | **X.X** | **X.X** | **±X.X** |
Verdict: improving/stable/declining
```

## Action by Avg
≥8 Maintain · 6-7.9 Light review + profile · 4-5.9 gap-analysis + fix · <4 Critical perf sprint

## Anti-Patterns
❌ Score without real data · compare different platforms in same trend · skip bundle/cache checks · score once and ignore
