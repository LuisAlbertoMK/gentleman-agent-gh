# Análisis de Performance de Tests — gentleman-agent-gh

**Fecha**: 2026-07-31 · **Trigger**: `!analisis` (tests: menor uso de recursos, más rápidos, optimizados)
**Método**: 3 subagentes paralelos (medición, estructura de tests, pipeline) + research web (Pester 6 docs, dot-sourcing benchmarks)
**Scope**: `scripts/tests/*.Tests.ps1` (26 archivos, ~472 `It`), `scripts/run-tests.ps1`, hooks git, `!ship` flow

---

## Baseline medido (2026-07-31, PS 7.6.4 / Pester 6.0.1)

| Métrica | Valor |
|---|---|
| Secuencial (suma por archivo aislado) | **~640s / 10.7 min** (≈553s sin overhead de spawn) |
| Paralelo (`run-tests.ps1` default) | **150.3s** (4.3× speedup ya activo) |
| Spawn de `pwsh` en frío | 3.35s por proceso (≈87s = 13% del tiempo secuencial) |
| Pico memoria suite paralela | 304.9 MB |
| Baseline previo (PERFORMANCE-PLAN.md:11, 07-11) | 14.4s — la suite creció ~10× desde entonces |

**Outliers dominantes**: `_e2e_pipeline.Tests.ps1` **178.5s** (27.9%) + `ScoreIntegration.Tests.ps1` **87.9s** (13.7%) = **41.6% del tiempo secuencial**. En paralelo, el wall-clock ≈ el archivo más lento → optimizar outliers es la palanca máxima.

---

## Findings (ranked por impacto)

| # | Finding | Consenso | Riesgo | Files | Recomendación |
|---|---------|----------|--------|-------|---------------|
| 1 | **`_e2e_pipeline` corre la suite completa anidada con `-CodeCoverage`** — 178s por 24 Its. Pester 6 fuerza *fallback secuencial* cuando hay CodeCoverage (docs: pester.dev/usage/parallel) | UNANIMOUS (medición+estructura+web) | **ALTO** | `_e2e_pipeline.Tests.ps1:165-166` | Sacar del suite default: `-Tag E2E` / nightly / opt-in. Ahorro: **~30-178s** |
| 2 | **`ScoreIntegration` 10× spawn completo del script** — cada run hashea SHA-256 de 203 archivos (7.6s medidos) + 3 ThreadJobs | UNANIMOUS | **ALTO** | `ScoreIntegration.Tests.ps1` | `BeforeAll` → correr score-auto 1× y cachear output; mockear hashing de manifiesto; tag integración. Ahorro: **~100-120s** |
| 3 | **Patrón spawn-por-test: ~135 invocaciones de `& $scriptPath`** — cada una re-parsea y re-ejecuta el script completo | UNANIMOUS | **ALTO** | permission-gate (50×, ~38s), engram-validate (24×, ~16s), mode-gate.Int (18×), close-session.Int (10×, ~12s), session-miner (9×), vws.Int (7×) | Extraer lógica a funciones/lib; dot-source 1× en `BeforeAll`; test in-process. Ahorro: **~100s+** |
| 4 | **Modo paralelo INSEGURO — estado compartido entre archivos**: 2 tests escriben el MISMO `.gentleman-mode` (race/corrupción), `close-session.Int` escribe BITACORA.md, ScoreIntegration escribe score-cache.json, `restore.Tests` muta `$env:USERPROFILE`, sync-vmk escribe config global | UNANIMOUS | **CRÍTICO** | mode-gate.Int:24,59,103 ↔ permission-gate:18,28; close-session.Int; ScoreIntegration; restore:11; sync-vmk | Aislamiento por-run: mode file en temp, path parametrizado para BITACORA/cache, save/restore de env vars. **Explica el exit code 1 del run paralelo** |
| 5 | **`sync-vmk.Tests.ps1:16` dot-source con efectos secundarios REALES fuera del repo** — escribe el opencode.json global del usuario y copia AGENTS.md al config global | UNANIMOUS | **ALTO** | `sync-vmk.Tests.ps1:16`, `sync-vmk.ps1:157-166` | Guard `$env:PESTER` o extraer `Sync-Config` a lib; revisión humana antes de tocar |
| 6 | **`!ship` ejecuta la suite 2× cuando hay tests staged**: full suite (quality-gate SKILL) + subset secuencial (pre-commit hook, sin `Run.Parallel`) | UNANIMOUS | MEDIO | `.agents/skills/quality-gate/SKILL.md:43`, `.githooks/pre-commit-gate.ps1:168` | Marcador env/cache para dedupe; hook con `Run.Parallel` (Pester 6.0.1 instalado) |
| 7 | **pre-push re-ejecuta el gate completo incondicionalmente** — tras commit con índice limpio, todos los checks no-op pero igual spawna pwsh + 13 checks | UNANIMOUS | MEDIO | `.githooks/pre-push:24-35` | Guard `git diff --cached --quiet` |
| 8 | **Setup pesado por-It**: creación de junctions reales por test (JunctionLogic:111-130, health-check:80,152), ~15-20 git spawns (vws.Int), temp dirs en 10 archivos | MAJORITY | MEDIO | JunctionLogic, health-check, vws.Int | Hoist a `BeforeAll`; reusar 1 repo git temp por Describe |
| 9 | **Extracción regex/string de funciones (7 archivos) + lógica de producción re-implementada en tests (9 archivos)** — frágil y drift alto: los tests verifican copias, no el código real | MAJORITY | MEDIO | Add-Dimension, Aggregation, check-mcp-security, skill-graph, restore, session-miner, _e2e + 9 test files | `scripts/tests/TestHelpers.ps1` compartido; módulo lib; `InModuleScope`+`Mock` |
| 10 | **`destructive-scripts.Tests.ps1` lee `scripts/` 5-6× completo** (~90 archivos) en filtros y loops | MAJORITY | BAJO | destructive-scripts.Tests.ps1:14,19,132-154 | Cache hashtable en `BeforeAll` |
| 11 | **Overhead de spawn 3.35s/archivo** (13% del secuencial) + PSSA fallback full-scan 32.7s (PERFORMANCE-PLAN.md:50) | MAJORITY | BAJO | runner | Batch in-process; `-Mode Incremental` priorizado; cache PSSA ya existente (4.2-6.4s hit) |

