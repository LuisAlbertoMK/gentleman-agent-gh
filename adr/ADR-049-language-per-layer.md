# ADR-049: Language per Layer — PS Orchestration, Go Hot Paths

- Status: Accepted
- Date: 2026-09-04
- Evidence: [docs/mejoras/2026-09-04-language-perf-benchmark.md](../docs/mejoras/2026-09-04-language-perf-benchmark.md)

## Context

Hardware constraint (Ryzen 3700U 4C/8T, ~6 GB RAM free, SATA SSD) demands maximum speed
with minimum resource consumption. Benchmarks on real repo data (169 files) show, per CLI
invocation on this machine: pwsh spawn 1355 ms / 88.8 MB, python 110 ms / 12.7 MB,
Go 33 ms / 8.5 MB. File ops: Go 3.6–7.2x faster than PS. Measured gate: `fast.exe --gate`
92 ms vs PS-equivalent ~2–4 s (~96% reduction).

## Decision

1. **PowerShell remains the orchestration layer** — hooks, session scripts, config sync,
   Windows glue (COM/WMI/registry). The bottleneck there is process spawn and IO, not
   language speed; a rewrite yields ~zero gain at high cost/risk.
2. **Go is the default for hot paths** — any script measured doing heavy file I/O,
   scanning, or per-invocation latency-sensitive checks gets ported to Go behind the
   existing compiled CLI pattern (`cmd/fast`, `gentle-batch-edit.go`), evolving toward a
   single mega-CLI with subcommands.
3. **PS fallback is mandatory** for every ported path (established by 90418912) — machines
   without Go/exe degrade gracefully (WARN + slower path), never fail.
4. **Source in git, binaries never** (reinforces 94e914ad): committed binaries are frozen
   and stale-prone; source is modifiable, portable, upstreamable. Rebuild locally with
   `go build`.
5. **New tools default to compact JSON output** — reduces LLM context consumption, the
   scarcest resource in this agent workflow.
6. **Rejected**: full Rust migration (IO-bound workload, dev cost 3–5x for ≤10% gain),
   Python as file-op layer (middle ground, second runtime), Go daemon (complexity > 33 ms gain),
   committed binaries (staleness + platform lock).

## Consequences

- Every future perf-sensitive tool: profile first, port only the measured hot path.
- Spawn-count reduction (batching PS invocations into one Go gate) is the next-biggest
  lever after language choice for hot paths.
- PSSA/PS5-compat policies apply unchanged to the remaining PS layer.
