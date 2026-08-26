# Improvement Cycle Manifest

> Inspired by autoresearch (Karpathy) `program.md` — defines scope, metrics, and loop behavior.
> Auto-loaded by `self-improvement` skill on cycle start.
> Only edit this file to change cycle direction. Do NOT edit while cycle runs.

## Objective

**Cycle 28** (ACTIVE): Security hardening + quality recovery — implement findings from global analysis (2026-07-29). Restore 4 score dims at 0.0. Compress skills >3KB. **Target**: 9.3→9.5/10 (current: 9.3/10, 4 dims restored).

**Previous**: Cycle 27 — Deep audit, fix, and refactor del repo. **Result**: SUCCESS (10/10 backlog, score 9.1/10 → 6.2/10 post-close).

### Backlog

| # | Item | Impact | Risk | IR | Est | Status | Done Criteria |
|---|------|--------|------|----|-----|--------|---------------|
| 1 | Fix multiline pipeline bug in score-dims.ps1 (CC/BP dims) | High | Low | 3 | 30m | ✅ Done | `!score` reports CC>9, BP>9 |
| 2 | Integration tests for score-auto.ps1 | Medium | Low | 2 | 1h | ✅ Done | `ScoreIntegration.Tests.ps1` with 11+ tests all pass |
| 3 | Fix pre-commit hook numbering consistency | Low | Low | 1 | 15m | ✅ Done | Hook prints [1/12]–[12/12] |
| 4 | Fix e2e pipeline tests (hook + execution state) | Medium | Low | 2 | 15m | ✅ Done | `e2e_pipeline.Tests.ps1` 24/24 pass |
| 5 | Skill compression (>3KB skills) | Medium | Medium | 1 | 3h | ✅ Done | 0 skills >3KB (SE 8.0→10.0); avg 2.5KB |
| 6 | Compress/merge non-junction skills | Low | Medium | 0.5 | 2h | 🔴 Pending | 0 non-junction skills |

## Pilares
1. **Script Performance** — reduce avg script size from 6.4KB to <5KB. Compress scripts >8KB. (✅ Cycle 8)
2. **Score expansion** — implement sub-dimension taxonomy to break the 10.0 ceiling on key metrics. (✅ Cycle 8)
3. **Clean Code refinement** — add `[Parameter(Mandatory)]` to remaining script without params → 36/36. (✅ Cycle 8)
4. **Skill Resolution** — BFS resolution with keyword scoring + 13-route agent routing table. (✅ Cycle 9)
5. **PSSA Zero-Warnings** — Fix BOM + replace aliases → <50 real PSSA warnings. (🟢 Cycle 10 active)
6. **Doc Sync & Automation** — README/CHANGELOG actualizados, BITACORA limpia, upstream integrado. (🟢 Cycle 10 active)

## Metrics

| Metric | Target | Tracked By |
|--------|--------|------------|
| inter(30) | >=30 meaningful interactions | `scripts/inter-track.ps1` |
| Score delta | maintain >=9.5 (new dims may shift), target >=9.8 | `scripts/score-auto.ps1` |
| Backlog Integrity | 0 items with status ≠ reality | auto-check on cycle start |
| Score freshness | ≤1 day since last .project.json update | `git log -1 -- .project.json` |
| Automation claims verified | 100% of claims pass smoke test | per-claim smoke script |
| Subagent delegations per session | >=3 delegations (3 verificación siempre) | bitacora + engram |
| Dreaming auto-trigger | fires on every 5th self-check | Learning Loop (unconditional) |
| Skill sizes | 0 >3KB, avg <2.0KB | `scripts/benchmark.ps1` (current: avg 2.5KB, 0 >3KB ✓) |
| Working tree hygiene | 0 cambios sin commit al cerrar ciclo | `git status --short` |
| Cross-ref | 0 errors | `scripts/cross-ref-check.ps1` |

## Impact/Risk Scoring

| Score | Impact | Risk |
|-------|--------|------|
| High (3) | Direct score improvement, unblocks work | Cross-cutting, high breakage potential |
| Medium (2) | Quality/efficiency gain | Touches multiple files, needs verify |
| Low (1) | Cosmetic, nice-to-have | Isolated change, easy revert |

