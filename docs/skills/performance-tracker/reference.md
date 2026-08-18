# performance-tracker — Worked Examples, Testing Patterns & Guardrails

> **Externalized from** .agents/skills/performance-tracker/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains 4-5 worked examples, 3 testing patterns, 4 edge cases, and 2 anti-patterns.
> **Consumable by**: performance-tracker sub-agent when scoring app performance.
## Examples (4-5)

### Example 1: Mobile App Full Score (Android)
```powershell
# Prerequisites: adb, Android Studio, lighthouse-ci
adb shell am start -n com.example.app/.MainActivity
sleep 5
adb shell dumpsys meminfo com.example.app | Select-String "TOTAL"
adb shell dumpsys batterystats com.example.app | Select-String "Uid.*com.example.app"

# Lighthouse for web view
npx lighthouse https://app.example.com --output json --chrome-flags="--headless" > lh-report.json

# Extract scores
$lh = Get-Content lh-report.json | ConvertFrom-Json
$load = if ($lh.categories.performance.score * 10 -ge 9) { 9 } elseif ($lh.categories.performance.score * 10 -ge 7) { 7 } else { 5 }
$network = if ($lh.audits["server-response-time"].numericValue -lt 200) { 9 } elseif (...) { 7 } else { 5 }

# Memory from dumpsys (MB)
$memMB = (adb shell dumpsys meminfo com.example.app | Select-String "TOTAL").ToString().Split()[1] / 1024
$memory = if ($memMB -lt 50) { 9 } elseif ($memMB -lt 100) { 7 } elseif ($memMB -lt 200) { 5 } else { 3 }

# Bundle size
$apkMB = (Get-ChildItem build/outputs/apk/release/*.apk).Length / 1MB
$bundle = if ($apkMB -lt 30) { 9 } elseif ($apkMB -lt 50) { 7 } elseif ($apkMB -lt 80) { 5 } else { 3 }

# Energy: Battery Historian or manual 1hr test
$energy = 7  # placeholder

$avg = [math]::Round(($load + 7 + $memory + $network + $bundle + $energy) / 6, 1)
mem_save -type learning -title "perf-score:myapp" -content "**Load**:$load|**Render**:7|**Memory**:$memory|**Network**:$network|**Bundle**:$bundle|**Energy**:$energy|**Avg**:$avg|**Platform**:mob|**App**:myapp"
```
**Result**: Persists structured score for trend analysis. Run weekly → compare deltas.

---

### Example 2: Web App CI Pipeline Integration
```yaml
# .github/workflows/perf-track.yml
name: Performance Tracking
on: [push, pull_request]
jobs:
  perf-score:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci && npm run build
      - run: npx serve -s build -l 3000 &
      - run: sleep 5
      - name: Lighthouse CI
        run: npx lighthouse http://localhost:3000 --output json --output-path lh.json --chrome-flags="--headless --no-sandbox"
      - name: Extract & Save Score
        run: |
          $lh = Get-Content lh.json | ConvertFrom-Json
          $load = [math]::Round($lh.categories.performance.score * 10)
          $render = if ($lh.audits["cumulative-layout-shift"].numericValue -lt 0.1) { 9 } elseif (...) { 7 } else { 5 }
          $network = if ($lh.audits["server-response-time"].numericValue -lt 200) { 9 } elseif (...) { 7 } else { 5 }
          $bundle = if ((Get-ChildItem build/static/js/*.js | Measure-Object -Property Length -Sum).Sum / 1KB -lt 100) { 9 } elseif (...) { 7 } else { 5 }
          $avg = [math]::Round(($load + $render + 7 + $network + $bundle + 7) / 6, 1)
          echo "PERF_SCORE=$avg" >> $env:GITHUB_ENV
      - name: Trend Check
        run: |
          # Query previous scores from Engram
          $prev = mem_search "perf-score:mywebapp" --limit 5
          if ($prev.Count -ge 2) {
            $recentAvg = ($prev | Select-Object -First 3 | ForEach-Object { $_.content -match 'Avg:(\d+\.\d+)' ; [double]$matches[1] } | Measure-Object -Average).Average
            $olderAvg = ($prev | Select-Object -Skip 3 -First 3 | ForEach-Object { $_.content -match 'Avg:(\d+\.\d+)' ; [double]$matches[1] } | Measure-Object -Average).Average
            if ($olderAvg - $recentAvg -gt 0.5) { exit 1 }  # fail build on regression
          }
```
**Result**: Automated scoring on every PR, fails build if trend drops >0.5 over 5 runs.

