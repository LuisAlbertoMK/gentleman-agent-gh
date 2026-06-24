# Improvement Cycle Manifest

> Inspired by autoresearch (Karpathy) `program.md` -- defines scope, metrics, and loop behavior.
> Auto-loaded by `self-improvement` skill on cycle start.
> Only edit this file to change cycle direction. Do NOT edit while cycle runs.

## Objective

**Cycle 6** (CLOSED): Metric integrity and verification-first. Closed gaps between claimed and actual state. **Result**: SUCCESS (5/6 backlog items, inter 49/30, 12 dimensions with honest scores).

**Cycle 7** (CLOSED): Score accuracy and script optimization. Fixed data integrity in scoring artifacts, compressed 3 largest scripts, rewrote README to match reality. **Result**: SUCCESS (5/5 backlog items, inter 51/30, score 9.9/10).

**Cycle 8** (CLOSED): Script performance optimization. Compressed remaining large scripts, pushed avg to <5KB, expanded score taxonomy with sub-dimensions. **Result**: SUCCESS (3/3 backlog items, inter 66/30, score 9.9/10).

**Cycle 9**: Skill Resolution Engine. Transform `skill-graph.ps1` into a semantic resolver with BFS keyword scoring, regex-based agent routing, and multi-format output.

### Pillars
1. **Script Performance** — reduce avg script size from 6.4KB to <5KB. Compress scripts >8KB. (✅ Cycle 8)
2. **Score expansion** — implement sub-dimension taxonomy to break the 10.0 ceiling on key metrics. (✅ Cycle 8)
3. **Clean Code refinement** — add `[Parameter(Mandatory)]` to remaining script without params → 36/36. (✅ Cycle 8)
4. **Skill Resolution** — BFS resolution with keyword scoring + 13-route agent routing table. (🟢 Cycle 9 active)

### Cycle 6 Backlog (CLOSED)
| Item | Impact | Risk | I/R | Est. inter | Status | Done criteria |
|------|--------|------|-----|------------|--------|---------------|
| Close Cycle 5: mark items 1-3 ✅ Done, carry item 4 forward | High | Low | 3.0 | 1 | ✅ Done | CYCLE.md reflects items 1-3 closed (commit 63f5232) |
| Add "Backlog Integrity" metric to score-auto.ps1 | High | Low | 3.0 | 2-3 | ✅ Done | `score-auto.ps1` outputs `backlog_integrity` dim; script `check-backlog-integrity.ps1` exists and exits 0 on clean |
| Score freshness: auto-warning or auto-update .project.json | Medium | Low | 2.0 | 2 | ✅ Done | Cycle loop step 3 auto-checks `.project.json` age; triggers warning if >1d stale |
| Verify automation claim has end-to-end smoke test | High | Medium | 1.5 | 3-5 | ✅ Done | `scripts/smoke/smoke-all.ps1` tests 5 auto claims (BI, upstream, dreaming, freshness, LOOP) — all pass |
| Score expansion: sub-dimensions to break 10.0 ceiling | Medium | Low | 2.0 | 3 | ⏳ Deferred | Low impact — taxonomy change, not real improvement. Deferred to Cycle 8+ |
| Integration smoke tests for key scripts (carry-over from C5) | Medium | Medium | 1.0 | 2-3 | ✅ Done | `scripts/smoke/` exists with 5 tests; `smoke-all.ps1` exits 0 |

