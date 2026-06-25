# GC Tuning for Bun/V8 in Agent Workloads

**Research date**: 2026-06-23
**Scope**: opencode-vmk (Node.js/V8) + gentleman-vMK (Bun/JavaScriptCore)
**Sources consulted**: 20+ (V8 DeepWiki, Bun DeepWiki, Node.js docs, JSC blog, Platformatic, ADHDecode, NearForm, Red Hat, WebKit blog, several GitHub issues/PRs)

---

## 1. Architecture Comparison

### V8 (Node.js / opencode-vmk)

| Generation | Collector | Strategy | Concurrent? | Incremental? | Typical Pause |
|---|---|---|---|---|---|
| Young (NewSpace) | Scavenger | Copying (Cheney) | Parallel (workers) | No | 1â€“5 ms |
| Young (NewSpace) | Minor Mark-Sweep | Mark-Sweep | Concurrent | Yes (V8 12+) | 2â€“8 ms |
| Old (OldSpace) | Mark-Compact | Mark-Sweep-Compact | Concurrent marking + sweeping | Yes | 15â€“100 ms+ |

- **V8 heap**: NewSpace (two semi-spaces) â†’ OldSpace â†’ LargeObjectSpace â†’ CodeSpace
- **Default max-old-space-size**: ~1.5 GB (64-bit), auto-scaled by Node.js to 50% of container RAM (up to 2 GB ceiling)
- **Default max-semi-space-size**: **DANGEROUSLY small** in Node.js v22+ â€” as low as **1 MB** per semi-space on 512 MB containers (auto-calculated from perceived available memory). This causes massive premature promotion.
- **Incremental marking** enabled by default; splits mark phase into 1â€“5 ms steps triggered every 256 KB old-gen allocation
- **Concurrent sweeping** enabled by default; background thread reclaims memory

### JavaScriptCore (Bun / gentleman-vMK)

| Aspect | Behavior |
|---|---|
| Heap model | Non-compacting, generational (eden + old space) |
| Eden GC | Collects only eden (young gen) â€” fast, ~linear to eden size |
| Full GC | Collects entire heap; concurrent marking + parallel marking threads |
| Write barrier | Strict generational barrier; Bun uses `JSC::WriteBarrier` + `WriteBarrierList` |
| Compaction | **None** â€” JSC does NOT compact (avoids move cost, trades fragmentation) |
| Allocation | Bump-pointer in eden; IsoSubspaces for typed allocations |

- **Bun's GarbageCollectionController** (Zig): adaptive timer-based scheduler
  - **Fast mode** (~1 s interval) when heap is growing
  - **Slow mode** (30 s interval) when heap stable for 30 s
  - Runs `collectAsync()` on heap doubling (`heap_size > prev * 2`)
  - Deferred while HTTP requests are in-flight
  - At 70%+ RSS, triggers aggressive collection
  - Configurable: `BUN_GC_TIMER_INTERVAL`, `BUN_GC_TIMER_DISABLE`, `BUN_GC_RUNS_UNTIL_SKIP_RELEASE_ACCESS`
- **JSC env vars**: prefix with `BUN_JSC_` â€” unstable, per `OptionsList.h`
- **Known upstream JSC GC leaks** (4 tracked, critical â€” `SlotVisitor::drainFromShared` race, `HashTable::removeIterator`, etc.)

---

## 2. The "Toaster" Problem: Predictable Low-Latency GC for Interactive Agents

Agents like opencode and gentleman have a specific GC profile:

| Characteristic | Agent Workload | Typical Web App |
|---|---|---|
| Session duration | Minutes to hours (long) | Seconds to minutes |
| Allocation pattern | Spikey (tool results, streaming, context accumulation) | Steady (request-response) |
| Tolerance for pauses | VERY LOW (user typing, streaming) | Moderate (page transitions) |
| Heap growth | Monotonic with context | Cyclic (per-request) |
| Critical path | Tool execution + LLM streaming | First paint / API response |

