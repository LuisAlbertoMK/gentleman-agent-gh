# Perf Offline Fallback — Idea

**Date**: 2026-08-27
**Branch**: experimento/weak-point-fix-2026-08-27
**Status**: Implemented

## Problem

`hardware-profile.ps1` requires `#requires -Version 7` (pwsh7). On machines where only
PowerShell 5.1 is available (Windows Desktop, locked-down environments), the performance
profiling capability is completely blocked.

This creates a dependency chain:
```
score-auto.ps1 (SP dimension) → hardware-profile.ps1 → pwsh7
```

If pwsh7 is absent, the SP dimension scores at 0, dragging down the composite.

## Solution

Create `scripts/perf-offline-fallback.ps1` that:

1. **Runs on PS 5.1** — no pwsh7-only features (Start-ThreadJob, ForEach-Object -Parallel)
2. **Never calls pwsh** or `hardware-profile.ps1`
3. **Uses proxy measurements**:
   - Script file count + total size as hardware proxy
   - `.project.json` or `.learnings/score-cache.json` for cached score
   - `Measure-Command` / `[Stopwatch]` over lightweight I/O as speed proxy
4. **Returns JSON** with `score`, `tokenBudget`, `scriptCount`

## Tradeoffs

| Approach | Pros | Cons |
|----------|------|------|
| **This: I/O proxy** | Fast, no external deps, PS 5.1 | Approximation, not real HW detection |
| Full HW detection | Accurate | Requires pwsh7 or CIM (slower) |
| Skip scoring entirely | Simple | Loses SP dimension value |

The I/O proxy is a **reasonable approximation** because:
- Script count/size correlates with project complexity
- `Get-ChildItem -Recurse` speed correlates with disk I/O performance
- Cached score from `.project.json` is already authoritative

## Integration Points

- `score-auto.ps1` SP dimension could call this as fallback when pwsh7 is absent
- `hardware-profile.ps1` output could be cached and read by this script
- Could feed into OpenCode resource profile selection for locked environments

## Files

- `scripts/perf-offline-fallback.ps1` — the implementation
- `docs/mejoras/perf-offline-idea.md` — this document
