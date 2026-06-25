# Memory Leak Detection & Prevention in Long-Running Agents

> **Scope**: opencode-vMK (Bun/Effect.ts) & gentleman-vMK (Bun) agent systems
> **Target**: <512MB RSS, zero leak growth over 8+ hour sessions
> **Date**: 2026-06-23
> **Sources consulted**: 32

---

## Table of Contents

1. [Agent-Specific Leak Patterns](#1-agent-specific-leak-patterns)
2. [Bun/Node Profiling Toolchain](#2-bunnode-profiling-toolchain)
3. [Effect.ts Memory Management](#3-effectts-memory-management)
4. [LLM Session Memory](#4-llm-session-memory)
5. [Cache Eviction Strategies](#5-cache-eviction-strategies)
6. [CI Leak Detection](#6-ci-leak-detection)
7. [Toaster Constraints](#7-toaster-constraints)
8. [Production Monitoring](#8-production-monitoring)
9. [Test Strategies](#9-test-strategies)
10. [Actionable Checklist](#10-actionable-checklist)

---

## 1. Agent-Specific Leak Patterns

### 1.1 Event Listener Accumulation

Every tool call, skill load, and stream subscription in an agent typically registers event listeners. In long-running agents (8+ hr sessions) these accumulate unless explicitly removed.

**Patterns in agent code:**
- `EventEmitter.on()` in `process.on('message')` or `EventSource` for streaming LLM responses â€” each `new EventSource(url)` creates connections
- `addEventListener` in subprocess IPC (`Worker`, `child_process`) without matching `removeEventListener`
- Observer pattern in Effect's `PubSub` without capacity limits

**Detection:** Heap snapshot â†’ look for `EventListener` objects under `(event listeners)` or `(compiled code)`. Use `bun --heap-prof-md` or `node --inspect` Memory panel.

**Fix:**
```typescript
// âŒ Leak
process.on('message', handler);
// handler never removed â€” accumulates per session

// âœ… Fix: use Effect.Listener.add or explicit cleanup
const subscription = process.addListener('message', handler);
// ... later
process.removeListener('message', handler);
```

For Effect.ts, use `Effect.onExit` or `Scope.addFinalizer` to deregister listeners automatically when the fiber ends.

### 1.2 Timer / Interval Leaks

`setInterval` / `setTimeout` without clear â†’ prevents GC of entire closure scope.

**Common in agents:** health-check pings, heartbeat timers, polling loops, retry backoffs.

**Detection:** `process._getActiveHandles()` or `process._getActiveRequests()` show pending timers. Use `clinic doctor` which reports "Event Loop Delay" >100ms as a symptom.

**Fix:** Track all timers and clear on scope exit:
```typescript
// âŒ Leak
setInterval(() => pollServer(), 5000);

// âœ… Fix: Wrap in Effect Schedule with bounded count
Effect.repeat(pollServer, Schedule.recurs(100))
// or
const interval = setInterval(() => pollServer(), 5000);
// ... cleanup
Effect.acquireRelease(
  Effect.sync(() => ({ interval })),
  ({ interval }) => Effect.sync(() => clearInterval(interval))
)
```

### 1.3 Closure Captures

Each closure created inside `forEach`, `map`, or event handlers captures its enclosing scope. If that scope references large objects (LLM responses, tool results, conversation history), those objects stay alive as long as the closure is referenced.

**Worst pattern in agents:** Array of results with anonymous handler closures:
```typescript
// âŒ Leak: each handler keeps whole array alive
results.forEach(result => {
  processResult(result, (err, val) => {
    // this closure captures 'result' and 'results'
  })
})
```

**Fix:** Nullify references after use, avoid capturing large objects in callbacks.

### 1.4 Cache / Map Growth

Unbounded `Map<K,V>` or `Set<T>` for caches is the #1 leak in Node/Bun apps ([source: clinic.js docs](https://www.clinicjs.org/)).

**Agent-specific:** skill registry, tool result cache, prompt template cache, LLM response cache, conversation history, token budget tracking.

**Detection:** `heapUsed` grows monotonically. Heap snapshot shows `Map` entries accumulating.

**Fix options** (from cheapest to most complex):
1. Bounded size â€” `Map` + max capacity + eviction
2. TTL-based â€” auto-expire entries after time
3. WeakRef-based â€” let GC decide

See [Cache Eviction Strategies](#5-cache-eviction-strategies).

### 1.5 Detached DOM / Node objects

Only relevant if the agent runs in a browser/Electron context. But for CLI agents: large object graphs from JSON.parse() of LLM responses can create deep object trees that become hard to GC.

### 1.6 Large String Retention

LLM responses are large strings (1-10K tokens = 4-40KB each). If accumulated in an array or used as Map keys, they prevent GC of potentially large character data.

**Detection:** Heap snapshot â†’ filter by string size. Look for strings > 1KB with unexpected retention paths.

**Fix:** Use `Symbol()` keys for dedup, not string concatenation. Trim history aggressively.

### 1.7 Fiber / Promise Accumulation (Effect.ts)

Effect fibers are ~40 bytes each ([Effect DeepWiki](https://deepwiki.com/Effect-TS/effect/2.2-fiber-based-concurrency)). `Effect.fork` without `Fiber.join` or supervision creates orphan fibers.

**Specific pattern:** `zipLatest` + `async` Stream + non-emitting Stream â†’ infinite fiber creation ([Effect Issue #3200](https://github.com/Effect-TS/effect/issues/3200)).

```typescript
// âŒ Leak: zipLatest with async Stream that never emits
Stream.zipLatest(
  Stream.async<never>(emit => { /* never emits */ }),
  otherStream
)

// âœ… Fix: Always ensure async streams emit or use bounded PubSub
const pubsub = PubSub.bounded<string>({ capacity: 100, strategy: "dropping" })
```

These patterns are documented in Effect's own community hub ([EffectPatterns](https://github.com/PaulJPhilp/EffectPatterns)).

---

## 2. Bun/Node Profiling Toolchain

### 2.1 Quick Comparison

| Tool | Best For | Bun | Node | Command |
|------|----------|-----|------|---------|
| **clinic doctor** | Triage (Â±15s run) | âŒ | âœ… | `npx clinic doctor -- node app.js` |
| **clinic heapprofiler** | Allocation flamegraph | âŒ | âœ… | `npx clinic heapprofiler -- node app.js` |
| **clinic flame** | CPU hot paths | âŒ | âœ… | `npx clinic flame -- node app.js` |
| **clinic bubbleprof** | Async bottlenecks | âŒ | âœ… | `npx clinic bubbleprof -- node app.js` |
| **`bun --heap-prof-md`** | Heap profile on exit | âœ… | âŒ | `bun --heap-prof-md script.ts` |
| **`bun --cpu-prof-md`** | CPU profile in markdown | âœ… | âŒ | `bun --cpu-prof-md script.ts` |
| **`bun --inspect`** | Chrome DevTools (partial) | âœ…âš ï¸ | âœ… | `bun --inspect app.ts` |
| **Node `--inspect`** | Full Chrome DevTools | âŒ | âœ… | `node --inspect app.js` |
| **`Bun.gc(true)`** | Force sync GC + mimalloc cleanup | âœ… | âŒ | In-code |
| **`process.memoryUsage()`** | Raw RSS/heap numbers | âœ… | âœ… | In-code |
| **`0x`** | V8 flame graphs | âŒ | âœ… | `npx 0x -- node app.js` |

### 2.2 Heap Snapshot Analysis

**Node:** Use `node --inspect`, open `chrome://inspect`, go to Memory tab â†’ "Take heap snapshot". Filter by constructor name, look for:
- `(string)` â€” large string accumulation
- `(closure)` â€” leaked closures
- `(array)` / `(object properties)` â€” Map entries
- `Detached DOM tree` â€” if browser context

**Bun:** `bun --heap-prof-md` generates a markdown file on exit with `# Heap Profile` sections listing object counts per type ([Bun docs](https://bun.com/docs/project/benchmarking)). This is the closest Bun has to heap snapshots â€” no interactive DevTools yet, but the markdown output is grep-friendly.

### 2.3 Allocation Tracking

**Node:** Memory panel â†’ "Allocation sampling" records allocations per function. Also `--trace-gc` logs GC events showing frequency and duration.

**Bun:** No direct allocation profiler. Use `--smol` (v2+) to reduce heap baseline and `Bun.gc(true)` after known-heavy operations.

### 2.4 Manual GC Triggers

```typescript
// Node
const used = process.memoryUsage().heapUsed / 1024 / 1024;
if (used > 150) global.gc(); // requires --expose-gc

// Bun
if (process.memoryUsage().rss > 200 * 1024 * 1024) Bun.gc(true);
```

### 2.5 Baseline Tracking

Run both tools and compare against a known-good baseline after each deploy:

```bash
# Node baseline
node -e "console.log(JSON.stringify(process.memoryUsage()))" | node baseline-compare.js

# Bun baseline
bun -e "console.log(Bun.gc(true), process.memoryUsage())"
```

---

## 3. Effect.ts Memory Management

### 3.1 Fiber Economy

- Fibers are ~40 bytes each â€” 10K fibers â‰ˆ 400KB ([Effect DeepWiki](https://deepwiki.com/Effect-TS/effect/2.2-fiber-based-concurrency))
- An Effect is a lazy description (zero cost until run) â€” no GC pressure from creating effects
- OS threads equivalent would be ~8MB for 10K threads (95% reduction with fibers)

### 3.2 Resource Lifecycle via Scope

Effect.ts provides `Scope` + `Effect.scoped` for guaranteed cleanup:

```typescript
// Safe pattern â€” finalizers run in reverse on scope close
Effect.scoped(
  Effect.gen(function* () {
    yield* Effect.addFinalizer(() => Console.log("release conn"))
    const conn = yield* acquireConnection
    return yield* useConnection(conn)
  })
)
```

**Leak-prone patterns:**
- âŒ `Effect.scoped` wrapping only the **acquire** but not the **use** phase
- âŒ `Scope.make()` + `Scope.close()` manually without error handling in between
- âŒ Forgetting `.pipe(Effect.scoped)` on scoped effects

### 3.3 Pool Management

```typescript
// Safe â€” TTL prevents unbounded connection growth
Pool.makeWithTTL({
  acquire: createConnection,
  min: 1,
  max: 5,
  timeToLive: "60 seconds",
})
```

**Leak risk:** `Pool.make` without `timeToLive` â†’ connections accumulate if `max` is high and connections are slow to return.

### 3.4 PubSub / Queue Bounding

```typescript
// âŒ Unbounded â€” message backlog grows with slow consumers
PubSub.unbounded<string>()

// âœ… Bounded â€” backpressure or dropping
PubSub.bounded<string>({ capacity: 100, strategy: "dropping" })
```

**Known issue:** `zipLatest` + `async` Stream + non-emitting Stream creates infinite fibers ([Effect Issue #3200](https://github.com/Effect-TS/effect/issues/3200)). Fixed in recent versions. Always test `zipLatest` with async Streams.

### 3.5 Supervisor Pattern

```typescript
// Supervisor tracks all forked fibers â€” prevents fire-and-forget accumulation
const supervisor = Supervisor.track()
Effect.supervised(supervisor)(Effect.gen(function* () {
  yield* Effect.fork(someWork)
  yield* Effect.fork(otherWork)
  const count = yield* supervisor.value
  // count = 2 â€” known, manageable
}))
```

Use `Supervisor.track()` in development. In production, consider a periodic fiber audit:
```typescript
setInterval(async () => {
  const fibers = await supervisor.value
  if (fibers > 1000) {
    console.error(`WARNING: ${fibers} active fibers â€” possible leak`)
    Bun.gc(true)
  }
}, 60000)
```

### 3.6 Common Effect Leak Patterns Summary

| Pattern | Cause | Fix |
|---------|-------|-----|
| `forkDaemon` without supervision | Orphan fibers continue after parent dies | Use `Effect.fork` (auto-supervise) |
| Unbounded `PubSub` | Message backlog grows without bound | Use `.bounded({ capacity, strategy: "dropping" })` |
| `zipLatest` + async Stream | Infinite fiber creation | Ensure both streams emit; upgrade Effect |
| `Pool.make` without TTL | Connections accumulate | `Pool.makeWithTTL({ timeToLive: ... })` |
| Missing `Effect.scoped` | Finalizers never run | Wrap in `Effect.scoped` |
| Large string in Map/Set key | Big strings prevent GC of value | Use `WeakRef` or bounded LRU |

---

## 4. LLM Session Memory

### 4.1 The Core Problem

Each LLM call accumulates:
1. **Conversation history** (prompts + responses) â€” 4-50KB per exchange
2. **Tool results** â€” could be megabytes for file reads or code generation
3. **Context summary** â€” compressed but still grows
4. **Token usage metadata** â€” array of `{ input, output, timestamp }` records

In a 100-message session, plain accumulation is 0.4-5MB of strings. But with tool results like file reads, it can reach 10-50MB.

### 4.2 Prevention Patterns

**Sliding window:**
```typescript
// Keep only the last N messages as full text, summarize the rest
class SessionHistory {
  private messages: Message[] = []
  private maxContextMessages = 20  // max before summarization
  private summary: string | null = null

  add(msg: Message): void {
    this.messages.push(msg)
    if (this.messages.length > this.maxContextMessages * 2) {
      this.summarize()
    }
  }

  private summarize(): void {
    const excess = this.messages.slice(0, -this.maxContextMessages)
    this.summary = compress(excess)  // LLM call to summarize
    this.messages = this.messages.slice(-this.maxContextMessages)
  }

  getContext(): string {
    return `${this.summary ?? ''}\n${this.messages.map(m => m.text).join('\n')}`
  }
}
```

**Token budget tracking:**
```typescript
// Track by token count, not message count â€” safer for variable-length messages
maxTokens: 4096  // or 8192 for larger models
```

**Snapshot on disk:**
```typescript
// After N exchanges, serialize conversation to SQLite/JSON on disk
// Resume from disk if needed; purge from memory
await Bun.write(this.conversationFile, JSON.stringify(this.messages))
this.messages = []
```

**Use Effect Scope for session lifecycle:**
```typescript
Effect.scoped(
  Effect.gen(function* () {
    const session = yield* Session.create(maxTokens: 4096)
    yield* Effect.addFinalizer(() => session.saveToDisk())
    // ... agent loop ...
    yield* session.close()
  })
)
```

### 4.3 What to Measure

```typescript
setInterval(() => {
  const mem = process.memoryUsage()
  const sessionHeap = this.estimateHeapUsage()
  console.log({
    rssMB: (mem.rss / 1024 / 1024).toFixed(1),
    heapMB: (mem.heapUsed / 1024 / 1024).toFixed(1),
    messages: this.history.length,
    tokens: this.tokenBudget.used,
  })
  if (mem.rss > 400 * 1024 * 1024) this.forceSummarize()
}, 60000)
```

---

## 5. Cache Eviction Strategies

### 5.1 Strategy Comparison

| Strategy | Complexity | Memory Control | GC-Friendly | Use When |
|----------|-----------|----------------|-------------|----------|
| **Bounded LRU** (Map + capacity) | Low | âœ… Exact | âŒ Objects stay alive | Fixed-size cache with known access pattern |
| **TTL-based** (Map + expiry) | Low | âš ï¸ Approximate | âŒ Objects stay alive until expiry | Short-lived data (tool results, API responses) |
| **LFU** (frequency tracking) | Medium | âœ… Exact | âŒ More metadata overhead | Hot data has high reuse (skill lookups) |
| **WeakRef-based** | Medium | âŒ GC decides | âœ… Auto-evicts | Cache where data can be re-fetched |
| **Size-based** (bytes, not count) | High | âœ… Exact | âŒ Must measure | Variable-size cache (LLM responses vary 10x) |
| **Combined** (TTL + capacity) | Medium | âœ… Best | âŒ | Recommended default |

### 5.2 Bounded LRU (Recommended Default)

```typescript
class LRUCache<K, V> {
  private capacity: number
  private cache = new Map<K, V>()

  constructor(capacity: number) { this.capacity = capacity }

  get(key: K): V | undefined {
    if (!this.cache.has(key)) return
    const value = this.cache.get(key)!
    this.cache.delete(key)
    this.cache.set(key, value)  // move to end (most recently used)
    return value
  }

  set(key: K, value: V): void {
    if (this.cache.has(key)) this.cache.delete(key)
    else if (this.cache.size >= this.capacity) {
      // evict least recently used (first key in insertion order)
      const lru = this.cache.keys().next().value
      this.cache.delete(lru)
    }
    this.cache.set(key, value)
  }

  get size(): number { return this.cache.size }
}
```

### 5.3 WeakRef + FinalizationRegistry

```typescript
class AutoCleanCache<K extends object, V extends object> {
  private cache = new Map<K, WeakRef<V>>()
  private registry = new FinalizationRegistry((key: K) => {
    const ref = this.cache.get(key)
    if (ref && !ref.deref()) this.cache.delete(key)
  })

  set(key: K, value: V): void {
    this.cache.set(key, new WeakRef(value))
    this.registry.register(value, key)
  }

  get(key: K): V | undefined {
    const ref = this.cache.get(key)
    if (!ref) return
    const obj = ref.deref()
    if (!obj) { this.cache.delete(key); return }
    return obj
  }
}
```

**When to use:** Skill registry (compiled skill objects can be re-loaded), prompt template cache, tool lookup tables. Do NOT use for data that must always be available or that's expensive to re-create.

**Caution:** GC timing is non-deterministic ([MDN WeakRef](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakRef)). Don't rely on finalizers for correctness.

### 5.4 TTL-Based Cache

```typescript
class TTLCache<K, V> {
  private cache = new Map<K, { value: V; expires: number }>()

  constructor(private ttlMs: number) {}

  get(key: K): V | undefined {
    const entry = this.cache.get(key)
    if (!entry) return
    if (Date.now() > entry.expires) {
      this.cache.delete(key)
      return
    }
    return entry.value
  }

  set(key: K, value: V): void {
    this.cache.set(key, { value, expires: Date.now() + this.ttlMs })
  }
}
```

### 5.5 Size-Based (Byte-Aware)

```typescript
class SizeBoundedCache<K, V extends { byteSize?: number }> {
  private cache = new Map<K, { value: V; bytes: number }>()
  private totalBytes = 0

  constructor(private maxBytes: number) {}

  set(key: K, value: V): void {
    const bytes = value.byteSize ?? JSON.stringify(value).length
    // Evict until enough space
    while (this.totalBytes + bytes > this.maxBytes && this.cache.size > 0) {
      const evictKey = this.cache.keys().next().value
      const evicted = this.cache.get(evictKey)!
      this.totalBytes -= evicted.bytes
      this.cache.delete(evictKey)
    }
    this.cache.set(key, { value, bytes })
    this.totalBytes += bytes
  }
}
```

Best for LLM response caches where response size varies by 10x. Combine with LRU access ordering.

---

## 6. CI Leak Detection

### 6.1 Why CI Detection Matters

Memory leaks in agent systems surface slowly â€” after 2+ hours of use. A 5-minute test suite won't catch them. CI detection must specifically exercise leak-prone paths under controlled baselines.

### 6.2 Approaches

#### Approach A: Heap Baseline Diff

```bash
# 1. Run a workload and capture heap BEFORE
node -e "
  const h1 = process.memoryUsage()
  // Run workload
  const h2 = process.memoryUsage()
  const diff = h2.heapUsed - h1.heapUsed
  console.log(diff > 5 * 1024 * 1024 // >5MB growth = FAIL)
    ? 'FAIL: possible leak'
    : `PASS: ${(diff/1024).toFixed(0)}KB growth`
  )
"
```

**For Bun:**
```bash
bun --smol --heap-prof-md -e "
  // same logic as above
  // Read bun --heap-prof-md output on exit
"
```

#### Approach B: Repeated Workload

```typescript
// test/leak-detection.test.ts
import { describe, it, expect } from 'bun:test'

describe('memory leak detection', () => {
  it('should not grow heap across repeated operations', () => {
    const ops = 1000
    const before = process.memoryUsage().heapUsed

    for (let i = 0; i < ops; i++) {
      performOperation() // your leak-prone function
    }

    const after = process.memoryUsage().heapUsed
    const leakPerOp = (after - before) / ops
    expect(leakPerOp).toBeLessThan(50) // <50 bytes/op = no significant leak
  })
})
```

#### Approach C: GC-Confirmed Diff

For more accurate results, force GC before measurement:

```typescript
function measureGC(): number {
  Bun.gc(true)
  const before = process.memoryUsage().heapUsed
  // run workload
  Bun.gc(true)
  return process.memoryUsage().heapUsed - before
}

// In test: repeat N times, ensure growth doesn't compound
const growth: number[] = []
for (let i = 0; i < 10; i++) {
  growth.push(measureGC())
}
// Growth across iterations should be flat, not trending up
```

#### Approach D: `bun test --isolate`

```bash
# Each test file runs in fresh process â€” prevents cross-test memory bleed
# Use for deterministic per-test baselines
bun test --isolate
```

This is crucial for Bun testing. Documented as `--isolate` flag since Bun 1.1.13 ([The Register, Apr 2026](https://www.theregister.com/software/2026/04/21/bun-1113-out-with-memory-fixes-as-dev-complain-of-leaks/5221154)).

### 6.3 CI Integration (GitHub Actions)

```yaml
# .github/workflows/leak-detection.yml
- name: Run memory leak detection
  run: |
    bun test --isolate test/leak-detection/ --timeout 120000

- name: Check GC stress
  run: |
    NODE_OPTIONS="--expose-gc" node -e "
      // high-frequency allocation + GC stress test
      for (let i = 0; i < 100; i++) setInterval(() => {
        const arr = Array(10000).fill('x')
        if (i % 10 === 0) global.gc()
      }, 10)
      setTimeout(() => {
        global.gc()
        const m = process.memoryUsage()
        console.log(JSON.stringify(m))
        process.exit(m.heapUsed > 300 * 1024 * 1024 ? 1 : 0)
      }, 30000)
    "
```

### 6.4 Thresholds to Track

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| `heapUsed` growth per 1000 ops | > 50 bytes/op | > 500 bytes/op | Fix before merge |
| RSS after 10 min workload | > 200MB | > 400MB | Profile with clinic |
| Active timers | > 50 | > 200 | Clear unused timers |
| Active handles | > 30 | > 100 | Check EventEmitter usage |
| Fiber count (Effect) | > 1000 | > 5000 | Add Supervisor audit |

---

## 7. Toaster Constraints

### 7.1 The Constraints

- **OOM killer**: Process killed instantly at memory limit
- **No swap**: Page faults crash the process
- **Hard limit**: Typically 256MB or 512MB
- **No ballooning**: If RSS reaches limit, you're dead â€” no second chance

### 7.2 Budget Breakdown (256MB Target)

| Component | Budget | Notes |
|-----------|--------|-------|
| Bun runtime + JSC | 13-42MB | `--smol` reduces to ~13MB idle |
| Skills (66 files, strings) | 25-35MB | Can be lazy-loaded |
| Conversation history | 5-20MB | Keep under 4K tokens in memory |
| Tool caches | 5-15MB | Bounded LRU with max 100 entries |
| LLM response buffers | 5-20MB | Stream to disk for large responses |
| Stack, C++ bindings, Buffers | 10-20MB | Buffer allocations outside heap |
| **Reserve** | ~30MB | For GC spikes, fragmentation |
| **Total target** | **~150-180MB** | Leaves headroom |

### 7.3 Hard Ceilings

```typescript
// Node (opencode-vMK)
NODE_OPTIONS="--max-old-space-size=128 --max-semi-space-size=4"

// Bun (gentleman-vMK)
--smol  // JIT: 256â†’64MB, GC heap: 32â†’4MB, RSS: 47â†’13MB (-72%)
```

### 7.4 Proactive OOM Prevention

```typescript
// Poll memory and take action before OOM
const OOM_THRESHOLD = 0.8 * 256 * 1024 * 1024  // 80% of 256MB

setInterval(() => {
  const { rss } = process.memoryUsage()
  if (rss > OOM_THRESHOLD) {
    // 1. Emergency summarization of conversation history
    sessionHistory.emergencySummarize()
    // 2. Clear caches
    skillCache.clear()
    toolResultCache.clear()
    // 3. Force GC
    Bun.gc(true)
    // 4. Log
    console.warn(`OOM prevention: RSS ${(rss/1024/1024).toFixed(0)}MB > 80%`)
  }
}, 10000)  // every 10 seconds
```

### 7.5 Graceful Degradation

If memory is too high, degrade capabilities rather than crash:
- Reduce max context messages from 20 â†’ 5
- Skip token tracking metadata accumulation
- Drop tool result caching entirely (use WeakRef)
- Disable skill auto-load â€” load only explicitly needed skills

```typescript
// Graceful degradation levels
const memoryLevels = {
  green:  { maxMessages: 20, cacheSize: 200, skillsPreload: true },
  yellow: { maxMessages: 10, cacheSize: 50,  skillsPreload: false },
  red:    { maxMessages: 3,  cacheSize: 10,  skillsPreload: false, skipHistory: true }
}

function getMemoryLevel(rssMB: number): keyof typeof memoryLevels {
  if (rssMB > 200) return 'red'
  if (rssMB > 150) return 'yellow'
  return 'green'
}
```

---

## 8. Production Monitoring

### 8.1 Custom Metrics Endpoint

Expose key memory metrics for Prometheus scraping or custom aggregators:

```typescript
// /metrics endpoint
async function getMetrics(): Promise<string> {
  const mem = process.memoryUsage()
  const activeHandles = process._getActiveHandles().length
  const activeRequests = process._getActiveRequests().length

  return [
    `# HELP agent_heap_used_bytes Heap used by V8/JSC`,
    `# TYPE agent_heap_used_bytes gauge`,
    `agent_heap_used_bytes ${mem.heapUsed}`,
    `# HELP agent_heap_total_bytes Heap total allocated`,
    `agent_heap_total_bytes ${mem.heapTotal}`,
    `# HELP agent_rss_bytes Resident set size`,
    `agent_rss_bytes ${mem.rss}`,
    `# HELP agent_active_handles Active libuv handles (timers, sockets)`,
    `agent_active_handles ${activeHandles}`,
    `# HELP agent_active_requests Active libuv requests`,
    `agent_active_requests ${activeRequests}`,
    `# HELP agent_fiber_count Active Effect fibers`,
    `agent_fiber_count ${currentFiberCount}`,
    `# HELP agent_session_message_count Messages in current session`,
    `agent_session_message_count ${sessionHistory.length}`,
    `# HELP agent_cache_entries Total cache entries`,
    `agent_cache_entries ${totalCacheEntries}`,
    `# HELP agent_gc_pause_ms GC pause in last interval`,
    `agent_gc_pause_ms ${lastGCPauseMs}`,
  ].join('\n')
}
```

### 8.2 Prometheus / Datadog Integration

**Prometheus:**
```yaml
# prometheus.yml scrape config
scrape_configs:
  - job_name: 'agent'
    static_configs:
      - targets: ['agent:9464']
```

**Datadog (via agent metrics API):**
```typescript
// Or just use --inspect + Prometheus histogram for GC durations
const observe = (name: string, value: number) => {
  // send to Datadog statsd
  datadogClient.gauge(`agent.${name}`, value)
}
```

### 8.3 Automated Memory Profiling in Production

```typescript
// Take a heap snapshot when RSS exceeds threshold (Node only)
const MEMORY_WARN = 300 * 1024 * 1024  // 300MB

setInterval(async () => {
  const rss = process.memoryUsage().rss
  if (rss > MEMORY_WARN) {
    const snapshot = v8.getHeapSnapshot()
    const file = Bun.file(`heap-${Date.now()}.heapsnapshot`)
    const writer = file.writer()
    snapshot.pipe(writer)
    console.error(`MEMORY WARNING: RSS ${(rss/1024/1024).toFixed(0)}MB â€” snapshot saved`)
  }
}, 30000)
```

**Bun limitation:** No `v8.getHeapSnapshot()` equivalent (JSC doesn't expose it). Use `bun --heap-prof-md` on exit as alternative, or add a SIGUSR2 handler:

```typescript
process.on('SIGUSR2', async () => {
  const mem = process.memoryUsage()
  await Bun.write(`/tmp/memory-sig-${Date.now()}.json`, JSON.stringify(mem, null, 2))
  console.log(`Memory snapshot: RSS=${(mem.rss/1024/1024).toFixed(0)}MB`)
})
```

### 8.4 Periodic Leak Audits

Run these automatically in production (e.g., every hour):
```typescript
async function leakAudit() {
  const before = process.memoryUsage()
  Bun.gc(true)
  const after = process.memoryUsage()
  const recoveryRatio = (before.heapUsed - after.heapUsed) / before.heapUsed
  // Expected: recoveryRatio > 0.1 (10% recovered after GC)
  // If < 0.05 after repeated cycles, likely leak
  return { recoveryRatio, leakPossible: recoveryRatio < 0.05 }
}
```

### 8.5 Alerts

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| RSS > 200MB | âœ… | â€” | Degrade cache |
| RSS > 80% of OOM limit | â€” | âœ… | Emergency summarization |
| GC recovery < 5% over 3 checks | âœ… | â€” | Notify + mark for profiling |
| Heap growth > 1MB/min | â€” | âœ… | Restart process |
| Fiber count > 5000 (Effect) | âœ… | âœ… | Supervisor audit + log |

---

## 9. Test Strategies

### 9.1 What to Test

For each potential leak vector, write one minimal test:

```typescript
// tests/memory-leaks/1-fork-leak.test.ts
import { describe, it, expect } from 'bun:test'

describe('Effect fiber leak', () => {
  it('should not leak fibers across repeated forks', async () => {
    const before = process.memoryUsage().heapUsed

    for (let i = 0; i < 100; i++) {
      await Effect.runPromise(
        Effect.scoped(
          Effect.gen(function* () {
            const fib = yield* Effect.fork(Effect.never)
            yield* Fiber.interrupt(fib)
          })
        )
      )
    }

    // If each fork+interrupt leaks, this will show
    Bun.gc(true)
    const after = process.memoryUsage().heapUsed
    const leaked = after - before
    expect(leaked).toBeLessThan(1024 * 50) // <50KB growth for 100 forks
  })
})
```

### 9.2 Test Categories

| Category | What to Test | Threshold |
|----------|-------------|-----------|
| **Fiber lifecycle** | Fork â†’ interrupt â†’ GC | < 500 bytes/cycle |
| **Conversation history** | Add â†’ summarize â†’ GC | Flat after summary |
| **Cache eviction** | Fill â†’ evict â†’ GC | Flat after eviction |
| **Timer cleanup** | Set â†’ clear â†’ GC | No handle leak |
| **Event listeners** | Add â†’ remove â†’ GC | No listener leak |
| **Pool connections** | Acquire â†’ release â†’ GC | Flat after TTL |
| **Large response** | Process â†’ nullify â†’ GC | < 10KB retained |

### 9.3 CI-Only Tests (Heavy)

These are too slow for `bun test --watch` but should run in CI:

```typescript
// Run with: bun test --timeout 300000 --preload setup-test-timeout.ts
it('should survive 1000 conversation turns without leak', async () => {
  const before = process.memoryUsage().heapUsed

  for (let i = 0; i < 1000; i++) {
    await simulateConversationTurn()
  }

  Bun.gc(true)
  const after = process.memoryUsage().heapUsed
  const leakPerTurn = (after - before) / 1000
  expect(leakPerTurn).toBeLessThan(10) // <10 bytes per turn
}, 300000) // 5 min timeout
```

### 9.4 GC Stress Test

```typescript
it('should handle rapid allocation without OOM', async () => {
  for (let i = 0; i < 500; i++) {
    const large = Array(100000).fill('x')
    await someProcessing(large)
    // Should not grow indefinitely â€” GC should reclaim between iterations
  }
  Bun.gc(true)
  const final = process.memoryUsage().heapUsed
  expect(final).toBeLessThan(100 * 1024 * 1024) // <100MB
})
```

### 9.5 Snapshot Diff Test (Node only)

For opencode-vMK:
```typescript
// Generate two heap snapshots and diff them
import v8 from 'v8'
import { describe, it, expect } from 'bun:test'

it('should produce no new detachments after operation', () => {
  const snapshot1 = v8.getHeapSnapshot()
  performOperation()
  const snapshot2 = v8.getHeapSnapshot()
  // Compare â€” if DetachedDOMTree count increases, leak
  // Implement with heap-snapshot-diff or manual analysis
})
```

---

## 10. Actionable Checklist

### High Priority (immediate impact)

- [ ] **Set `--smol` for gentleman-vMK** â€” cuts baseline RSS ~72%
- [ ] **Set `NODE_OPTIONS="--max-old-space-size=128 --expose-gc"` for opencode-vMK**
- [ ] **Add periodic `Bun.gc(true)` calls** after LLM responses and batch processing
- [ ] **Bound all caches** with LRU + max capacity (100 entries default)
- [ ] **Wrap resources in `Effect.scoped`** with `acquireRelease` â€” audit existing uses

### Medium Priority (next iteration)

- [ ] **Replace `PubSub.unbounded` with `PubSub.bounded`** everywhere
- [ ] **Check all `Effect.fork` calls** â€” prefer `Effect.fork` (supervised) over `forkDaemon`
- [ ] **Add conversation history sliding window** with automatic summarization
- [ ] **Add leak detection tests** to CI (at least baseline diff approach)
- [ ] **Add Supervisor fiber tracking** in dev mode (warning at >1000 fibers)
- [ ] **Stream large file reads** instead of `Bun.file().json()` / `readFileSync`

### Lower Priority (monitor & plan)

- [ ] **Evaluate `WeakRef` caches** for skill registry and prompt template cache
- [ ] **Add metrics endpoint** for Prometheus scraping
- [ ] **Implement graceful degradation** when RSS > 80% limit
- [ ] **Set up production memory alerts** (RSS > 200MB, growth > 1MB/min)
- [ ] **Migrate to Effect v4** for smaller bundle + memory improvements
- [ ] **Profile with clinic heapprofiler** for Node (opencode-vMK) â€” 2x/year or after major changes
- [ ] **Profile with `bun --heap-prof-md`** for Bun (gentleman-vMK) â€” 2x/year

---

## References

| # | Source | URL |
|---|--------|-----|
| 1 | Clinic.js â€” Official docs | https://www.clinicjs.org/ |
| 2 | Clinic.js â€” Heap Profiler | https://www.clinicjs.org/documentation/heapprofiler/ |
| 3 | Effect.ts â€” Scope docs | https://effect.website/docs/resource-management/scope/ |
| 4 | Effect.ts â€” Supervisor docs | https://effect.website/docs/observability/supervisor/ |
| 5 | Effect Issue #3200 â€” zipLatest leak | https://github.com/Effect-TS/effect/issues/3200 |
| 6 | EffectPatterns â€” Community patterns (300+) | https://github.com/PaulJPhilp/EffectPatterns |
| 7 | Effect DeepWiki â€” Fiber concurrency | https://deepwiki.com/Effect-TS/effect/2.2-fiber-based-concurrency |
| 8 | Effect Pool.ts â€” makeWithTTL | https://effect-ts.github.io/effect/effect/Pool.ts.html |
| 9 | Google DevTools â€” Fix memory problems | https://developer.chrome.com/docs/devtools/memory-problems/ |
| 10 | MDN â€” WeakRef | https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakRef |
| 11 | JS.info â€” WeakRef & FinalizationRegistry | https://javascript.info/weakref-finalizationregistry |
| 12 | Node.js â€” Understanding Memory Tuning | https://nodejs.org/en/learn/diagnostics/memory/understanding-and-tuning-memory |
| 13 | V8 â€” Trash Talk: Orinoco GC | https://v8.dev/blog/trash-talk |
| 14 | V8 â€” Orinoco Parallel Scavenger | https://v8.dev/blog/orinoco-parallel-scavenger |
| 15 | Bun docs â€” Benchmarking / profiling | https://bun.com/docs/project/benchmarking |
| 16 | Bun API â€” `Bun.gc()` | https://bun.com/reference/bun/gc |
| 17 | Lucio DurÃ¡n â€” Bun v2 Runtime Internals | https://lucioduran.com/blog/bun-v2-runtime-internals-deep-dive |
| 18 | The Register â€” Bun 1.1.13 memory fixes | https://www.theregister.com/software/2026/04/21/bun-1113-out-with-memory-fixes-as-dev-complain-of-leaks/5221154 |
| 19 | DEV.to (Axiom) â€” Node.js profiling | https://dev.to/axiom_agent/nodejs-performance-profiling-in-production-v8-flame-graphs-clinicjs-and-heap-snapshots-2d70 |
| 20 | HireNodeJS â€” Clinic.js profiling 2026 | https://www.hirenodejs.com/blog/nodejs-clinic-js-profiling-2026 |
| 21 | Red Hat â€” Node.js memory in containers | https://developers.redhat.com/articles/2025/10/10/nodejs-20-memory-management-containers |
| 22 | Zoer.ai â€” Bun vs Node mem comparison | https://zoer.ai/posts/zoer/bun-vs-nodejs-memory-usage-comparison |
| 23 | froxell.com â€” Bun vs Node 2026 | https://www.froxell.com/blog/bun-runtime-breakdown-nodejs-2026 |
| 24 | OneUptime â€” Optimize Bun performance | https://oneuptime.com/blog/post/2026-01-31-bun-performance-optimization/view |
| 25 | dev.to (Shafayet) â€” TS performance | https://dev.to/shafayeat/performance-optimization-with-typescript-dcj |
| 26 | Node.js â€” GC Traces | https://nodejs.org/en/learn/diagnostics/memory/using-gc-traces |
| 27 | Node.js â€” Using Heap Profiler | https://nodejs.org/en/learn/diagnostics/memory/using-heap-profiler |
| 28 | Node.js â€” Using Heap Snapshot | https://nodejs.org/en/learn/diagnostics/memory/using-heap-snapshot |
| 29 | Effect v4 Beta â€” Bundle size blog | https://effect.website/blog/effect-v4-beta |
| 30 | ACM Queue â€” Idle-time GC | https://queue.acm.org/detail.cfm?id=2977741 |
| 31 | IJIRT â€” V8 Memory for Node.js | https://ijirt.org/publishedpaper/IJIRT182978_PAPER.pdf |
| 32 | PlainEnglish.io â€” WeakRef smarter memory | https://javascript.plainenglish.io/weakrefs-finalizationregistry-smarter-memory-management-in-javascript-366a3acf08f6 |

---

> **Next step**: Implement the checklist items in priority order. Start with runtime flags (`--smol` / `--max-old-space-size`) and bounded caches â€” these are the highest-impact, lowest-effort items.