### Problem Chain (V8)

```
High allocation rate (tool results, context)
  â†’ Young gen fills faster â†’ frequent minor GC (1-5ms each, adds up)
  â†’ Objects promoted prematurely â†’ Old gen grows
  â†’ Major GC triggered more often â†’ 50-500ms+ pauses
  â†’ User experiences "stuttering" during streaming
```

On Node.js v22+, premature promotion is **aggravated** by the tiny default semi-space (1 MB on 512 MB containers). Objects survive 1â€“2 scavenges and get promoted, bloating Old Space.

### Problem Chain (Bun/JSC)

JSC's non-compacting design avoids compaction pauses but can fragment. Bun's adaptive controller already handles the interactive use-case well: it defers GC during HTTP, uses fast/slow modes, and triggers on heap doubling. However, the upstream JSC GC leaks (#28343) mean long sessions can accumulate unreclaimed memory.

---

## 3. Recommended Flags

### opencode-vmk (Node.js/V8)

```bash
# Agent workload â€” balanced for interactivity
NODE_OPTIONS="
  --max-old-space-size=4096
  --max-semi-space-size=64
  --initial-old-space-size=1024
  --expose-gc
  --trace-gc
"
```

| Flag | Value | Rationale |
|---|---|---|
| `--max-old-space-size` | 4096 (4 GB) | Prevents OOM during long sessions with large context; leaves room for native modules/buffers |
| `--max-semi-space-size` | 64 MB | **Critical** â€” prevents premature promotion. Each semi-space 64 MB â†’ NewSpace up to 128 MB. Enough to let short-lived tool results die in Scavenge. Benchmark values: 32/64/128 MB |
| `--initial-old-space-size` | 1024 (1 GB) | Pre-allocates old space, reducing early GC churn during session warm-up |
| `--expose-gc` | â€” | Enables `global.gc()` for strategic manual collection after large context swaps |
| `--trace-gc` | â€” | Logs all GC events for monitoring; can be removed in production after baseline |

**Why NOT `--gc-interval`**: For agent workloads, timer-based GC fights the adaptive controller. Better to let V8's own heuristics (incremental marking + concurrent sweeping) handle it. The exception is if you observe 30â€“45% pause reduction from periodic scavenge â€” test empirically.

### gentleman-vMK (Bun/JavaScriptCore)

Bun/Node compat flags:
```bash
# --expose-gc is supported since Bun v1.1.43 (Jan 2025)
bun --expose-gc run server.ts
```

Bun-specific tuning (environment variables):
```bash
# Tune GC timer interval (default: ~1000 ms fast, 30000 ms slow)
BUN_GC_TIMER_INTERVAL=500          # Faster checks for interactive responsiveness
# BUN_GC_TIMER_DISABLE=1           # For debugging only â€” don't use in production

# JSC internal flags (unstable â€” check OptionsList.h for your Bun version)
BUN_JSC_gcMaxHeapSize=4096         # Max heap in MB
BUN_JSC_minHeapSize=512            # Min heap in MB (pre-warm)
```

| Variable | Value | Rationale |
|---|---|---|
| `BUN_GC_TIMER_INTERVAL` | 500 | More frequent GC opportunity checks for interactive agent |
| `BUN_JSC_gcMaxHeapSize` | 4096 | Cap heap at 4 GB for long sessions |
| `BUN_JSC_minHeapSize` | 512 | Pre-warm heap to avoid early growth pauses |

**Important**: JSC env vars must be prefixed `BUN_JSC_` and change between Bun releases without notice. Only use for debugging/benchmarking, not as production contract.

---

## 4. Measured Pause Time Targets

| Metric | Target | Warning | Critical |
|---|---|---|---|
| Minor GC (Scavenge/Eden) | < 5 ms | 5â€“15 ms | > 15 ms |
| Major GC (Mark-Compact/Full) | < 50 ms | 50â€“200 ms | > 200 ms |
| GC frequency (minor) | < 10/s | 10â€“30/s | > 30/s |
| GC frequency (major) | < 1/30s | 1/10sâ€“1/30s | > 1/10s |
| Heap used / max ratio | 40â€“60% | 60â€“80% | > 80% |
| Total GC time per minute | < 500 ms | 500â€“2000 ms | > 2000 ms |

### Allocation Rate Targets

| Metric | Target | Notes |
|---|---|---|
| Allocation rate (steady) | < 50 MB/s | Normal agent operation |
| Allocation rate (peak) | < 200 MB/s | During large tool results / streaming |
| Promotion rate | < 5 MB/s | Above this â†’ increase semi-space |

---

## 5. Programmatic GC Patterns

### V8 (Node.js)

```js
// Strategic manual GC â€” NOT on every tick, only after known large allocations
import v8 from 'node:v8';

// After context swap or large tool result
function afterLargeOperation() {
  if (typeof global.gc === 'function') {
    const before = process.memoryUsage().heapUsed;
    global.gc();            // force major GC (synchronous, STW)
    const after = process.memoryUsage().heapUsed;
    const freed = (before - after) / 1024 / 1024;
    if (freed > 50) {
      console.debug(`[GC] Freed ${freed.toFixed(1)} MB via manual GC`);
    }
  }
}

// GC profiling
const { GCProfiler } = require('v8');
const profiler = new GCProfiler();
profiler.start();
// ... do work ...
const profile = profiler.stop();
// profile.statistics contains per-GC-event data with duration, type, heap stats
```

### Bun (JSC)

```js
import { heapStats } from 'bun:jsc';

// Manual GC â€” supported since Bun v1.1.43
Bun.gc(true);   // synchronous full GC
Bun.gc(false);  // asynchronous GC

// Eden-only GC (lighter)
const { edenGC, fullGC, gcAndSweep } = require('bun:jsc');
edenGC();       // collect only young gen

// Monitor heap stats
function logHeapStats() {
  const stats = heapStats();
  console.debug({
    heapSize: stats.heapSize,
    objectCount: stats.objectCount,
    // objectTypeCounts shows retained objects by type
  });
}
```

---

## 6. Monitoring Setup

### V8 (Node.js) â€” `--trace-gc` output

```
[13579:0x7f...] Scavenge 10.5 ms, 20.6 MB â†’ 15.2 MB  (26% freed)
[13579:0x7f...] Mark-sweep 85.2 ms, 312 MB â†’ 180 MB  (42% freed)
```

Parse this for: pause duration, heap shrinkage %, frequency. Track the ratio of GC time to wall-clock time.

### V8 (Node.js) â€” `perf_hooks` API

```js
const { PerformanceObserver } = require('perf_hooks');
const obs = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.entryType === 'gc') {
      const kind = ['Scavenge', 'MarkSweep', 'Incremental', 'Weak'][entry.kind];
      console.log(`[GC] ${kind}: ${entry.duration.toFixed(2)}ms`);
    }
  }
});
obs.observe({ entryTypes: ['gc'] });
```

### V8 (Node.js) â€” `v8.GCProfiler`

```js
const { GCProfiler } = require('v8');
const profiler = new GCProfiler();
profiler.start();
setTimeout(() => {
  const profile = profiler.stop();
  // profile.statistics[]: { gcType, cost (ms), beforeGC, afterGC }
  console.log(JSON.stringify(profile, null, 2));
}, 10000);
```

### V8 (Node.js) â€” `v8.startHeapProfile` (Node.js 26+, 2026)

```js
const profile = v8.startHeapProfile({
  sampleInterval: 512 * 1024,   // 512 KB sampling
  stackDepth: 16,
  includeObjectsCollectedByMajorGC: true,
  includeObjectsCollectedByMinorGC: true,
});
// ... do work ...
profile.stop();  // writes .heapprofile
```

### Bun â€” JSC heap stats + heap snapshot

```js
// Runtime heap stats
import { heapStats } from 'bun:jsc';
const stats = heapStats();

// Full heap snapshot (viewable in Safari/WebKit GTK DevTools)
Bun.generateHeapSnapshot();  // writes to file

// Native heap stats (mimalloc)
// Set MIMALLOC_SHOW_STATS=1 before launch
```

### Suggested Monitoring Dashboard (CLI-friendly)

```bash
# Watch GC pauses in real-time
node --trace-gc --max-old-space-size=4096 --max-semi-space-size=64 app.js 2>&1 |
  awk '/Scavenge|Mark-sweep/ {print strftime("%H:%M:%S"), $0}'

# Period sample heap
node -e "
  setInterval(() => {
    const m = process.memoryUsage();
    console.log(JSON.stringify({
      rss: (m.rss/1024/1024).toFixed(1),
      heapTotal: (m.heapTotal/1024/1024).toFixed(1),
      heapUsed: (m.heapUsed/1024/1024).toFixed(1),
      external: (m.external/1024/1024).toFixed(1),
    }));
  }, 5000);
"
```

---

## 7. Benchmarking Strategy

### Step 1: Baseline (no flags)

```bash
# V8 baseline
node --trace-gc app.js 2>&1 | tee baseline-gc.log

# Bun baseline
bun --expose-gc run app.js
```

### Step 2: Vary semi-space

```bash
# Benchmark young gen sizes (the single most impactful flag for agents)
for mib in 16 32 64 128; do
  node --max-old-space-size=4096 --max-semi-space-size=$mib --trace-gc app.js 2>&1 |
    tee semi-${mib}mg.log
done
```

### Step 3: Analyze

```bash
# Extract pause stats from trace-gc logs
grep -E 'Scavenge|Mark-sweep' semi-64mg.log |
  awk '{print $3}' |                            # duration column
  sed 's/ms,//' |
  sort -n |
  awk 'NR==1{min=$1}; END{print "Min:",min,"Max:",$1,"Avg:",sprintf("%.1f",total/NR)}
    {total+=$1}' NR=1
```

### Step 4: Compare metrics

| Metric | Baseline | 16 MB | 32 MB | 64 MB | 128 MB |
|---|---|---|---|---|---|
| Minor GC freq (/min) | | | | | |
| Minor GC avg pause | | | | | |
| Major GC freq (/min) | | | | | |
| Major GC avg pause | | | | | |
| Premature promotion rate | | | | | |
| RSS peak (MB) | | | | | |

---

## 8. Summary: Quick-Start Recommendations

### opencode-vmk (Node.js/V8)

```
ALWAYS set --max-semi-space-size=64 (at minimum) in Node.js v22+
The V8 default of ~1 MB in containers causes pathological premature promotion.
```

```jsonc
// opencode.json agent config
{
  "agent": {
    "opencode-vmk": {
      "env": {
        "NODE_OPTIONS": "--max-old-space-size=4096 --max-semi-space-size=64 --initial-old-space-size=1024 --expose-gc"
      }
    }
  }
}
```

### gentleman-vMK (Bun/JSC)

Bun's adaptive GC controller is already well-suited for interactive workloads. The main leverage points:

1. **Use `--expose-gc`** for strategic `Bun.gc(true)` after large context swaps
2. **Tune `BUN_GC_TIMER_INTERVAL=500`** for more responsive GC scheduling
3. **Monitor `heapStats()`** from `bun:jsc` for object-type retention analysis
4. **Watch for JSC upstream GC leaks** (tracking #28343) â€” periodic full GC may be needed as mitigation until WebKit fixes land

### Universal

1. Profile before tuning â€” defaults are good until they're not
2. The largest lever is **reducing allocation rate** in agent code (pooling, streaming, pruning context)
3. Major GC pause > 200 ms is user-noticeable during streaming â€” tune or refactor
4. Set heap limit to 50â€“60% of container RAM, never 100%
