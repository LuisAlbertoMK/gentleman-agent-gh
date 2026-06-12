---
name: performance-tracker
description: Score and track mobile/desktop/web app performance across 6 dimensions. Continuous scoring with trend analysis.
license: Apache-2.0
metadata: version: "1.0"
triggers: "performance score, mobile perf, desktop perf, rendimiento, performance-tracker, app score, lighthouse, benchmark"
---

## Scope
Score app PERFORMANCE (not agent behavior). For agent self-evaluation, use `auto-metrics`.
Covers: Mobile (Android/iOS), Desktop (Win/Mac/Linux), Web.

## 6 Dimensions (1-10)

### Load Time
| Score | Mobile | Desktop | Web |
|-------|--------|---------|-----|
| 9-10 | Cold start <1.5s | Launch <1s | LCP <1.5s, TTI <2s |
| 7-8 | Cold start <2.5s | Launch <2s | LCP <2.5s, TTI <3.5s |
| 5-6 | Cold start <4s | Launch <3.5s | LCP <4s, TTI <5s |
| 3-4 | Cold start <6s | Launch <5s | LCP <6s, TTI <7s |
| 1-2 | Cold start >6s | Launch >5s | LCP >6s, TTI >7s |

### Render
| Score | Mobile | Desktop | Web |
|-------|--------|---------|-----|
| 9-10 | 60fps sustained, 0 drops | 60fps, vsync | CLS <0.1, INP <200ms |
| 7-8 | 55fps avg, <2% drops | 55fps, smooth | CLS <0.25, INP <350ms |
| 5-6 | 45fps avg, <5% drops | 45fps, minor jank | CLS <0.5, INP <500ms |
| 3-4 | 30fps avg, <10% drops | 30fps, noticeable jank | CLS <0.75, INP <700ms |
| 1-2 | <30fps, stutter | <30fps, freezing | CLS >0.75, INP >700ms |

### Memory
| Score | Mobile | Desktop | Web |
|-------|--------|---------|-----|
| 9-10 | <50MB heap, no leaks | <100MB, stable | <30MB, GC rare |
| 7-8 | <100MB, minimal GC | <200MB, stable | <60MB, GC ok |
| 5-6 | <200MB, GC visible | <400MB, GC pressure | <100MB, leaks possible |
| 3-4 | <350MB, OOM risk | <800MB, high usage | <200MB, leaks likely |
| 1-2 | >350MB, OOM crashes | >800MB, swapping | >200MB, major leaks |

### Network
| Score | Criteria |
|-------|----------|
| 9-10 | API p95 <200ms, payload <50KB, cache hit >80% |
| 7-8 | API p95 <500ms, payload <150KB, cache hit >60% |
| 5-6 | API p95 <1s, payload <500KB, cache hit >40% |
| 3-4 | API p95 <2s, payload <1MB, cache hit >20% |
| 1-2 | API p95 >2s, payload >1MB, cache hit <20% |

### Bundle
| Score | Mobile | Desktop | Web |
|-------|--------|---------|-----|
| 9-10 | APK <30MB, IPA <50MB | <50MB installer | JS <100KB gzip |
| 7-8 | APK <50MB, IPA <80MB | <100MB installer | JS <200KB gzip |
| 5-6 | APK <80MB, IPA <120MB | <200MB installer | JS <400KB gzip |
| 3-4 | APK <120MB, IPA <180MB | <400MB installer | JS <800KB gzip |
| 1-2 | APK >120MB, IPA >180MB | >400MB installer | JS >800KB gzip |

### Energy/CPU
| Score | Mobile | Desktop | Web |
|-------|--------|---------|-----|
| 9-10 | 1% battery/hr bg, CPU <10% | Idle <2% CPU | No throttle, <10% CPU |
| 7-8 | 2% battery/hr, CPU <20% | Idle <5% CPU | Minimal throttle |
| 5-6 | 4% battery/hr, CPU <30% | Idle <10% CPU | Occasional throttle |
| 3-4 | 8% battery/hr, CPU <50% | Idle <20% CPU | Frequent throttle |
| 1-2 | >8% battery/hr, CPU >50% | Idle >20% CPU | Constant throttle |

## Quick Score (5 min)
Run from workspace root. Only checks available tools.

