---
name: perf-profiling
description: "Trigger: performance profiling, slow queries, N+1, memory leak, CPU hotspot, query optimization. Audit with measurement."
triggers: "performance profiling, slow queries, N+1, memory leak, CPU hotspot, profiling, query optimization"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
Performance profiling, slow queries, memory leaks, CPU bottlenecks. No perf issue → report and stop.

## STEP 1: MEASURE (before grep)
- **Go**: `go test -bench=. -benchmem -cpuprofile=cpu.prof`
- **Python**: `python -m cProfile -o prof.out script.py` / `py-spy top --pid PID`
- **Node**: `node --prof app.js` / `clinic flame -- node app.js`
- **Browser**: Chrome DevTools Performance → flame chart
- No profiler? → grep fallback, note limitation.

## EXAMPLES (real traces)
**N+1**: `for p in posts: u = db.get(User, p.owner_id)` (1+N) → fix joinedload/selectin (2 queries)
**Slow query (EXPLAIN)**: `EXPLAIN ANALYZE SELECT * FROM orders WHERE status='open';` → `Seq Scan 2M rows 340ms`; fix `CREATE INDEX idx_orders_status` → `Index Scan 2ms`.
**Memory leak**: py `tracemalloc.start()` → `snap.compare_to(snap0)[:10]` growth; Node heap S0/S1/S2 → diff retained.
**CPU hotspot**: `py-spy record --pid 123 -o flame.svg --duration 30` (prod-safe) · `perf record -g -p 123 -- sleep 30; perf report`
**Before/after**: timeit x1000 p50/p95 450/610ms → 12/18ms (index); report both.

## TESTING (regression-proof)
- **CI threshold**: bench vs stored baseline; fail if p95 > 200ms or ratio > 1.2x (`benchmark-regression.ps1 -MaxRatio 1.2`; pytest `--durations=5`).
- **Mock slow dep**: stub slow I/O, profile logic only: `monkeypatch.setattr(db, "findMany", fake(50ms))` → deterministic, no network.
- **Sampling safety**: py-spy/async-profiler sample without stop-the-world → prod-safe; never run blocking CPU profilers in prod traffic.

## EDGE CASES
- **False-positive hotspot**: one-time init cost > steady-state loop → profile ≥30s; compare self vs cumulative time.
- **Async context**: py-spy shows task/greenlet frames; contextvars lost across await → keep request-id per coroutine, profile per-task.
- **Prod profiling**: short windows (30–60s), off-peak, sampling only, no forced GC; async-profiler for JVM.

## SCAN DIMENSIONS (grep fallback)
**Code**: `grep -rn "for.*in.*for\|while.*while\|\.reduce\|\.map.*\.map" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` → O(n²+)
**DB (N+1)**: `grep -rn "\.find\|\.findMany\|\.findFirst\|createQueryBuilder\|select()" --include="*.ts" --include="*.js" --include="*.py"` → N+1 (Prisma/TypeORM/SQLAlchemy 2.0)
**Network**: `grep -rn "fetch\|axios\|http\.get\|requests\.\|urllib" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` → sequential, no pooling
**Concurrency**: `grep -rn "goroutine\|async.*await\|Promise\|Thread" --include="*.go" --include="*.ts" --include="*.js" --include="*.py"` → leaks/deadlocks
**Memory**: `grep -rn "addEventListener\|setInterval\|setTimeout\|innerHTML" --include="*.ts" --include="*.js"` → leaks

## ROI MATRIX
| Bottleneck | Impact | Effort | Priority |
|-----------|--------|--------|----------|
| N+1 query | HIGH | LOW | P1 |
| Missing index | HIGH | LOW | P1 |
| Sequential API calls | HIGH | MED | P1 |
| Sync DB | MED | MED | P2 |
| Memory leak | MED | HIGH | P2 |
| Render cost | MED | MED | P2 |

## OUTPUT
```
### Performance Audit
| Bottleneck | Location | Impact | Fix | ROI |
### Findings
- P1: [finding + evidence]
- P2: [finding + evidence]
```

## Rules
1. Measure before optimize (profile first, grep second). 2. Focus P1s. 3. Every finding: file:line + evidence.

## Refs
performance · performance-tracker · data-quality

## Anti-Patterns
Grep-only profiling · Skip measurement tools · Ignore network I/O · No before/after benchmark · Miss modern ORM patterns