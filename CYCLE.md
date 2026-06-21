# Improvement Cycle Manifest

> Inspired by autoresearch (Karpathy) `program.md` -- defines scope, metrics, and loop behavior.
> Auto-loaded by `self-improvement` skill on cycle start.
> Only edit this file to change cycle direction. Do NOT edit while cycle runs.

## Objective

**Cycle 6**: Metric integrity and verification-first. Close gaps between claimed and actual state of automation, backlog tracking, and scoring. Every claim in CYCLE.md and .project.json MUST be verifiable from repo state. Fix score ceiling deadlock with honest sub-scores.

### Pillars
1. **Backlog integrity** — every item's status MUST match repo reality. Auto-verify on cycle check.
2. **Score freshness** — .project.json auto-updates after significant changes; warning when stale >1d.
3. **Verifiable claims** — every automation claim has a passing smoke test or is marked aspirational.
4. **Score expansion** — break 10.0 ceiling with sub-dimensions that reward verifiable improvement.

### Backlog (sorted by impact/risk)
| Item | Impact | Risk | I/R | Est. inter | Status | Done criteria |
|------|--------|------|-----|------------|--------|---------------|
| Close Cycle 5: mark items 1-3 ✅ Done, carry item 4 forward | High | Low | 3.0 | 1 | ✅ Done | CYCLE.md reflects items 1-3 closed (commit 63f5232) |
| Add "Backlog Integrity" metric to score-auto.ps1 | High | Low | 3.0 | 2-3 | ✅ Done | `score-auto.ps1` outputs `backlog_integrity` dim; script `check-backlog-integrity.ps1` exists and exits 0 on clean |
| Score freshness: auto-warning or auto-update .project.json | Medium | Low | 2.0 | 2 | ✅ Done | Cycle loop step 3 auto-checks `.project.json` age; triggers warning if >1d stale |
| Verify automation claim has end-to-end smoke test | High | Medium | 1.5 | 3-5 | ✅ Done | `scripts/smoke/smoke-all.ps1` tests 5 auto claims (BI, upstream, dreaming, freshness, LOOP) — all pass |
| Score expansion: sub-dimensions to break 10.0 ceiling | Medium | Low | 2.0 | 3 | ⏳ Pending | `.project.json` has >11 dimensions; score.current >10.0 achievable |
| Integration smoke tests for key scripts (carry-over from C5) | Medium | Medium | 1.0 | 2-3 | ✅ Done | `scripts/smoke/` exists with 5 tests; `smoke-all.ps1` exits 0 |

### Progress
- Score: 9.9/10 (honest re-score, Script Performance 9.0 dragging)
- inter: 47/30 (ongoing cycle 6 execution)
- Backlog Completion: 5/6 (items #1, #2, #3, #4, #6 done — #5 Score expansion pending)
- Skills >3KB: 0 ✓ (all 69 skills compressed, including sdd-onboard 6.9→2.3KB)

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
Cycle 6 (metric integrity) 2026-06-21.