---

### Example 3: Desktop App (Electron) Profiling Session
```powershell
# 1. Start app with profiling
$env:ELECTRON_ENABLE_LOGGING=1
$env:ELECTRON_LOG_FILE="electron.log"
Start-Process "dist/win-unpacked/MyApp.exe" -ArgumentList "--enable-precise-memory-info", "--js-flags=--expose-gc"
Start-Sleep 3

# 2. Collect metrics over 60s
$pid = (Get-Process MyApp).Id
$metrics = @()
for ($i=0; $i -lt 12; $i++) {
    $proc = Get-Process -Id $pid
    $mem = [math]::Round($proc.WorkingSet64 / 1MB, 1)
    $cpu = [math]::Round($proc.TotalProcessorTime.TotalMilliseconds / 1000, 1)
    $metrics += @{ time=$i*5; mem=$mem; cpu=$cpu }
    Start-Sleep 5
}

# 3. Render: Use DevTools Protocol (CDP) for frame times
$cdp = New-Object System.Net.WebClient
$frames = $cdp.DownloadString("http://localhost:9222/json/version")  # adjust port
# Parse frame timestamps → calculate fps, jank %

# 4. Score
$avgMem = ($metrics | Measure-Object -Property mem -Average).Average
$memory = if ($avgMem -lt 100) { 9 } elseif ($avgMem -lt 200) { 7 } elseif ($avgMem -lt 400) { 5 } else { 3 }
$render = if ($avgFps -ge 55 -and $jankPct -lt 2) { 9 } elseif ($avgFps -ge 45) { 7 } elseif ($avgFps -ge 30) { 5 } else { 3 }

$avg = [math]::Round(($load + $render + $memory + $network + $bundle + $energy) / 6, 1)
mem_save -type learning -title "perf-score:myapp-desktop" -content "..."
```
**Result**: Real-user monitoring style profiling for Electron/desktop apps.

---

### Example 4: Regression Detection & Alert
```powershell
# Run at session end or scheduled
$scores = mem_search -query "perf-score:myapp" -limit 20
if ($scores.Count -lt 5) { Write-Host "Need 5+ scores for trend"; exit }

$recent = $scores | Select-Object -First 5 | ForEach-Object {
    $_.content -match 'Avg:(\d+\.\d+)'; [double]$matches[1]
}
$older = $scores | Select-Object -Skip 5 -First 5 | ForEach-Object {
    $_.content -match 'Avg:(\d+\.\d+)'; [double]$matches[1]
}

$recentAvg = ($recent | Measure-Object -Average).Average
$olderAvg = ($older | Measure-Object -Average).Average
$delta = [math]::Round($olderAvg - $recentAvg, 2)

if ($delta -gt 0.5) {
    $msg = "🚨 PERF REGRESSION: $delta drop (was $olderAvg, now $recentAvg) — triggering gap-analysis"
    Write-Host $msg
    # Auto-create issue or notify
    gh issue create --title "Perf regression: $delta drop" --body $msg --label performance
} elseif ($delta -gt 0.2) {
    Write-Host "⚠️ Perf drift: $delta drop — schedule light review"
} else {
    Write-Host "✅ Perf stable: $delta delta"
}
```
**Result**: Automated trend alerting with actionable thresholds.

---

### Example 5: Cross-Platform Comparison (Separate Trends)
```powershell
# NEVER mix platforms in same trend — separate mem_save titles
mem_save -title "perf-score:myapp-android" -content "...|**Platform**:mob|**App**:myapp"
mem_save -title "perf-score:myapp-ios" -content "...|**Platform**:mob|**App**:myapp"
mem_save -title "perf-score:myapp-web" -content "...|**Platform**:web|**App**:myapp"
mem_save -title "perf-score:myapp-windows" -content "...|**Platform**:desk|**App**:myapp"
mem_save -title "perf-score:myapp-macos" -content "...|**Platform**:desk|**App**:myapp"

# Query per platform independently
$android = mem_search -query "perf-score:myapp-android" -limit 10
$web = mem_search -query "perf-score:myapp-web" -limit 10
# Compare platform-specific trends independently
```
**Result**: Clean platform-isolated trends. Anti-pattern avoided.

