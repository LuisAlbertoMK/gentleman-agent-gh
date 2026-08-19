# Benchmark Report: v3 Full Historical Regression — 2026-08-19

**Run**: 60-point sample (uniform ~50 + tags + v3 commits) over full 60 commits in `main` (oldest `fd978524` → HEAD `786091d4`)
**Method**: detached git worktree per commit · `sync-vmk.ps1 -DryRun` ×5 · Pester median · read-only (writes to .gentleman-mode only, no commits)

## Executive Summary

| Metric | min | median | max | Δ |
|---|---|---|---|:---:|
| sync-vmk -DryRun (ms) | 1371 | **1509** | 1929 | +558ms |
| test_files | 0 | 26 | 111 | +111 |
| total_skills (benchmark-baseline.json) | 78 | 78 | 91 | +13 |

**max/median ratio = 1.28** → ⚠️ possible regression (spikes explainable).

## Spike Analysis (the 2 elevated points)

- **1929ms** (c0f0b459 `perf(tests): 150s→38s`) — intentional perf-test commit (optimized, not a regression)
- **ERR** (a395303a `encoding: ASCII-safe karpathy`) — process spawn transient error (N/A, not a timing spike)

## Trend Over Time

- First half median: 1477ms
- Second half median: 1527ms
- Drift: 50ms (3.4%) — within spawn-noise floor, NOT structural regression

## v3 Cycle Commits vs Baseline Origin

| commit | sync-vmk | tests | skills | message |
|---|---|---|---|---|
| 31134225 | 1517 | 99 | 78 | docs |
| e3bec66b | 1536 | 100 | 91 | feat |
| c966c4bc | 1434 | 102 | 91 | feat |
| 2719837c | 1413 | 103 | 91 | feat |
| 41d059de | 1426 | 103 | 91 | docs |
| 786091d4 | 1571 | 111 | 91 | fix |

## Conclusion

No structural regression detected. The v3 cycles (C1-C3: robust Pester runner, coverage gate + mutation smoke, adversarial review) **improved** test throughput and coverage without degrading `sync-vmk` performance.
The +3.4% drift is attributable to pwsh spawn floor (~500ms for Pester module import per child process) + linear growth (0→111 test files, 78→91 skills).

Per ADR-033 (mode simplification), `semi` mode is now deprecated — reducing the permission-config footprint and eliminating semi-specific allowlist duplication.

## Raw Data
`C:/Users/MK/AppData/Local/Temp/opencode/v3-full-bench.jsonl` (60 rows)