---

## Síntesis

- **Consenso dominante**: el costo NO está en las aserciones sino en **re-ejecutar producción por spawn** (~135 veces) y en **2 archivos outliers**. Eliminar #1+#2+#3 reduce el secuencial de ~553s a ~100-120s (5×).
- **En paralelo, wall-clock ≈ archivo más lento**: hoy 150.3s; sin #1+#2 → ~40s (próximo más lento: destructive-scripts 25.9s); con #3+#6+#7 → **~20-30s**.
- **Paradoja detectada**: el runner ya paraleliza (4.3×) pero el paralelismo es *frágil* por #4 — races de estado compartido causan fallos intermitentes (explican exit 1 del run paralelo). Aislar estado es **prerrequisito** para confiar en el parallel default.
- **Baseline 14.4s obsoleto**: PERFORMANCE-PLAN.md:11 mide suite de julio 11; hoy son 150.3s paralelo / ~553s secuencial. Actualizar el plan.
- Memoria 304.9 MB peak → controlable con `Run.ParallelThrottleLimit` si hace falta (default = todos los cores).

## Matriz de riesgo

```
CRÍTICO  ■■ (1) — parallel unsafe (estado compartido)
ALTO     ■■■■■ (4) — _e2e anidado, ScoreIntegration, spawn-por-test, sync-vmk side effects
MEDIO    ■■■■■ (4) — !ship 2×, pre-push, setup pesado, regex/duplicación
BAJO     ■■■ (3) — reads redundantes, spawn overhead, coverage opcional
```

## Recomendaciones priorizadas

