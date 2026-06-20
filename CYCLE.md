# Improvement Cycle Manifest

> Inspired by autoresearch (Karpathy) `program.md` -- defines scope, metrics, and loop behavior.
> Auto-loaded by `self-improvement` skill on cycle start.
> Only edit this file to change cycle direction. Do NOT edit while cycle runs.

## Objective

**Cycle 4**: Impact-driven optimization with delegation-first execution. Maintain 10.0 across 12+ cycles through parallel subagent work, risk-based prioritization, and upstream feature evaluation.

### Pillars
1. **Impact/Risk prioritization** -- every fix scored by (impact * value) / (complexity * risk). High-impact/low-risk first.
2. **Subagent delegation** -- default execution strategy. Parallel subagents for independent work. Orchestrate, don't do.
3. **Profile-scoped JD activation** -- apply on first real high-risk review.
4. **Skill hygiene** -- 0 skills >3KB, avg <2.0KB, Karpathy compression standard.

### Backlog (sorted by impact/risk)
| Item | Impact | Risk | I/R | Est. inter |
|------|--------|------|-----|------------|
| Activar profile-scoped JD en review real | High | Medium | 2.0 | 3-5 |
| Evaluar upstream features (backup/planner) | High | Low | 2.0 | 2-3 |
| Comprimir skills >2.5KB restantes | Medium | Low | 1.5 | 1-2 |
| PSSA violations: 453 info-level (review/accept) | Low | Low | 1.0 | 1-2 |
| Skill cross-ref completeness audit | Medium | Low | 1.0 | 1 |

### Progress
- Score: 10.0/10 (baseline)
- inter: 33/30
- Cycle Progress: 3/10

## Metrics

| Metric | Target | Tracked By |
|--------|--------|------------|
| inter(30) | >=30 meaningful interactions | `scripts/inter-track.ps1` |
| Score delta | maintain >=9.8, target 10.0 | `scripts/score-auto.ps1` |
| Subagent delegations per session | >=3 delegations | bitacora + engram |
| Profile-scoped JD | activated >=1 high-risk review | review-rules.jsonc jd_profiles |
| Skill sizes | 0 >3KB, avg <2.0KB | `scripts/benchmark.ps1` |
| Impact/Risk adherence | every item scored before work | CYCLE.md backlog |
| Working tree hygiene | 0 cambios sin commit al cerrar ciclo | `git status --short` |
| Cross-ref | 0 errors | `scripts/cross-ref-check.ps1` |

## Impact/Risk Scoring

Every improvement candidate scored on two axes before execution:

| Score | Impact | Risk |
|-------|--------|------|
| High (3) | Direct score improvement, unblocks work | Isolated change, easy revert |
| Medium (2) | Quality/efficiency gain | Touches multiple files, needs verify |
| Low (1) | Cosmetic, nice-to-have | Cross-cutting, high breakage potential |

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

All 11 dims at 10.0. Focus on keeping them green while advancing Cycle Progress.
- **Cycle Progress** (0->10): inter(30) with impact-scored improvements
- **Activation**: profile-scoped JD on first high-risk review
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

## External Repos (re-check on cycle start)

| Repo | What to Check | Last Verified |
|------|---------------|---------------|
| karpathy/autoresearch | New program.md patterns, loop improvements | 2026-06-19 (no changes) |
| Gentleman-Programming/gentleman-guardian-angel | New caching strategies, AGENTS.md compliance checks | 2026-06-19 (v2.8.1, no changes) |
| gentle-ai ecosystem | New MCP servers, backup systems (read-only, no PRs) | 2026-06-19 |
| engram (MCP) | Cloud sync, new query types, performance | 2026-06-19 |

## Cycle Loop

```
LOOP:
  1. READ CYCLE.md -- understand objective and constraints
  2. CHECK external repos for new features
  3. DIAGNOSE: score, gaps, skill sizes, cross-ref, PSSA
  4. SCORE backlog items by Impact/Risk (I/R = Impact / Risk)
  5. IDENTIFY fix candidates sorted by I/R descending
  6. PARTITION independent work -> parallel subagents
  7. EXECUTE (per item):
     a. Delegate to subagent with isolated context
     b. Triple-verify by difficulty level
     c. Log to bitacora + inter-track++
     d. Collect results: Decision + Files + Findings + Nuance
  8. ORCHESTRATE: merge subagent results, verify coherence
  9. VERIFY: re-score, compare delta, check inter>=30
  10. If score improved -> Keep changes, advance baseline
  11. If score equal/worse -> Review and revert
  12. LEARN: engram, anti-patterns, CYCLE.md notes
  13. SCORE AUTO-UPDATE: `score-auto.ps1 -Json | Set-Content .project.json`
  14. PROPAGATE: opencode -> opencode-vmk -> gentleman-vMK
  15. If inter>=30 OR time budget exhausted -> STOP cycle
```

## Exceptions

- **NEVER STOP** on single fix failure -- revert and try next
- **NEVER ask** "should I continue" -- cycle runs autonomously
- **DO ask** if: new external dependency needed, architectural decision, or confidence < 0.7 on conflict judgment

## Author

gentleman-vMK -- Cycle 1 (infrastructure) 2026-06-17. Cycle 2 (hygiene+automation) 2026-06-18.
Cycle 3 (audit+validation) 2026-06-19. Cycle 4 (impact-driven delegation) 2026-06-20.