**Priority = Impact / Risk**. Execute high-priority first. Skip items with Risk > Impact (I/R < 1.0).

## Subagent Delegation Rules

1. Partition independent work -> one subagent per item
2. Run parallel subagents with isolated context
3. Each subagent returns: Decision Taken + Files Changed + Key Findings + Nuance
4. Orchestrate: merge results, resolve conflicts, verify coherence
5. Log each delegation to bitacora + inter-track++

**Exception**: Single-file, low-risk edits (config, docs) -> do directly.

## Sub-Dimension Taxonomy (Score Expansion)

32 sub-dimensions across 12 dimensions, computed by `score-auto.ps1`. Each scores 0-10.
Averages into **Score Depth** dimension (13th dim) for granularity beyond 10.0 ceiling.

| Dimension | Sub-dims | How they're scored |
|-----------|----------|-------------------|
| Project Artifacts | readme, changelog, cross_ref, skills, project_json, roadmap | Each artifact exists → 10, missing → 0. Skills: min(SC/6, 10) |
| Security | crypto, secrets | crypto: weak crypto present → 5 else 10. secrets: secrets found → 3 else 10 |
| Dead Code | orphans, junctions, commented | ≤0→10, ≤5→7, else→5. Junctions: 0→10 else 7 |
| Clean Code | help_rate, param_rate, strict_rate | (count/total) × 10 each |
| Best Practices | param_cov, trycatch | (count/total) × 10 each |
| Orthography | corruption | files=0→10, ≤5→9, ≤10→7, else→4 |
| Bitacora | exists, content | exists→10 else 0. content: min(lines/2, 10) |
| Metrics | metrics_dir, errors_dir, error_json, reports | each exists→10 else 0 |
| Script Performance | count, avg_size, huge | count 15-60→10 else 7. avg ≤10KB→10. huge=0→10 |
| Skill Effectiveness | skill_count, over_3kb, over_5kb, skill_avg | ≥60→10. 0 over→10. avg ≤2.0KB→10 |
| Cycle Activity | inter_ratio | min((IC/IT)×10, 10) |
| Backlog Integrity | integrity | passed/total × 10 |

## Difficulty -> Triple-Verify Mapping

| Level | Example | Verify Required | Time Budget |
|-------|---------|-----------------|-------------|
| Facil | docs/config only | E2 (static) only | 2 min |
| Medio | test fixes, minor tweaks | E1 (test) + E2 | 5 min |
| Medio-Dificil | refactors, new small features | E1+E2+E3 (build) | 10 min |
| Dificil | new skills, scripts | Full + 4R review | 15 min |
| Complejo | cross-cutting changes | Full + judgment-day | 30 min |
| Muy Complejo | architectural decisions | Full + SDD cycle | 60 min |

> **⚠️ Para ciclos de mejora**: esta tabla se reemplaza por **SIEMPRE 3 subagentes** sin excepción, sin importar la dificultad.

## External Repos (re-check on cycle start)

| Repo | What to Check | Last Verified |
|------|---------------|---------------|
| karpathy/autoresearch | New program.md patterns, loop improvements | 2026-06-30 |
| Gentleman-Programming/gentleman-guardian-angel | New caching strategies, AGENTS.md compliance checks | 2026-06-17 (v2.8.1) |
| gentle-ai ecosystem | New MCP servers, backup systems | 2026-06-30 |
| engram (MCP) | Cloud sync, new query types, performance | 2026-06-30 |

## Cycle Loop