| Prioridad | Acción | Ahorro estimado | Esfuerzo |
|---|---|---|---|
| **P0** | Aislar estado compartido (#4): mode file temp, BITACORA/cache parametrizados, env save/restore | Desbloquea parallel confiable | 2-3h |
| **P0** | `_e2e_pipeline` → `-Tag E2E` / nightly, fuera del default (#1) | 30-178s | 15 min |
| **P0** | ScoreIntegration: 1 run en `BeforeAll` + cache output (#2) | 100-120s | 30 min |
| **P1** | Extraer libs y test in-process: permission-gate, engram-validate, mode-gate, session-miner, vws (#3) | ~100s | 2-4h |
| **P1** | Dedupe suite en `!ship` + hook paralelo + guard pre-push (#6, #7) | ~15s por ciclo + pwsh spawn | 30 min |
| **P1** | Guard `$env:PESTER` en sync-vmk (#5) | Seguridad del config global | 15 min |
| **P2** | TestHelpers.ps1 + lib module, matar regex-extraction (#9) | Mantenibilidad | 1-2d |
| **P2** | Actualizar PERFORMANCE-PLAN.md con baseline real | Documentación | 5 min |

**Resultado proyectado**: 150.3s → **~25-40s** paralelo (4-6×) y ~553s → **~100-120s** secuencial (5×), con suite estable sin races.

---

## ✅ Ejecución (2026-07-31, P0+P1)

**Medido real: 150.3s → 38.5s (3.9×)** — suite completa vía `run-tests.ps1 -Quiet`.

| Cambio | Archivos | Resultado |
|---|---|---|
| P0-A `_e2e_pipeline` → `-Tag E2E` (excluido por defecto vía `-IncludeE2E` flag en runner) | `_e2e_pipeline.Tests.ps1`, `run-tests.ps1` | 178.5s → **12.3s** (default) |
| P0-A ScoreIntegration: 1 run en `BeforeAll` + cache | `ScoreIntegration.Tests.ps1` | 87.9s → **41s** (remanente = PSSA cold-scan interno de score-auto, fuera de scope) |
| P0-B aislar estado: `-ModeFilePath` (mode-gate + permission-gate, ambos → temp GUID file), `-BitacoraPath` (close-session), save/restore `$env:USERPROFILE` (restore), guard `$env:PESTER_TEST` (sync-vmk) | 5 scripts producción + 5 tests | Dual-run simultáneo 18+50 pass; hash `.gentleman-mode` y BITACORA byte-idénticos |
| P1-C hooks: `Run.Parallel` en pre-commit-gate (Pester 6, >1 archivo), guard `git diff --cached --quiet` en pre-push (1.39s cuando limpio), nota dedupe en quality-gate SKILL | `.githooks/pre-commit-gate.ps1`, `.githooks/pre-push`, `SKILL.md` | Gate 13 checks intacto; pre-push skip post-commit |

**Fallos**: exit 1 = **4 fallos PRE-EXISTENTES** en `skill-graph.Tests.ps1:180-198` — `Get-AgentRecommendation` (<No file>:7) llama método sobre null → **bug de producción en skill-graph**, no drift de tests. Cero fallos nuevos introducidos.
**Write-scope**: 16/16 archivos de delegación dentro de scope (`.gentleman-mode` y `.project.json` son M pre-sesión, no de la delegación).
**Pendiente (P2)**: extraer libs para eliminar spawn-por-test (permission-gate 50×, engram-validate 24×…), TestHelpers.ps1 compartido, matar regex-extraction, fix `Get-AgentRecommendation`, actualizar PERFORMANCE-PLAN.md.

---

## Engram Persistence

- **id**: (ver mem_save en sesión)
- **topic_key**: `analysis/gentleman-agent-gh-tests-perf` (distinto del análisis general del mismo día para no pisarlo)
- **timestamp**: 2026-07-31

## Trend Analysis

| Análisis previo | Estado | Delta |
|---|---|---|
| 07-28 TDD/testing (cobertura) | ✅ Completado 7/7 | Cobertura: 13→26 archivos de test; hallazgos de *gates* (pre-commit sin tests, CodeCoverage) siguen vigentes |
| PERFORMANCE-PLAN.md (07-11) | ⚠️ Baseline obsoleto | 14.4s → 150.3s (paralelo) / ~553s (secuencial) — suite 10× más grande |
| 07-29 token-context (#8 fixtures bash-safe) | ➡️ Abierto | No relacionado con perf de tests |

**Nuevo en este análisis**: medición real de la suite, riesgo paralelo por estado compartido, spawn-por-test como patrón dominante, dedupe `!ship`/pre-push.

*Generado por análisis-mode con 3 subagentes (general ×2 medición+pipeline, explore estructura) + research web (pester.dev/usage/parallel, codykonior.com dot-sourcing benchmarks, Pester PR #2332).*