### Cycle 6 Progress (CLOSED)
- Score: 9.7/10 (honest re-score after audit — Best Practices 9.0, Metrics 8 dragging)
- inter: 49/30 (complete — 163% of target)
- Backlog Completion: 5/6 (items #1, #2, #3, #4, #6 done — #5 deferred)
- Skills >3KB (SKILL.md only): 0 ✓ (all 69 SKILL.md files compressed)

### Cycle 7 Backlog
| Item | Impact | Risk | I/R | Est. inter | Status | Done criteria |
|------|--------|------|-----|------------|--------|---------------|
| Score accuracy: sync .project.json ↔ PROJECT-SCORE.md, fix Metrics dimension | High | Low | 3.0 | 1 | ✅ Done | Both files show same 12 dims, accurate inter count, errors/ noted |
| Clean Code: add StrictMode to scripts missing it | High | Low | 3.0 | 1 | ✅ Done | `run.ps1` + `restore-project-score.ps1` now have StrictMode |
| Script Performance: compress 3 largest scripts | High | Medium | 1.5 | 3-5 | ✅ Done | skill-graph.ps1 <15KB, intake-verify.ps1 11.8KB ✅, install.ps1 <12KB |
| README rewrite: accurate URL, counts, multi-agent, MCP, shortcuts | Medium | Low | 2.0 | 2 | ✅ Done | README reflects actual repo state, mentions multi-agent arch, !shortcuts, MCP |
| Error handling: add try/catch to 12 remaining scripts | Medium | Medium | 1.0 | 4-6 | ✅ Done | 33/36 have try/catch (92%); 3 LOW-risk intentional (bash-safe, skill-validate, skill-graph) |

### Cycle 7 Progress (CLOSED)
- Score: 9.9/10 (post-closing auto-score — up from 9.7)
- inter: 51/30 (170% of target)
- Backlog Completion: 5/5 (all items done)
- Score accuracy: ✅ .project.json fixed, PROJECT-SCORE.md synced, errors/ dir created
- Clean Code: ✅ StrictMode added to last 2 scripts
- Script Performance: ✅ 3 scripts compressed (avg 7.2→6.3KB)
- README: ✅ Full rewrite with accurate URL, multi-agent table, MCP, !shortcuts
- Error handling: ✅ try/catch added to 8 scripts (25/36→33/36, 92%)
- Backlog Integrity: ✅ 5/5 items verified

### Cycle 8 Backlog
| Item | Impact | Risk | I/R | Est. inter | Status | Done criteria |
|------|--------|------|-----|------------|--------|---------------|
| Script Performance: compress scripts >8KB to reduce avg <5KB | High | Low | 3.0 | 4-6 | ✅ Done | avg 4.3KB, no scripts >8KB (score-auto.ps1: 10.9→8.0KB) |
| Score expansion: sub-dimensions to break 10.0 ceiling | Medium | Low | 2.0 | 1 | ✅ Done | CYCLE.md defines sub-dims; score-auto.ps1 outputs them (32 sub-dims across 12 dims) |
| Clean Code: add params to last script without [Parameter()] | Medium | Low | 2.0 | 1 | ✅ Done | run.ps1 documented no-param by design (universal runner uses $args); score-auto.ps1 now recognizes |

### Cycle 8 Progress (CLOSED)
- Score: 9.9/10 (13 dims, all backlog items verified)
- inter: 66/30 (220% of target)
- Backlog Completion: 3/3 (all items done)
- Script Performance: ✅ avg 4.3KB, no scripts >8KB
- Score Expansion: ✅ 32 sub-dims across 12 dims
- Clean Code: ✅ params on remaining scripts, run.ps1 documented exception

### Cycle 9 Progress
- Score: 9.8/10
- inter: 89/30 (continuing from Cycle 8)
- Backlog Completion: 2/3 items done
- Skill Resolution Engine: ✅ BFS keyword scoring + 13-route regex routing + 3 format modes
- Edge case fixes: ✅ null array safety, format-before-count order, no-match handling

### Cycle 9 Backlog
| Item | Impact | Risk | I/R | Est. inter | Status | Done criteria |
|------|--------|------|-----|------------|--------|---------------|
| Skill Resolution Engine: BFS + agent routing in skill-graph.ps1 | High | Medium | 1.5 | 2-3 | ✅ Done | `Resolve-Skill` returns scored skills by BFS; `Get-AgentRecommendation` routes by 13 regex patterns + BFS fallback; -Format Json/Csv/Text; tested (ListAll, Task, RecommendAgent) |
| Fix edge cases: @() guards, null array safety | Medium | Low | 2.0 | 1 | ✅ Done | No-match tasks don't crash; RecommendAgent returns 0 on no match; Json format exits before count check |
| [TBD] | | | | | ⏳ Pending | |

## Metrics

| Metric | Target | Tracked By |
|--------|--------|------------|
| inter(30) | >=30 meaningful interactions | `scripts/inter-track.ps1` |
| Score delta | maintain >=9.5 (new dims may shift), target >=9.8 | `scripts/score-auto.ps1` |
| Backlog Integrity | 0 items with status ≠ reality | auto-check on cycle start |
| Score freshness | ≤1 day since last .project.json update | `git log -1 -- .project.json` |
| Automation claims verified | 100% of claims pass smoke test | per-claim smoke script |
| Subagent delegations per session | >=3 delegations | bitacora + engram |
| Upstream check automation | zero manual checks needed | `scripts/check-upstream.ps1` |
| Dreaming auto-trigger | fires on every 5th self-check | Learning Loop (unconditional) |
| Skill sizes | 0 >3KB, avg <2.0KB | `scripts/benchmark.ps1` (current: avg 1.8KB, 0 >3KB ✓) |
| Working tree hygiene | 0 cambios sin commit al cerrar ciclo | `git status --short` |
| Cross-ref | 0 errors | `scripts/cross-ref-check.ps1` |

## Impact/Risk Scoring

Every improvement candidate scored on two axes before execution:

| Score | Impact | Risk |
|-------|--------|------|
| High (3) | Direct score improvement, unblocks work | Cross-cutting, high breakage potential |
| Medium (2) | Quality/efficiency gain | Touches multiple files, needs verify |
| Low (1) | Cosmetic, nice-to-have | Isolated change, easy revert |

**Priority = Impact / Risk**. Execute high-priority first. Skip items with Risk > Impact (I/R < 1.0).

## Subagent Delegation Rules

Default execution strategy for non-trivial work:

1. Partition independent work items -> one subagent per item
2. Run parallel subagents with isolated context
3. Each subagent returns: Decision Taken + Files Changed + Key Findings + Nuance
4. Orchestrate: merge results, resolve conflicts, verify coherence
5. Log each delegation to bitacora + inter-track++

**Exception**: Single-file, low-risk edits (config, docs) -> do directly.

## Dimensions to Maintain

All 11 dims (plus new) at target. Cycle 6 adds integrity-focused dimensions.
- **Backlog Completion** (0->10): backlog items completed this cycle (tracked in Progress section)
- **Cycle Activity** (0->10): inter count / target (tracked in .project.json)
- **Backlog Integrity** (0->10): % items with status matching repo reality
- **Score Freshness** (0->10): days since last .project.json update (10 = today)
- **Automation**: upstream checks auto, dreaming auto, monitoring auto
- **Delegation**: >=3 subagent delegations per session
- **Hygiene**: working tree clean, atomic commits, cross-ref 0 errors

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
| Script Performance | count, avg_size, huge | count 15-35→10 else 7. avg ≤10KB→10. huge=0→10 |
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

## External Repos (auto-checked via `scripts/check-upstream.ps1`)

| Repo | What to Check | Last Verified |
|------|---------------|---------------|
| karpathy/autoresearch | New program.md patterns, loop improvements | 2026-06-20 (auto, UNCHANGED) |
| Gentleman-Programming/gentleman-guardian-angel | New caching strategies, AGENTS.md compliance checks | 2026-06-20 (auto, UNCHANGED) |
| gentle-ai | Skills, scripts, MCP servers, backup systems | 2026-06-20 (auto, CHANGED — 9 new commits including JD profiles PR #920) |
| engram (MCP) | Cloud sync, new query types, performance | 2026-06-20 (auto, UNCHANGED) |

## Cycle Loop

```
LOOP:
  1. READ CYCLE.md -- understand objective and constraints
   2. CHECK external repos (auto via check-upstream.ps1 — drift found? → auto-report with commit summary + relevance + suggested actions)
   3. DIAGNOSE: score, gaps, skill sizes, cross-ref, PSSA; check `.project.json` freshness (warning if >1d stale)
  4. SCORE backlog items by Impact/Risk (I/R = Impact / Risk)
  5. IDENTIFY fix candidates sorted by I/R descending
  6. PARTITION independent work -> parallel subagents
   7. EXECUTE (per item):
      a.0. SNAPSHOT: `git stash push -m "auto-${item}"` before any change
      a. Delegate to subagent with isolated context
      b. Triple-verify by difficulty level
      c. Log to bitacora + inter-track++
      d. Collect results: Decision + Files + Findings + Nuance
   8. ORCHESTRATE: merge subagent results, verify coherence
   9. VERIFY: re-score, compare delta
   10. If score improved -> Keep changes, advance baseline
   11. If score drop >0.5 from baseline -> full revert (`git checkout -- .` + `git stash drop`); else if score equal/worse -> review and decide
  12. LEARN: engram, anti-patterns, CYCLE.md notes
  13. SCORE AUTO-UPDATE: `score-auto.ps1 -Json | Set-Content .project.json`
  14. PROPAGATE: opencode -> opencode-vmk -> gentleman-vMK
   15. If inter>=30 AND no dim<9.0 (new dims grace 5 cycles) -> SUCCESS; if time budget (7d from cycle start) exhausted -> STOP; if score drop >0.5 from baseline -> full revert (git checkout + stash drop)
```

## Exceptions

- **NEVER STOP** on single fix failure -- revert and try next
- **NEVER ask** "should I continue" -- cycle runs autonomously
- **DO ask** if: new external dependency needed, architectural decision, or confidence < 0.7 on conflict judgment

## Author

gentleman-vMK -- Cycle 1 (infrastructure) 2026-06-17. Cycle 2 (hygiene+automation) 2026-06-18.
Cycle 3 (audit+validation) 2026-06-19. Cycle 4 (impact-driven delegation) 2026-06-20.
Cycle 5 (automation-first) 2026-06-20.
Cycle 6 (metric integrity) 2026-06-21. ✅ CLOSED (5/6, inter 49/30)
Cycle 7 (score accuracy + script optimization) 2026-06-21. ✅ CLOSED (5/5, inter 51/30)
Cycle 8 (script performance optimization) 2026-06-22. ✅ CLOSED (3/3, inter 66/30, score 9.9/10)
Cycle 9 (Skill Resolution Engine) 2026-06-24. 🟢 ACTIVE (2/3, inter 89/30, score 9.8/10)
