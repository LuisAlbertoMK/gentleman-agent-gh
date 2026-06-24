# Cycle Improvement Plan

> Synthesized from 4 perspectives: orchestrator + 3 subagentes (Backlog & Metrics, Loop & Process, Tooling & Delegation).
> Cada hallazgo con prioridad, inter estimado, y cómo verificarlo.

## P0 — Crítico (bloquea avance del ciclo)

| # | Hallazgo | Síntomas | Fix | Inter | Verificación |
|---|----------|----------|-----|-------|-------------|
| 1 | **Escala I/R invertida** — Risk=3 es "fácil/revertible" (bajo riesgo real), Risk=1 es "cross-cutting" (alto riesgo). I/R = Impact/Risk → recompensa lo peligroso. | Items peligrosos tienen I/R más alto que los seguros | Renombrar columna `Risk` → `Confianza` (High=3 confianza, fácil) o invertir valores. **Opción A (recomendada)**: rename, mantiene fórmula. | 1 | `grep -c "Risk" CYCLE.md` = 0 |
| 2 | **Exit criteria en conflicto 3-vía** — CYCLE.md dice OR (inter≥30 OR time), self-improvement skill dice AND (inter≥30 AND no dim<9), AGENTS.md dice AND + quality + revert | Misma sesión, 3 reglas distintas para cuándo parar | Homogeneizar a AND: "inter≥30 AND no dim<9.0 (new dims grace 5 ciclos) → SUCCESS; time budget (>7d) → STOP; score drop >0.5 → full revert" | 1 | Las 3 fuentes dicen lo mismo |
| 3 | **Backlog items sin done criteria** — "Verify automation claim" ¿qué claims? ¿cuenta? Sin criterio no se puede verificar | Cycle Progress 0/10 no es verificable | Agregar columna `done_criteria` al backlog con marker grepeable (ej: `script exists at scripts/foo.ps1`) | 2 | Cada item ≥1 marker grepeable |
| 4 | **Verify profiles E1/E2/E3 existen en config pero sin comandos ejecutables** — `review-rules.jsonc` define E1/E2/E3, no hay scripts que los implementen | verify es documentación, no automatización | Crear `scripts/verify.ps1 -Profile E1|E2|E3` con comandos reales. E1: test runner, E2: PSSA+markdownlint, E3: syntax check | 4 | Cada perfil falla con non-zero en error inducido |
| 5 | **Sin auto-revert en score drop** — LOOP step 11 dice "revert" pero no hay snapshot ni `git checkout` automático | Revertir es una intención, no un mecanismo | Step "7a.0 SNAPSHOT: git stash push -m auto-${item}". Step 11: "score drop >0.5 → restore from snapshot" | 2 | Dry-run con cambio malo → score cae → auto-revert |

## P1 — Alto (calidad del ciclo sufre sin esto)

| # | Hallazgo | Fix | Inter | Verificación |
|---|----------|-----|-------|-------------|
| 6 | **Cycle Progress ambiguo** — mismo nombre en .project.json (mide inter count) y CYCLE.md (mide backlog completion) | .project.json → `Cycle Activity`, CYCLE.md → `Backlog Completion: X/6` | 1 | Nombres distintos en ambos |
| 7 | **Best Practices 10 es score falso** — try/catch 17/34 (50%) pero muestra 10. Stale data | Exponer try/catch ratio en rationale. Capping por staleness (>1d → max 9) | 2 | Rationale muestra "trycatch: 17/34 (50%)"; stale → capped 9 |
| 8 | **Score freshness ya violada** — última actualización .project.json: 2026-06-19, hoy 2026-06-21 (2 días stale) | Mirror check en cycle loop (step 3 incluye `git log -1 -- .project.json`). Mientras tanto duplicar en check-upstream.ps1 | 1 | `git log` check en loop step 3 |
| 9 | **Redundancia en LOOP** — step 9 y step 15 checkean inter≥30. Además step 12 (LEARN) antes de step 13 (SCORE UPDATE) | Step 9: sacar inter check. Steps 12↔13: swap (score update antes de learn) | 1 | Step 9 no menciona inter; orden correcto |
| 10 | **Falta modo `!check`/`!verify`** — solo !ship (commit+push), !fast (skip verify), !draft (no commit). No hay verify sin commit | Agregar a `review-rules.jsonc` modes: `!check: { verify: "profile", gate: true, commit: false }` | 1 | `!check` corre verify profiles sin commit |
| 11 | **Subagent types insuficientes para cycle work** — faltan builder, verifier, configurator | Documentar en CYCLE.md qué tipo de agente usar por categoría de tarea | 1 | Tabla de mapping task→agent type en CYCLE.md |
| 12 | **JD profiles no conectados con difficulty mapping** — Complejo dice "Full + JD" pero no especifica qué JD profiles | Difficulty table referenciar JD profiles por change type (scripts→security+reliability, skills→architect+reliability) | 1 | Difficulty table tiene columna JD profiles |
| 13 | **Post-task G no es cycle-aware** — cuando un ciclo está activo, G no revisa cycle metrics | Ciclo activo → post-task checkea score delta + inter antes de auto-metrics estándar | 2 | Cycle task → post-task prioriza cycle metrics |

