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

### Load Time
| Score | Mobile | Desktop | Web |
|-------|--------|---------|-----|
| 9-10 | Cold <1.5s | Launch <1s | LCP <1.5s, TTI <2s |
| 7-8 | Cold <2.5s | Launch <2s | LCP <2.5s, TTI <3.5s |
| 5-6 | Cold <4s | Launch <3.5s | LCP <4s, TTI <5s |
| 3-4 | Cold <6s | Launch <5s | LCP <6s, TTI <7s |
| 1-2 | Cold >6s | Launch >5s | LCP >6s, TTI >7s |

### Render
| Score | Mobile | Desktop | Web |
|-------|--------|---------|-----|
| 9-10 | 60fps, 0 drops | 60fps, vsync | CLS <0.1, INP <200ms |
| 7-8 | 55fps, <2% drops | 55fps, smooth | CLS <0.25, INP <350ms |
| 5-6 | 45fps, <5% drops | 45fps, jank | CLS <0.5, INP <500ms |
| 3-4 | 30fps, <10% drops | 30fps, jank | CLS <0.75, INP <700ms |
| 1-2 | <30fps, stutter | <30fps, freeze | CLS >0.75, INP >700ms |

### Memory
| Score | Mobile | Desktop | Web |
|-------|--------|---------|-----|
| 9-10 | <50MB, no leaks | <100MB, stable | <30MB, GC rare |
| 7-8 | <100MB, min GC | <200MB, stable | <60MB, GC ok |
| 5-6 | <200MB, GC visible | <400MB, GC pressure | <100MB, leaks possible |
| 3-4 | <350MB, OOM risk | <800MB, high usage | <200MB, leaks likely |
| 1-2 | >350MB, OOM | >800MB, swapping | >200MB, major leaks |

### Network
9-10: API p95 <200ms, payload <50KB, cache hit >80% · 7-8: <500ms, <150KB, >60%
5-6: <1s, <500KB, >40% · 3-4: <2s, <1MB, >20% · 1-2: >2s, >1MB, <20%

### Bundle
| Score | Mobile | Desktop | Web |
|-------|--------|---------|-----|
| 9-10 | APK <30MB | <50MB installer | JS <100KB gzip |
| 7-8 | APK <50MB | <100MB | JS <200KB |
| 5-6 | APK <80MB | <200MB | JS <400KB |
| 3-4 | APK <120MB | <400MB | JS <800KB |
| 1-2 | >120MB | >400MB | >800KB |

### Energy/CPU
| Score | Mobile | Desktop | Web |
|-------|--------|---------|-----|
| 9-10 | 1%/hr bg, CPU <10% | Idle <2% CPU | No throttle, <10% CPU |
| 7-8 | 2%/hr, CPU <20% | Idle <5% | Minimal throttle |
| 5-6 | 4%/hr, CPU <30% | Idle <10% | Occasional throttle |
| 3-4 | 8%/hr, CPU <50% | Idle <20% | Frequent throttle |
| 1-2 | >8%/hr, CPU >50% | Idle >20% | Constant throttle |

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