---

## Testing Patterns (3)

### Pattern 1: Synthetic Benchmark Validation
```powershell
# Verify scoring logic against known baselines
function Test-PerfScoreLogic {
    param([hashtable]$metrics, [int]$expectedAvg)
    
    $load = Get-LoadScore $metrics.lcp $metrics.tti
    $render = Get-RenderScore $metrics.fps $metrics.cls $metrics.inp
    $memory = Get-MemoryScore $metrics.memMB
    $network = Get-NetworkScore $metrics.p95ms $metrics.payloadKB $metrics.cacheHit
    $bundle = Get-BundleScore $metrics.bundleKB
    $energy = Get-EnergyScore $metrics.batteryPctHr $metrics.cpuPct
    
    $actual = [math]::Round(($load+$render+$memory+$network+$bundle+$energy)/6, 1)
    Assert-Equal $actual $expectedAvg "Score calculation mismatch"
}

# Test cases
Test-PerfScoreLogic @{ lcp=1.2; tti=1.8; fps=60; cls=0.05; inp=150; memMB=40; p95ms=150; payloadKB=30; cacheHit=85; bundleKB=80; batteryPctHr=0.8; cpuPct=8 } 9.5
Test-PerfScoreLogic @{ lcp=3.0; tti=4.0; fps=48; cls=0.3; inp=400; memMB=180; p95ms=800; payloadKB=400; cacheHit=45; bundleKB=300; batteryPctHr=3; cpuPct=25 } 5.5
Test-PerfScoreLogic @{ lcp=7.0; tti=8.0; fps=25; cls=0.9; inp=900; memMB=500; p95ms=2500; payloadKB=1200; cacheHit=15; bundleKB=900; batteryPctHr=10; cpuPct=60 } 2.0
```
**Purpose**: Validates dimension scoring formulas produce expected buckets.

---

### Pattern 2: Trend Detection Accuracy
```powershell
# Inject known trend into mem_save, verify detection
function Test-TrendDetection {
    # Clean slate
    mem_purge -confirm -scope session  # or use unique test project
    
    # Inject declining trend: 9.0 → 8.5 → 8.0 → 7.5 → 7.0 (drop 0.5 per step)
    9.0, 8.5, 8.0, 7.5, 7.0 | ForEach-Object {
        mem_save -type learning -title "perf-score:testapp" -content "**Load**:9|**Render**:9|**Memory**:9|**Network**:9|**Bundle**:9|**Energy**:9|**Avg**:$_|**Platform**:web|**App**:testapp"
    }
    
    # Run detection
    $result = Invoke-TrendCheck "testapp"  # uses the regression detection logic
    Assert-True $result.regressionDetected "Should detect >0.5 drop over 5 runs"
    Assert-Equal $result.delta 2.0 "Total drop should be 2.0"
    
    # Inject stable trend: 8.0, 8.1, 7.9, 8.0, 8.1
    8.0, 8.1, 7.9, 8.0, 8.1 | ForEach-Object { ... }
    $result = Invoke-TrendCheck "testapp"
    Assert-False $result.regressionDetected "Stable trend should not trigger"
}
```
**Purpose**: Ensures trend analysis correctly identifies regressions vs noise.

---