## P2 — Medio (optimizaciones)

| # | Hallazgo | Fix | Inter | Verificación |
|---|----------|-----|-------|-------------|
| 14 | "Full" undefined en difficulty table — no dice qué perfiles incluye | Reemplazar "Full" con "E1+E2+E3" explícito | 1 | `grep "\bFull\b" CYCLE.md` = 0 |
| 15 | Sin bridge difficulty→zones review-rules.jsonc | Agregar `difficulty_zones: { Facil: verde, Medio: amarilla, ... }` | 3 | Config parsea correctamente |
| 16 | Subagent delegations mide actividad, no valor | Filtrar delegations con output no-null en la métrica | 2 | Métrica ignora zero-output delegations |
| 17 | Security dim solo checkea 2 cosas (secrets, weak crypto) | Agregar grep de patrones peligrosos (injection, path traversal) | 3 | Nueva sub-evidencia en Security |
| 18 | Parallelizar LOOP steps 2+3 | "RUN in parallel: CHECK repos + DIAGNOSE" | 1 | Script corre ambos en paralelo |
| 19 | Crear `scripts/check-backlog-integrity.ps1` | Lee CYCLE.md backlog, verifica status vs repo reality | 3 | Backlog ✅ Done sin impl → script reporta mismatch |
| 20 | Auto-I/R scoring por heurísticas | Script que calcula I/R desde diff stats (files touched, zones) | 5 | Baseline vs auto <20% divergence en 10 items |
| 21 | Métricas ya al máximo (skill sizes, cross-ref) | Colapsar en compuesta "Maintenance" | 2 | Tabla de métricas se reduce 3 filas |
| 22 | Metrics dim mide existencia de directorio, no utilidad | Trackear uso real de métricas en cycle loop | 2 | evidence muestra "consumed in X de últimos Y ciclos" |
| 23 | Cycle Progress /10 arbitrario para 6 items | Mapear a `X/6` o weighted por inter-est | 2 | Progress = sum(inter_est_completado) / total |

## Resumen Ejecutivo

### Top 5 por impacto/inter

| # | Descripción | Inter | Rationale |
|---|-------------|-------|-----------|
| 1 | Fix I/R scale (rename Risk→Confianza) | 1 | Bug que prioriza cambios peligrosos sobre seguros |
| 2 | Resolver exit criteria 3-way conflict | 1 | 3 docs dicen 3 cosas distintas |
| 6 | Disambiguar Cycle Progress | 1 | Mismo nombre, 2 significados distintos |
| 7 | Honestidad en Best Practices score | 2 | Score 10 con try/catch 50% es engañoso |
| 10 | Modo `!check`/`!verify` | 1 | Sin esto no hay verify sin commit |

### Cómo proceder

1. Revisar este plan
2. Elegir items por prioridad o por batch
3. Cada item: subagente → triple-verify → bitacora → inter-track++
4. Re-score al cerrar cada batch

---

*Generado: 2026-06-21 | 4 perspectivas: orchestrator + 3 subagentes*
