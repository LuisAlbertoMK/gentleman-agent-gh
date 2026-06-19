# Improvement Cycle Manifest

> Inspired by autoresearch (Karpathy) `program.md` — defines scope, metrics, and loop behavior.
> Auto-loaded by `self-improvement` skill on cycle start.
> Only edit this file to change cycle direction. Do NOT edit while cycle runs.

## Objective

**Cycle 2**: Mantener score 10.0 y automatizar procesos manuales restantes:
- Corregir encoding corruption en SKILLS-INDEX.md (mojibake â†' → →)
- Automatizar trigger de session-miner.ps1 en DREAMING (AGENTS.md)
- Reducir PSSA violations en scripts de producción (<49 → <20 manual)
- Limpiar experiments/graph-crud/ (referencias de investigación obsoletas)
- Decidir y ejecutar PR a upstream gentle-ai con cambios genéricos

## Metrics

| Metric | Target | Tracked By |
|--------|--------|------------|
| inter(30) | ≥30 meaningful interactions per cycle | `scripts/inter-track.ps1` |
| Score delta | maintain ≥10.0, no dim below 9.9 | `scripts/score-auto.ps1` |
| Encoding corruption | 0 files with mojibake | `scripts/score-auto.ps1` (Orthography dim) |
| PSSA manual violations | <20 in production scripts | `scripts/pssa-gate.ps1 -Mode Check` |
| Cross-ref | 0 errors | `scripts/cross-ref-check.ps1` |

## Dimensions to Improve

All 11 dims at 10.0. Focus:
- Orthography: ensure 0 encoding corruption across all files
- Clean Code: maintain 9.9+, aim for 10.0
- Automate: reduce manual PSSA violations in production scripts
- Upstream: propagate generic improvements to gentle-ai

## Difficulty → Triple-Verify Mapping

| Level | Example | Verify Required | Time Budget |
|-------|---------|-----------------|-------------|
| Fácil | docs/config only | E2 (static) only | 2 min |
| Medio | test fixes, minor tweaks | E1 (test) + E2 | 5 min |
| Medio-Difícil | refactors, new small features | E1+E2+E3 (build) | 10 min |
| Difícil | new skills, scripts | Full + 4R review | 15 min |
| Complejo | cross-cutting changes | Full + judgment-day | 30 min |
| Muy Complejo | architectural decisions | Full + SDD cycle | 60 min |

## External Repos (re-check on cycle start)

| Repo | What to Check | Last Verified |
|------|---------------|---------------|
| karpathy/autoresearch | New program.md patterns, loop improvements | 2026-06-18 (no changes) |
| Gentleman-Programming/gentleman-guardian-angel | New caching strategies, AGENTS.md compliance checks | 2026-06-18 (v2.8.1, no changes) |
| gentle-ai ecosystem | New MCP servers, backup systems, upstream PRs | 2026-06-18 (no new public repos) |
| engram (MCP) | Cloud sync, new query types, performance | 2026-06-18 |

## Cycle Loop

```
LOOP:
  1. READ CYCLE.md — understand objective and constraints
  2. CHECK external repos for new features (Engram #645)
  3. DIAGNOSE: score, gaps, skill sizes, cross-ref, PSSA
  4. IDENTIFY fix candidates sorted by impact/ease
  5. For each fix:
     a. Backup snapshot (gentle-ai style)
     b. Apply change
     c. Triple-verify by difficulty level (see table)
     d. Log to bitácora + inter-track++
     e. Cache result (GGA-style: skip if unchanged)
  6. VERIFY: re-score, compare delta, check inter≥30
  7. If score improved → Keep changes, advance baseline
  8. If score equal/worse → Review and revert
  9. LEARN: engram, anti-patterns, CYCLE.md notes
  10. SCORE AUTO-UPDATE: `score-auto.ps1 -Json | Set-Content .project.json -Encoding UTF8` + update PROJECT-SCORE.md changelog
  11. PROPAGATE: opencode → opencode-vmk → gentleman-vMK
  12. Auto-metrics + session-summary
  13. If inter≥30 OR time budget exhausted → STOP cycle
  14. If improvements still possible → CONTINUE
```

## Exceptions

- **NEVER STOP** on single fix failure — revert and try next
- **NEVER ask** "should I continue" — cycle runs autonomously
- **DO ask** if: new external dependency needed, architectural decision, or confidence < 0.7 on conflict judgment

## Author

gentleman-vMK — Created 2026-06-17 for cycle 1 (infrastructure). Cycle 2 (hygiene+automation) started 2026-06-18.
