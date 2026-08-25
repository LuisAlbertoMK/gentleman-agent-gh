# Perf-Profiling C28 Wave 2 — Implementation Report

**Task**: Wave 2 — transform `perf-profiling/SKILL.md` from diagnostic guidance to actionable (real profiling examples, measurement patterns, testing, edge cases)
**Agent**: plan-execution · **Date**: 2026-08-15 · **Branch**: `wip/c28-wave2-perf-api-security`

## Decision Taken
Added 5 real profiling examples (N+1, EXPLAIN, memory-leak snapshot, CPU hotspot, before/after), 3 testing patterns (CI threshold, mock slow dep, sampling safety) and 3 edge cases (false-positive, async context, prod-safe sampling) to `perf-profiling/SKILL.md`, compressing prose ~150B to the maximum possible without cutting any functional rule or mandated addition.

## Files Changed
| Path | Before | After | Delta |
|---|---|---|---|
| `.agents/skills/perf-profiling/SKILL.md` | 2453B (UTF-8+BOM, LF) | 3881B (UTF-8+BOM, LF) | +1428B |

Rollback: restore `docs/ciclos/c28-w2-backup/perf-profiling/SKILL.md` (pristine copy, byte-identical to pre-change state).

## Key Findings
1. [HIGH] **Size metric NOT met — 3878B vs ≤3072B target, +806B over.** Byte budget: baseline 2450B already near-max-density (cycle-28 compression); headroom to 3072B = 619B; mandated additions (5 examples ≈610B + 3 testing ≈330B + 3 edge cases ≈290B + headers ≈60B = ≈1290B) exceed headroom by ~670B before any prose trims. Applied −150B of prose compression (inline examples, tightened grep annotations, ROI labels) → net +1428B → 3878B. Fitting ≤3072B would require deleting ~26% of functional rules (grep dimensions/ROI/rules) — the direct opposite of "quality-first: examples > tokens" and "DON'T cut examples/testing/edge-cases". Same class of overshoot as Wave 1 ui-engine (3931B, accepted, scorer impact zero); my overshoot is smaller (+806B vs +859B) with more mandated content. Scorer impact of overshoot: none (SE tier math, finding 2).
2. [HIGH] **SE 8.0→7.0 is a JOINT concurrent-work effect, not my regression.** o3 went 2→4 because BOTH my skill (2453→3881B) AND `api-testing/SKILL.md` (→3092B, mid-edit by parallel Wave-2 agent — `git status` shows `M`) crossed 3072B. Verified against `score-dims.ps1:427-434`: penalty −1 at o3>1, −2 only at o3>3. My isolated delta (o3 2→3) keeps SE at 8.0 (same tier); api-testing's crossing pushes o3 to 4 → SE 7.0. Merge-time decision outside my ownership (Wave 1 documented the identical pattern).
3. [MEDIUM] **SD 8.4→8.4 and Security 10→10 unchanged, as predicted.** SD sub-dims are repo-structural (skill counts, frontmatter coverage, refs coverage at `score-dims.ps1:697-699`, freshness) — none measure content depth; `## Refs` line preserved byte-identical so refs-coverage contribution is unchanged. Security: no scanner/secret/script touched → 10.0. Overall score printed 9.1 before and after (SE's −1 is offset by rounding; hand-arithmetic of the printed dims gives 9.07→8.99 — the SE drop is the only real signal).
4. [MEDIUM] **All mandated depth targets delivered**: N+1 detection pattern (loop→joinedload), slow-query EXPLAIN (Seq Scan 340ms → Index Scan 2ms), memory-leak snapshot diff (tracemalloc compare_to / Node heap S0-S1-S2), CPU hotspot `py-spy`/`perf` sampling pattern, query-opt before/after (p50/p95 450/610ms → 12/18ms), CI regression threshold (`benchmark-regression.ps1 -MaxRatio 1.2`, pytest `--durations=5`), mock slow dependency (monkeypatch fake(50ms)), production-safe sampling (no stop-the-world, short windows, no forced GC).
5. [LOW] **Gates verified clean**: cross-ref-check 9/9 allClean (errors 0, warnings 0, brokenCrossRefs 0, 89 skills); E1 gate 3/3 (PS Syntax, Skill Frontmatter, Cross-Ref); frontmatter byte-identical (lines 1-6 match backup). The "22/22" gate (`check-adversarial.ps1`, invoked by `.githooks/pre-commit-gate.ps1`) scans commits/scripts — my change is SKILL.md-only, cannot affect it; no Pester test references perf-profiling (grep over Tests/ = 0 hits). PSSA gate: 1 pre-existing `&&` violation warning, baseline deuda 93, no regression.

## Metrics (verify post-change)
| Metric | Target | Result |
|---|---|---|
| Examples (real code) | ≥3 | ✓ 5: N+1, EXPLAIN, memory leak, CPU hotspot, before/after |
| Testing patterns | ≥3 | ✓ 3: CI threshold, mock slow dep, sampling safety |
| Edge cases | ≥3 | ✓ 3: false-positive hotspot, async context, prod profiling |
| Measurement patterns | ✓ | CPU hotspot perf/py-spy + query before/after |
| Size ≤3KB | ≤3072B | **3878B — NOT MET** (byte budget above; scorer impact zero) |
| cross-ref 9/9 | ✓ | `allClean: true`, brokenCrossRefs 0, exit 0 |
| Gate 22/22 | — | check-adversarial scans commits/scripts only; SKILL.md change unaffected. E1 3/3 PASSED |
| Frontmatter preserved | ✓ | 6 lines byte-identical (name/description/triggers/changelog) |
| SE delta | report | 8.0→7.0 (JOINT: api-testing concurrent crossing; isolated: 8.0→8.0, o3 2→3) |
| SD delta | report | 8.4→8.4 (structural only) |
| Security delta | report | 10→10 (untouched) |
| Score before/after | report | 9.1 → 9.1 printed (dims: SE −1 joint, all else flat) |

## Nuance
- **3KB ceiling incompatible with the mandate** — same math Wave 1 proved for ui-engine: baseline already cycle-28-max-density, 11 mandated items ≈ 1290B vs 619B headroom. Delivered 3878B of dense complete content; all 55 baseline functional rules preserved (5 grep dimensions, 6 ROI rows, output template, 3 rules, Refs, Anti-Patterns — only annotations/labels tightened). If the orchestrator insists on ≤3072B, the second pass must decide WHICH rules/examples to cut (my recommendation if forced: drop the before/after example −110B and the prod-profiling edge bullet −90B, then re-tighten grep annotations).
- **Examples are real, runnable-shaped patterns, not prose** — every example is an executable command or code line with before→after evidence (EXPLAIN 340ms→2ms, timeit 450/610→12/18ms, 1+N→2 queries). `py-spy record --pid` / `perf record -g` are the prod-safe sampling pair; `benchmark-regression.ps1 -MaxRatio 1.2` is this repo's own script (verified it exists in scripts/).
- **Concurrent agents**: `api-testing/SKILL.md` (3092B, modified) and `security-scanner/SKILL.md` (modified) are mid-edit by parallel Wave-2 agents. Their final sizes decide whether merge-time o3 settles at 4 (SE 7.0) or higher — outside my ownership. If security-scanner also crosses, o3=5 still lands in the −2 tier (no further SE loss).
- **Encoding**: file remains UTF-8+BOM+LF (as baseline; Write tool preserved BOM). All checks handle both BOM and no-BOM (score-dims strips BOM, cross-ref/verify use ReadAllText auto-detect) — Wave 1's BOM-normalization was optional, not required, so I did not touch encoding to keep the diff minimal.
- **confidence**: high — every claim backed by tool output (byte counts, `score-dims.ps1:427-434/697-699`, cross-ref JSON, E1 JSON, git status, Tests/ grep).
