# Improvement Cycle Manifest

> Inspired by autoresearch (Karpathy) `program.md` — defines scope, metrics, and loop behavior.
> Auto-loaded by `self-improvement` skill on cycle start.
> Only edit this file to change cycle direction. Do NOT edit while cycle runs.

## Objective

Establecer el ciclo de auto-mejora continua como infraestructura del agente:
- Crear skill `self-improvement` que orqueste el ciclo completo
- Integrar triple-verify por dificultad (6 niveles)
- Implementar inter(30) como métrica de progreso
- Propagar cambios a opencode, opencode-vmk, gentleman-vMK

## Metrics

| Metric | Target | Tracked By |
|--------|--------|------------|
| inter(30) | ≥30 meaningful interactions per cycle | `scripts/inter-track.ps1` |
| Score delta | ≥+0.5 across lowest dimension | `scripts/score-auto.ps1` |
| Skill size | <3KB per skill | `scripts/run-improvement-cycle.ps1` |
| Cross-ref | 0 errors | `scripts/cross-ref-check.ps1` |

## Dimensions to Improve

All 10 at 10.0 currently. Focus:
- Maintain: keep all 10 dims at 10.0
- Track: add inter(30) as 11th dimension
- Automate: reduce manual steps in cycle execution

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
| karpathy/autoresearch | New program.md patterns, loop improvements | 2026-06-17 |
| Gentleman-Programming/gentleman-guardian-angel | New caching strategies, AGENTS.md compliance checks | 2026-06-17 (v2.8.1) |
| gentle-ai ecosystem | New MCP servers, backup systems | 2026-06-17 |
| engram (MCP) | Cloud sync, new query types, performance | 2026-06-17 |

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
  10. PROPAGATE: opencode → opencode-vmk → gentleman-vMK
  11. Auto-metrics + session-summary
  12. If inter≥30 OR time budget exhausted → STOP cycle
  13. If improvements still possible → CONTINUE
```

## Exceptions

- **NEVER STOP** on single fix failure — revert and try next
- **NEVER ask** "should I continue" — cycle runs autonomously
- **DO ask** if: new external dependency needed, architectural decision, or confidence < 0.7 on conflict judgment

## Author

gentleman-vMK — Created 2026-06-17 for first improvement cycle.
