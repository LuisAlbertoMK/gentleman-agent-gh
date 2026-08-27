# Runbook: OpenCode Resource Monitoring (Windows)

> Quick-reference cheat sheet for monitoring OpenCode CPU / memory / threads on
> Windows 11. Verified with `monitor-opencode.ps1` and `Get-Process` on this
> machine (~14 GB RAM). See also the context-mode knowledge base entry
> `OpenCode-resource-monitor-protocol` (searchable while an agent session is live).

## Quick start

```powershell
# Live resource monitor (CPU + RAM), every 3 seconds
pwsh D:\gentleman-agent-gh\scripts\monitor-opencode.ps1 -Interval 3

# Live thread + memory correlator (PowerShell 7), every 2 seconds
while($true) {
  $p = Get-Process -Name opencode -ErrorAction SilentlyContinue
  if ($p) {
    $p | ForEach-Object {
      $tc = if ($_.Threads) { $_.Threads.Count } else { 0 }
      Write-Host "[$(Get-Date -Format 'HH:mm:ss')] PID:$($_.Id) threads=$tc RSS=$([math]::Round($_.WorkingSet64/1MB,0))MB CPU=$([math]::Round($_.CPU,1))s"
    }
  }
  Start-Sleep -Seconds 2
}
```

> NOTE: run both monitors in **separate** PS7 terminals while OpenCode is active,
> then correlate: CPU 0% + threads<50 + RSS<1.5GB = healthy.

## One-shot snapshot

```powershell
Get-Process -Name opencode |
  Select-Object Id,
    @{n='Threads';e={ if ($_.Threads) { $_.Threads.Count } else { 0 }}},
    @{n='RSS(MB)';e={[math]::Round($_.WorkingSet64/1MB,0)}},
    @{n='CPU(s)';e={[math]::Round($_.CPU,1)}}
```

## monitor-opencode.ps1 parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `-Interval`     | 3      | Seconds between samples |
| `-Threshold`    | 15     | Memory warning % of total system RAM |
| `-MaxSamples`   | 0      | Stop after N samples (0 = unlimited) |
| `-Json`         | off    | Emit machine-readable JSON per sample |
| `-HeapSnapshotMb` | 0    | Trigger heap snapshot if RSS exceeds N MB |
| `-Quiet`        | off    | Exit code only (0=ok, 1=exceeded threshold) |

## Normal ranges (this machine, ~14 GB RAM)

| Metric | Idle | Active load | Warning | Critical |
|--------|------|-------------|---------|----------|
| Total RSS        | 820-900 MB | 1.0-1.5 GB | 2.0-2.5 GB | >3 GB   |
| Parent threads   | 33-38   | 35-45      | 80-150    | >150 stable |
| Subagent threads | 34-38   | 35-40      | 50-80     | >100 |
| CPU % (instant)  | 0 %     | 0 %        | 5-30 %    | >30% sustained |

## Baseline comparison

| Process      | RSS    | Notes |
|--------------|--------|-------|
| Node idle    | 35 MB  | Bare runtime, no context |
| OpenCode idle | 880 MB | Context (skills + prompts + tools) loaded |
| OpenCode active (peak) | 1,008 MB | Brief, recovered by GC |

The ~815 MB delta between Node idle and OpenCode is **loaded context**, not
runtime waste: 78 skills + shared prompt bundles + registry + tool runtimes.

## GC pattern (healthy)

```
13:03:44  PID 6672  threads=36  RSS=1002MB   <- peak
13:03:46  PID 6672  threads=38  RSS=878MB    <- GC released 130 MB
13:04:47  PID 5584  RSS=817MB flat 2+ min   <- subagent context stable (no leak)
```

A visible RSS drop after a peak = the V8/Node garbage collector is reclaiming
memory. Absence of drops + monotonic growth = suspected leak.

## Known issues / gotchas

- `wmic.exe` is **deprecated** in Windows 11 22H2+ and returns no data. Use
  `Get-Process` (PowerShell 7) instead. There is no native thread-count
  fallback via `wmic process` on modern Windows.
- `monitor-opencode.ps1` uses `/proc/<pid>/statm` accuracy on Linux for Bun;
  on Windows it falls back to `Get-Process -WorkingSet64` (accurate RSS).
- The `CPU` column from `Get-Process` is **cumulative seconds since process
  start**, NOT instantaneous %. To see instantaneous %, use the live
  `monitor-opencode.ps1` output (CPU 0.0% = waiting on I/O).
- OpenCode is I/O-bound. Sustained 0% CPU while a task runs is **expected**
  and means the process is blocked on network/LLM I/O, not busy-looping.

## Interpretation quick reference

| Observation | Meaning | Action |
|-------------|---------|--------|
| threads 30-50, RSS<1GB, CPU 0% | Healthy I/O-bound wait | None |
| threads 50-120, RSS 1-1.5GB, CPU 0% | Active tool dispatch | None |
| threads>150 stable, no GC drops | Pool saturated / leak | Restart OpenCode |
| RSS>2GB, monotonic (no drops) | Memory leak | Restart OpenCode |
| CPU>30% sustained (monitor-opencode) | Busy-loop (bug) | Restart OpenCode |
| Subagent RSS flat for 2+ min | Stable, no context leak | None (healthy) |

## Retrieve from context-mode knowledge base

```
ctx_search(queries: ["OpenCode resource monitoring"],
           source: "OpenCode-resource-monitor-protocol")
```

## See also

- `scripts/monitor-opencode.ps1` — primary resource monitor (root of repo)
- `scripts/monitor-subagent.ps1` — subagent-aware snapshot variant
- `docs/mejoras/2026-08-03-security-infra-dx-perf-audit.md` — infra/perf audit background
