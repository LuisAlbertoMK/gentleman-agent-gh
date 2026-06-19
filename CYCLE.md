# Improvement Cycle Manifest

> Inspired by autoresearch (Karpathy) `program.md` — defines scope, metrics, and loop behavior.
> Auto-loaded by `self-improvement` skill on cycle start.
> Only edit this file to change cycle direction. Do NOT edit while cycle runs.

## Objective

**Cycle 3**: Integrar external-auditor, validar ciclo de auto-mejora, mantener score 10.0:
- ✅ Restaurar `.project.json` post-corrupción por auto-metrics (checkpoint safety/cycle2-state-*)
- ✅ Punto de seguridad creado: tag `checkpoint/cycle2-done-bd39c66`, branch `safety/cycle2-state-*`
- ✅ external-auditor skill disponible global + local SKILL.md
- ✅ Commit cambios pendientes: AGENTS.md (router + auto-audit trigger), ANTI-PATTERN-CATALOG.md (#15), SKILLS-INDEX.md
- ✅ Ejecutar external-auditor en primera tarea compleja — restaurar .project.json + guardrail + commit. Encontró 2 gaps >1.5 (ErrPrev 6vs9, Breadth 5vs9). Immunize: anti-pattern #17 + guardrail pre-commit
- ✅ Verificar ciclo `self-improvement`: diagnose(score 5→9.4) → fix(restore + guardrail) → verify(external-auditor) → learn(anti-pattern #17) → propagate(committed)
- 🔲 Mantener score ≥9.4 — ninguna dim por debajo de 3.0

## Metrics

| Metric | Target | Tracked By |
|--------|--------|------------|
| inter(30) | ≥30 meaningful interactions | `scripts/inter-track.ps1` |
| Score delta | maintain ≥10.0, no dim below 9.9 | `scripts/score-auto.ps1` |
| External-auditor activations | ≥1 en tarea compleja | bitácora + ANTI-PATTERN-CATALOG |
| Working tree hygiene | 0 cambios sin commit al cerrar ciclo | `git status --short` |
| Cross-ref | 0 errors | `scripts/cross-ref-check.ps1` |

## Dimensions to Improve

All 11 dims at 10.0. Focus:
- **Audit**: activar external-auditor post-task — validar que estoy calibrado
- **Process**: ciclo de mejora completo y reproducible (phase 0→5)
- **Hygiene**: mantener working tree limpio, commits atómicos
- **Score**: defender el 10.0 — si external-auditor gap >1.5, immune-system

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
| karpathy/autoresearch | New program.md patterns, loop improvements | 2026-06-19 (no changes) |
| Gentleman-Programming/gentleman-guardian-angel | New caching strategies, AGENTS.md compliance checks | 2026-06-19 (v2.8.1, no changes) |
| gentle-ai ecosystem | New MCP servers, backup systems (read-only, no PRs) | 2026-06-19 (no new public repos) |
| engram (MCP) | Cloud sync, new query types, performance | 2026-06-19 |

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

gentleman-vMK — Created 2026-06-17 for cycle 1 (infrastructure). Cycle 2 (hygiene+automation) 2026-06-18. Cycle 3 (audit+validation) started 2026-06-19.
