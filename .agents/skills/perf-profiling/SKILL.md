---
name: perf-profiling
description: "Trigger: performance profiling, slow queries, N+1, memory leak, CPU hotspot, query optimization. Audit with measurement."
triggers: "performance profiling, slow queries, N+1, memory leak, CPU hotspot, profiling, query optimization"
---
## When to Use
Performance profiling, slow queries, memory leaks, CPU bottlenecks. If no performance issue → report and stop.

## STEP 1: MEASURE (before grep)
- **Go**: `go test -bench=. -benchmem -cpuprofile=cpu.prof`
- **Python**: `python -m cProfile -o prof.out script.py` / `py-spy top --pid PID`
- **Node**: `node --prof app.js` / `clinic flame -- node app.js`
- **Browser**: Chrome DevTools Performance → flame chart
- No profiling? → Fall back to grep, note limitation.

## SCAN DIMENSIONS (grep fallback)

**Code**: `grep -rn "for.*in.*for\|while.*while\|\.reduce\|\.map.*\.map" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` → O(n²+)

**DB (N+1)**: `grep -rn "\.find\|\.findMany\|\.findFirst\|createQueryBuilder\|select()" --include="*.ts" --include="*.js" --include="*.py"` → N+1 (Prisma, TypeORM, SQLAlchemy 2.0)

**Network**: `grep -rn "fetch\|axios\|http\.get\|requests\.\|urllib" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` → sequential calls, missing pooling

**Concurrency**: `grep -rn "goroutine\|async.*await\|Promise\|Thread" --include="*.go" --include="*.ts" --include="*.js" --include="*.py"` → leaks, deadlocks

**Memory/Frontend**: `grep -rn "addEventListener\|setInterval\|setTimeout\|innerHTML" --include="*.ts" --include="*.js"` → leaks

## ROI MATRIX
| Bottleneck | Impact | Effort | Priority |
|-----------|--------|--------|----------|
| N+1 query | HIGH | LOW | P1 |
| Missing index | HIGH | LOW | P1 |
| Sequential API calls | HIGH | MED | P1 |
| Synchronous DB | MED | MED | P2 |
| Memory leak | MED | HIGH | P2 |
| Unoptimized render | MED | MED | P2 |

## OUTPUT
```
### Performance Audit
| Bottleneck | Location | Impact | Fix | ROI |
### Findings
- P1: [finding + evidence]
- P2: [finding + evidence]
```

## Rules
1. Measure before optimize (profiling first, grep second). 2. Focus P1s. 3. Every finding: file:line + evidence.

## Refs
performance · performance-tracker · data-quality

## Anti-Patterns
Grep-only profiling · Skip measurement tools · Ignore network I/O · No before/after benchmark · Miss modern ORM patterns
