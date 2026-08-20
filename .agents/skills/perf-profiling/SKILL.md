---
name: perf-profiling
description: "Trigger: performance profiling, slow queries, N+1, memory leak, CPU hotspot, query optimization. Audit with measurement."
triggers: "performance profiling, slow queries, N+1, memory leak, CPU hotspot, profiling, query optimization"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Performance profiling, slow queries, memory leaks, CPU bottlenecks. No perf issue → report and stop.

## STEP 1: MEASURE (before grep)
- **Go**: `go test -bench=. -benchmem -cpuprofile=cpu.prof` · **Python**: `python -m cProfile -o prof.out` / `py-spy top --pid` · **Node**: `node --prof app.js` / `clinic flame` · **Browser**: DevTools Performance. No profiler → grep fallback, note limitation.

## EXAMPLES (real traces)
**N+1**: `for p in posts: u = db.get(User, p.owner_id)` (1+N) → joinedload/selectin (2 queries). **Slow query**: `EXPLAIN ANALYZE SELECT * FROM orders WHERE status='open';` → Seq Scan 2M rows 340ms → `CREATE INDEX idx_orders_status` → 2ms. **Memory leak**: py `tracemalloc` snap diff; Node heap S0/S1/S2 retained. **CPU hotspot**: `py-spy record --pid 123 -o flame.svg --duration 30` (prod-safe). **Before/after**: timeit x1000 p50/p95 450/610ms → 12/18ms (index); report both.

## TESTING (regression-proof)
- **CI threshold**: bench vs baseline; fail if p95 > 200ms or ratio > 1.2x (`benchmark-regression.ps1 -MaxRatio 1.2`; pytest `--durations=5`).
- **Mock slow dep**: stub slow I/O, profile logic only — deterministic, no network.
- **Sampling safety**: py-spy/async-profiler sample without stop-the-world → prod-safe; never blocking CPU profilers in prod traffic.

## EDGE CASES
- **False-positive hotspot**: one-time init > steady-state → profile ≥30s; compare self vs cumulative.
- **Async context**: py-spy shows task frames; contextvars lost across await → request-id per coroutine.
- **Prod profiling**: short windows (30-60s), off-peak, sampling only, no forced GC; async-profiler for JVM.

## SCAN DIMENSIONS (grep fallback)
**Code**: nested loops/reduce/map → O(n²+) · **DB**: `.find\|.findMany\|.findFirst\|createQueryBuilder\|select()` → N+1 · **Network**: `fetch\|axios\|http.get\|requests.` → sequential, no pooling · **Concurrency**: `goroutine\|async.*await\|Promise\|Thread` → leaks/deadlocks · **Memory**: `addEventListener\|setInterval\|setTimeout\|innerHTML` → leaks.

## ROI MATRIX
| Bottleneck | Impact | Effort | Priority |
|---|---|---|---|
| N+1 query | HIGH | LOW | P1 |
| Missing index | HIGH | LOW | P1 |
| Sequential API calls | HIGH | MED | P1 |
| Sync DB | MED | MED | P2 |
| Render cost | MED | MED | P2 |

## OUTPUT
`PERF-AUDIT:<date> P1:[finding]+[evidence] P2:[finding]+[evidence]`

## Rules
1. Measure before optimize (profile first, grep second). 2. Focus P1s. 3. Every finding: file:line + evidence.

## Refs
performance · performance-tracker · data-quality

## Anti-Patterns
Grep-only profiling · Skip measurement tools · Ignore network I/O · No before/after benchmark · Miss modern ORM patterns