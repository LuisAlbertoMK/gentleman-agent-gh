---
description: Quick performance pass over scripts and tests — measure, fix, prove
---

You are executing `!perf`. Quick performance pass over the project's scripts and tests.

Steps:

1. **Load skill**: `perf-profiling`.
2. **Measure baseline**: time the project test suite (prefer `& "$root\scripts\run-tests.ps1"` when available, else the project's test command). Record wall time and peak resource use.
3. **Identify hotspots** in scripts: slow loops, repeated disk/network IO, N+1 patterns, blocking waits, redundant recomputation.
4. **Apply the smallest safe fixes**: reduce IO, parallelize independent jobs, cache repeated computation. Respect the existing style; no refactoring for style alone.
5. **Prove it**: re-run the same test suite; compare before/after. Any failing test = revert that change.
6. **Report**: table `|Area|Before|After|Delta|` plus a one-line note per change.

Only measurable performance wins count. If no hotspot is found, say so instead of inventing work.
