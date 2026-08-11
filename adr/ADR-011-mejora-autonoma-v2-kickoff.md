# ADR-011: Mejora Autónoma Iterativa v2 — Kickoff

- **Status**: Accepted · **Date**: 2026-08-04 · **Type**: process
- **Context**: Experiment stop condition (§5) met for v1; a v2 protocol was requested to tighten momentum, metrics, and cost-control discipline.
- **Decision**: Adopt the v2 protocol — metrics M1-M9 (Gate 16/16, E2E 702/0, skill sizes avg ≤2,000B & 0 >3KB, Score ≥9.5, PSSA <50 warnings & 0 gate regressions, opencode.json ≤98,304B (= 65,536×1.5 headroom), cross-ref 0 errors, BenchmarkSeconds stable, .project.json freshness ≤1 day); budget max 3 cycles per session block and ≤45 min per cycle; diminishing-return threshold: marginal improvement <10% vs prior cycle → STOP; human checkpoint per cycle; ICE prioritization I×C/E; 3 subagents per cycle.
- **Alternatives**: Continue v1 budget/looser metrics — rejected: v1 lacked a hard diminishing-return stop and per-cycle human checkpoint.
- **Consequences**: Work on branch `experimento/mejora-autonoma-*`; deliverable set `mejora-log.md`/`benchmarks.md`/`adr/`; merge to main only on §5 stop condition via PR.
- **Refs**: `mejora-log.md` §Mejora Autónoma Iterativa v2 — Kickoff; `benchmarks.md` §Mejora Autónoma v2 — Baseline; CYCLE.md:98.