```
LOOP:
  1. READ CYCLE.md — understand objective and constraints
  2. DIAGNOSE: score, gaps, skill sizes, cross-ref, PSSA; check `.project.json` freshness
  3. SCORE backlog items by Impact/Risk (I/R = Impact / Risk)
  4. IDENTIFY fix candidates sorted by I/R descending
  5. PARTITION independent work -> 3 parallel subagentes de verificación
  6. EXECUTE:
     a. Delegate a 3 subagentes para verificar gaps
     b. Cada subagente retorna: Hallazgos + Archivos + Decisiones + Evidencia
     c. Log a bitacora + inter-track++
  7. ORCHESTRATE: merge resultados de 3 subagentes, verificar coherencia
  8. VERIFY: re-score, comparar delta
  9. If score improved → Keep changes, advance baseline
  10. If score drop >0.5 from baseline → full revert (`git checkout -- .` + `git stash drop`); else → review and decide
  11. LEARN: engram, anti-patterns, CYCLE.md notes
  12. REPORT: escribir `docs/ciclos/cycle<N>-YYYYMMDD.md` con hallazgos estructurados
  13. SCORE AUTO-UPDATE: `score-auto.ps1 -Json | Set-Content .project.json`
  14. If inter>=30 AND no dim<9.0 → SUCCESS; time budget (7d) exhausted → STOP; score drop >0.5 → revert
```

## Exceptions

- **NEVER STOP** on single fix failure — revert and try next
- **NEVER ask** "should I continue" — cycle runs autonomously
- **DO ask** if: new external dependency needed, architectural decision, or confidence < 0.7 on conflict judgment

## Cycle History

| Cycle | Name | Score | Key Wins |
|-------|------|-------|----------|
| 6 | Metric Integrity | 9.7/10 | Backlog integrity metric, automation smoke tests |
| 7 | Score Accuracy | 10/10 | Score sync, script compression, README rewrite |
| 8 | Script Performance | 9.9/10 | Avg <5KB, sub-dim taxonomy, StrictMode |
| 9 | Skill Resolution Engine | 10/10 | BFS resolver, 13-route table, regex routing |
| 10 | Full-Spectrum Quality | 10/10 | PSSA zero, doc sync, upstream integration |
| 11 | Deep Pipeline & Learning | 9.9/10 | Capture-learnings, cross-ref restored |
| 12 | Infrastructure Hardening | 10/10 | Ponytail levels, PS7.6 migration, drift cache |
| 13 | Score Recovery | 9.9/10 | Skill compression recovery, bias calibration |
| 14 | Score Perfection | 10/10 | Script Performance 10.0, caveman cleanup |
| 15 | Bias Calibration Loop | 10/10 | Hard gate in close-session + auto-metrics |
| 16 | External Improvement | 10/10 | 5-phase external improvement protocol |
| 17 | Portability & Research | 10/10 | setup-machine, dev-server, 3 research docs |
| 18 | Stabilization | 9.3/10 | install.ps1 fix, .project.json SSoT |
| 19 | Deep Clean & Bridge v2 | 9.3/10 | Root 19→14 files, 6 zombies purged |
| 20 | Agent Optimization | 9.3/10 | AGENTS.md 20KB→14.8KB, context-watchdog |
| 21 | Universal Optimization | 9.2/10 | codebase-memory-mcp, pre-commit+trufflehog |
| 22 | Score Recovery & Deep Quality | 9.2/10 | BITACORA dedup, 35 sub-dims, bloat gate |
| 23 | Score Consolidation | 9.3/10 | score-dims split (−514 lines), 14 skills compressed |
| 24 | Cross-Project Wisdom | 8.8/10 | wisdom store/loader/forge/demote, 5 smoke tests |
| 25 | Karpathy Compression | 9.1/10 | 15 skills compressed via 4 parallel subagents |
| 26 | Skill Merge & DCP | 9.2/10 | 4→1 UI skills (−46%), stale detection 5 signals |
| 27 | Audit Cleanup & Enrichment | 9.1/10 | 128 stale dirs, 3 scripts refactored, 10 skills expanded |
| 28 | CI Resurrection & Toolchain Freedom | 9.9/10 | quality-gate 24d startup_failure fixed, ADR-046 toolchain freedom, benchmark-regression revived, permission suites unified 157/157 |

## Archived Cycles

- Cycles 6-17: `.archive/ciclos/cycle-archive-6-17.md`
- Cycles 18-26: `.archive/ciclos/` — `cycle18-20260704.md` … `cycle26-20260709.md`
- Cycle 27: cycle artifacts pending archive

Only the current cycle is maintained in this file for active reference.

## Author

gentleman-vMK — Cycle 1 (infrastructure) 2026-06-17. Cycles 2-27: see history above.
