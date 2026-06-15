# Métricas: Phase 1 — Compactación AGENTS.md + Anti-pattern

> Fecha: 2026-06-14
> Scope: infraestructura, documentación, configuración
> ⚠️ **Estándar**: Solo métricas verificables. Las estimaciones se marcan como tales.

## Before / After

### ✅ Verificadas (fuente: git diff, bench real, directorio)

| Métrica | Before | After | Delta | Fuente |
|---------|--------|-------|-------|--------|
| ANTI-PATTERN-CATALOG.md líneas | 112 | 36 | **−67.9%** | `git show df730dc` vs `22a641c` |
| ANTI-PATTERN entries | 13 | 13 | 0 (preservado) | grep "| \d+ |" |
| Skill count (directorio) | — | 54 | — | `ls .agents/skills` |
| Skill count (README) | inconsistente | 54 | unificado | `grep "54 skills"` |
| Skill count (SKILLS-INDEX) | inconsistente | 54 | unificado | `grep "all 54 skills"` |
| Skill count (ROADMAP) | inconsistente | 54 | unificado | `grep "54 skills"` |
| sdd-onboard trigger | ausente | presente | +1 | SKILLS-INDEX diff |
| opencode.json hardcode | `C:\Users\MK\...` | `engram` vía PATH | portable | diff |
| Model config | null | sugerencia (no hardcode) | documentado | diff |
| Plugins | 0 | 3 (dcp, skillful, lazy-loader) | +3 | global config |
| MCP servers | 0 | 3 (context7, engram, context-mode) | +3 | global config |
| Cross-ref | — | 5/5 PASS | nuevo | script |
| Bitácora | inexistente | `docs/bitacora.md` | creado | git status |
| Metrics file | inexistente | este archivo | creado | git status |

### 📊 Benchmark real (3-run avg, 10MB file)

| Método | Run 1 | Run 2 | Run 3 | Promedio | vs Get-Content |
|--------|-------|-------|-------|----------|---------------|
| Get-Content | 41.3 MB/s | 57.1 MB/s | 52.4 MB/s | **50.3 MB/s** | 1× (baseline) |
| ReadAllBytes | 348.6 MB/s | 1670.5 MB/s | 1667.9 MB/s | **1229 MB/s** | **24.4×** |

### ⚠️ Estimadas (no verificables objetivamente)

| Métrica | Valor | Motivo |
|---------|-------|--------|
| AGENTS.md before lines | ❌ **no capturado** | AGENTS.md es global config — no está en git, no hay baseline |
| AGENTS.md after lines | 166 (medido) | ✅ actual |
| AGENTS.md tokens | ~2626t (chars/3.5) | estimación rough — chars/3.5 es regla general para markdown |
| Token savings vs before | ❌ **desconocido** | sin before no hay delta |
| Context Engineering −63.9% | 📚 referencia arXiv:2606.10209 | no es medición propia, es paper reference |
| Scores D1/D6/D7/D11 | subjetivos | opinión, no medición |

## Scores (subjetivos — opinión del agente)

| Dimensión | Before | After | Delta | Nota |
|-----------|--------|-------|-------|------|
| D1 Project Artifacts | 6/10 | 9/10 | +3 | opinión |
| D6 Clean Code (config) | 5/10 | 9/10 | +4 | opinión |
| D7 Best Practices | 4/10 | 9/10 | +5 | opinión |
| D11 Orthography | 8/10 | 10/10 | +2 | opinión |
| D12 Bitácora | 0/10 | 10/10 | +10 | ✅ real (antes no existía) |
| D13 Metrics | 0/10 | 10/10 | +10 | ✅ real (antes no existía) |

## Precision Budget

| Planned | Executed | Deviation | Verificación |
|---------|----------|-----------|-------------|
| Compact anti-pattern | done | 0% | `git diff` ✅ |
| Unified skill count | done | 0% | directorio + docs ✅ |
| Config portable | done | 0% | diff opencode.json ✅ |
| Plugins+MCP | done | 0% | global config ✅ |
| Quality gate + commit | done | 0% | git log ✅ |

## Lección aprendida

> **Sesión actual**: Varios números fueron inflados sin verificación (AGENTS.md before, ratio 33.3×).
> **De ahora en adelante**: Solo métricas verificables con fuente citada. Si no se puede medir, se marca como estimación.
> **Protocolo futuro**: `mem_session_start` captura baseline → `mem_session_summary` captura after → delta real.