```powershell
# Web
if (Get-Command npx -ErrorAction SilentlyContinue) {
  npx lighthouse http://localhost:3000 --quiet --output json | ConvertFrom-Json | Select-Object -ExpandProperty categories | ForEach-Object { "$($_.id): $($_.score*100)" }
}

# APK size (Android)
if (Test-Path "*.apk") {
  Get-ChildItem *.apk | Select-Object Name, @{N="SizeMB";E={$_.Length/1MB -as [int]}}
}
if (Test-Path "*.aab") {
  Get-ChildItem *.aab | Select-Object Name, @{N="SizeMB";E={$_.Length/1MB -as [int]}}
}

# IPA size (iOS)
if (Test-Path "*.ipa") {
  Get-ChildItem *.ipa | Select-Object Name, @{N="SizeMB";E={$_.Length/1MB -as [int]}}
}

# Bundle web
if (Test-Path "build/static/js/") {
  Get-ChildItem build/static/js/*.js -Recurse | Measure-Object -Property Length -Sum | % { "JS Bundle: $($_.Sum/1KB -as [int])KB" }
}
```

## Standard Score (30 min)
Run per-dimension auto-checks + manual verify.

### Mobile (Android)
```powershell
# APK analyzer
if (Get-Command aapt2 -ErrorAction SilentlyContinue) {
  aapt2 dump resources app-release.apk 2>$null | Select-Object -First 5
}

# Startup tracking (needs device)
# adb shell am start -W com.example/.MainActivity
```

### Mobile (iOS)
```powershell
# IPA analysis
# otool -l app.ipa | head -20
# xcrun xcodebuild -showBuildSettings
```

### Desktop
```powershell
# Binary size
if (Test-Path "*.exe") {
  Get-ChildItem *.exe | Sort-Object Length -Descending | Select-Object Name, @{N="SizeMB";E={$_.Length/1MB -as [int]}}
}
if (Test-Path "*.dmg") {
  Get-ChildItem *.dmg | Sort-Object Length -Descending | Select-Object Name, @{N="SizeMB";E={$_.Length/1MB -as [int]}}
}
```

### Web
```powershell
# Source map explorer
if (Test-Path "build/static/js/") {
  # Check for large chunks
  Get-ChildItem build/static/js/*.js | Sort-Object Length -Descending | Select-Object -First 5 Name, @{N="SizeKB";E={$_.Length/1KB -as [int]}}
}

# Check for render-blocking resources
if (Test-Path "build/index.html") {
  Select-String -Path build/index.html -Pattern "script|link|style" | Select-Object -First 10
}
```

## Storage & Trend
Same format as auto-metrics trend tracking.

```powershell
# Save score
mem_save(type="learning", title="perf-score:{app}", content="**Load**:X/10|**Render**:X/10|**Memory**:X/10|**Network**:X/10|**Bundle**:X/10|**Energy**:X/10|**Avg**:X.X/10|**Platform**:{mobile|desktop|web}|**App**:{name}")
```

### Trend Check (every 10 scores OR at session end)
1. `mem_search(query="perf-score:", limit=20)`
2. Parse → per-dim means, prev vs recent delta
3. Report and act if declining

```
## Performance Trend: {date}
Period: {oldest} → {newest} ({N} scores) | Platform: {majority}
| Dim | Prev | Recent | Delta |
|-----|------|--------|-------|
| Load | X.X | X.X | +X.X |
| Render | X.X | X.X | +X.X |
| Memory | X.X | X.X | +X.X |
| Network | X.X | X.X | +X.X |
| Bundle | X.X | X.X | +X.X |
| Energy | X.X | X.X | +X.X |
| **Avg** | **X.X** | **X.X** | **±X.X** |
Verdict: improving/stable/declining
```

If any dim drops >0.5 → `gap-analysis` on perf dims + diagnose.

## Action by Avg
| Avg | Action |
|:---:|--------|
| ≥8 | Maintain — monitor next release |
| 6-7.9 | Light review — profile hotspots |
| 4-5.9 | Improvement cycle — gap-analysis + fix |
| <4 | Critical — stop features, perf sprint |

## Cross-References
- **gap-analysis**: dims 3 (Optimization), 4 (Performance), 5 (Resource Usage)
- **auto-metrics**: for agent behavior scoring (not app perf)
- **metricas**: token-level before/after (irrelevant here)

## Anti-Patterns
❌ Score without real data — guesswork is noise
❌ Compare different platforms in same trend — mobile vs web have diff baselines
❌ Skip bundle/cache checks — those are easiest wins
❌ Score once and ignore — perf regresses; track over time