### Pattern 3: Platform Isolation Enforcement
```powershell
function Test-PlatformIsolation {
    # Save scores for same app on different platforms
    mem_save -title "perf-score:app-android" -content "...|**Platform**:mob|**App**:app|**Avg**:7.0"
    mem_save -title "perf-score:app-ios" -content "...|**Platform**:mob|**App**:app|**Avg**:8.5"
    mem_save -title "perf-score:app-web" -content "...|**Platform**:web|**App**:app|**Avg**:6.0"
    
    # Query each platform independently
    $android = mem_search "perf-score:app-android" -limit 5
    $ios = mem_search "perf-score:app-ios" -limit 5
    $web = mem_search "perf-score:app-web" -limit 5
    
    Assert-Equal $android.Count 1 "Android trend isolated"
    Assert-Equal $ios.Count 1 "iOS trend isolated"
    Assert-Equal $web.Count 1 "Web trend isolated"
    
    # Verify cross-platform query does NOT mix
    $all = mem_search "perf-score:app" -limit 20  # broader query
    Assert-True ($all | Where-Object { $_.title -like "*android*" }).Count -eq 1
    Assert-True ($all | Where-Object { $_.title -like "*ios*" }).Count -eq 1
    Assert-True ($all | Where-Object { $_.title -like "*web*" }).Count -eq 1
}
```
**Purpose**: Confirms platform-specific trends never pollute each other.

---

## Edge Cases (4)

### Edge Case 1: Missing Dimension Data (Energy on Desktop)
```powershell
# Energy metrics unavailable on desktop CI → use platform-aware default
$energy = if ($platform -eq "web" -or $platform -eq "mob") {
    Get-EnergyScore $battery $cpu
} else {
    7  # neutral: desktop plugged in, not measured
}
# Document in saved content: **Energy**:7 (desktop-default)
```
**Handling**: Assign neutral score (7), annotate in mem_save content. Never skip dimension.

---

### Edge Case 2: First Run — No Baseline for Trend
```powershell
$history = mem_search "perf-score:$app" -limit 10
if ($history.Count -lt 5) {
    Write-Host "Baseline building: $($history.Count)/5 scores collected"
    # Save anyway, skip trend check
    return @{ trendCheckSkipped=$true; reason="Insufficient history ($($history.Count) < 5)" }
}
```
**Handling**: Graceful degradation. Build baseline silently, start trend checks at N≥5.

---

### Edge Case 3: Lighthouse Flakiness (High Variance)
```powershell
# Run 3x, use median not mean
$runs = 1..3 | ForEach-Object {
    npx lighthouse $url --output json --chrome-flags="--headless" -q
    $lh = Get-Content lh.json | ConvertFrom-Json
    [double]$lh.categories.performance.score * 10
}
$medianLoad = ($runs | Sort-Object)[1]  # median of 3
# Reduces false regression alerts from CI noise
```
**Handling**: Median-of-3 for CI. Single run OK for local dev.

---

### Edge Case 4: App Not Running / Process Not Found
```powershell
$proc = Get-Process -Name $appName -ErrorAction SilentlyContinue
if (-not $proc) {
    Write-Warning "App '$appName' not running — skipping live metrics"
    # Fall back to static analysis only (bundle, config review)
    $liveMetrics = @{ memory=7; render=7; energy=7 }  # neutral
}
```
**Handling**: Never crash. Degrade to static-only scoring with neutral live dims.

---

## Anti-Patterns (2)

### Anti-Pattern 1: Scoring Without Real Measurements
```powershell
# ❌ WRONG: Guessing scores
$load = 9 "feels fast"
$memory = 8 "should be fine"

# ✅ CORRECT: Measure every dimension
$load = Get-LoadScore (Measure-LCP) (Measure-TTI)
$memory = Get-MemoryScore (Measure-ProcessMemory)
```
**Why it fails**: Subjective scores create false confidence, hide regressions, break trend analysis.

---

### Anti-Pattern 2: Mixing Platforms in Single Trend Line
```powershell
# ❌ WRONG: One trend for all platforms
mem_save -title "perf-score:myapp" -content "...|**Platform**:mob|**Avg**:7.0"
mem_save -title "perf-score:myapp" -content "...|**Platform**:web|**Avg**:5.5"
# Trend compares mobile 7.0 vs web 5.5 → false "regression" alert

# ✅ CORRECT: Platform in title
mem_save -title "perf-score:myapp-android" -content "...|**Platform**:mob|**Avg**:7.0"
mem_save -title "perf-score:myapp-web" -content "...|**Platform**:web|**Avg**:5.5"
```
**Why it fails**: Different platforms have different baselines (mobile CPU vs desktop, network variance). Cross-platform trends produce noise, not signal.

---

## Cross-Refs: auto-metrics | gap-analysis | web-quality-audit | performance | metricas


