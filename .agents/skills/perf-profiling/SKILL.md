---
name: perf-profiling
description: "Trigger: performance profiling, slow queries, N+1, memory leak, CPU hotspot, query optimization. Audit with measurement."
triggers: "performance profiling, slow queries, N+1, memory leak, CPU hotspot, profiling, query optimization"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2166
---
## When to Use
Performance profiling, slow queries, memory leaks, CPU bottlenecks. No perf issue → report and stop.
## STEP 1: MEASURE (before grep)
- **Go**: `go test -bench=. -benchmem -cpuprofile=cpu.prof` · **Python**: `python -m cProfile -o prof.out` / `py-spy top --pid` · **Node**: `node --prof app.js` / `clinic flame` · **Browser**: DevTools Performance. No profiler → grep fallback, note limitation.
- **No pwsh7/hardware** → `scripts/perf-offline-fallback.ps1 -Json` (5.1, offline estimate via script count/size, no hardware needed).
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
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
performance · performance-tracker · data-quality
## Anti-Patterns
Grep-only profiling · Skip measurement tools · Ignore network I/O · No before/after benchmark · Miss modern ORM patterns
> docs/skills/perf-profiling/reference.md

