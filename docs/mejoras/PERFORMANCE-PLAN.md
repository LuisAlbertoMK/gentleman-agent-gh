# Plan de Mejoras de Performance

**Fecha inicio:** 2026-07-11
**Ultima actualizacion:** 2026-07-31
**Objetivo:** Reducir tiempo de `!ship` de ~46s a ~1-2s

## Mediciones Base

| Componente | Tiempo Medido | Notas |
|------------|---------------|-------|
| run-tests.ps1 (parallel) | 38.5s | Tests Pester — baseline 2026-07-31, suite 26 files/472 Its (was 14.4s on 07-11; 150.3s parallel pre-opt on 07-31) |
| pssa-gate.ps1 | 28.5s | PSScriptAnalyzer - escanea TODO el repo |
| cross-ref-check.ps1 | 0.7s | Checks de integridad |
| score-auto.ps1 | 32.4s | Incluye PSSA como sub-job |
| Start-Job overhead | 1388ms/job | vs 84ms con ThreadJob |
| **TOTAL !ship** | **~46s** | Target: ~1-2s |

**Nota:** La optimizacion de run-tests.ps1 vive en la rama `experiment/tests-perf` (commit c0f0b459); detalle en `docs/mejoras/2026-07-31-gentleman-agent-gh-tests-perf.md`.

## Mejoras Planeadas

### P0 - Impacto Alto

| ID | Mejora | Estado | Tiempo Estimado | Responsable |
|----|--------|--------|-----------------|-------------|
| P0-1 | pssa-gate: solo escanear archivos cambiados (git diff) | ✅ Completado | 2-3h | subagent |
| P0-2 | score-auto: reemplazar Start-Job por Start-ThreadJob | ✅ Completado | 1h | subagent |
| P0-3 | pssa-gate: cache de resultados por sesion | ✅ Completado | 1-2h | subagent |

### P1 - Impacto Medio

| ID | Mejora | Estado | Tiempo Estimado | Responsable |
|----|--------|--------|-----------------|-------------|
| P1-1 | Verificar si run-tests.ps1 corre multiples veces en !ship | ✅ Completado | 1h | subagent |
| P1-2 | score-auto: leer SKILL.md una sola vez, reusar en hashtable | ✅ Completado | 2-3h | subagent |
| P1-3 | Merge Select-String passes en score-dims.ps1 | ✅ Completado | 1-2h | subagent |

### P2 - Impacto Bajo

| ID | Mejora | Estado | Tiempo Estimado | Responsable |
|----|--------|--------|-----------------|-------------|
| P2-1 | Shared file manifest para scripts | ✅ Completado | 2-3h | subagent |
| P2-2 | score-auto: invalidacion granular de cache | ✅ Completado | 2h | subagent |
| P2-3 | pssa-gate: excluir directorios innecesarios | ✅ Completado | 1h | subagent |

## Log de Cambios

| Fecha | Mejora | Cambio | Resultado |
|-------|--------|--------|-----------|
| 2026-07-11 | - | Mediciones iniciales | Baseline: 46s |
| 2026-07-11 | P0-2 | Start-Job → Start-ThreadJob (3 calls) | **Real: -4.7s** (37s → 32.3s, sin cache) |
| 2026-07-11 | P0-1 | pssa-gate.ps1: added `-Mode Incremental` — scans only `git diff --cached` .ps1 files, falls back to full scan if none | **Fallback test OK** — 32.7s (sin archivos staged) |
| 2026-07-31 | P0-3 | pssa-gate: session cache keyed por git HEAD + count/mtime/size de .ps1 (JSON en %TEMP%\opencode, nombre hasheado). Cache hit salta Invoke-ScriptAnalyzer, shape identica (RuleName/ScriptName/ScriptPath/Line/Severity) | Full scan 42-58s → cache hit **4.2-6.4s (~10x)**; exit 0 + PASSED, misma deuda (946 viol, 91 manual) |
| 2026-07-31 | P1-2 | score-dims: cada SKILL.md se lee **1 vez** (bytes → texto UTF-8 derivado + bytes reusados por Or). El hashtable existente queda como fuente unica | 82/82 skill files: texto identico a Get-Content -Raw; sin cambio de scores |
| 2026-07-31 | P1-3 | score-dims: Select-String sobre scripts reemplazado por regex sobre $scriptContentCache (line-split); LATEST_error.json leido 1 vez (Sec + SD); 4 scans de skills (redirect/changelog/triggers/refs) fusionados en 1 pasada | Flags identicos (1/1, 0/0, 82/82, 68/68); secret scan booleano identico; sin cambio de scores |
| 2026-07-31 | P2-1 | lib/file-manifest.ps1: Get-FileManifest compartido (relpath/length/mtime/sha256/group) — pssa-gate y score-auto consumen el mismo inventario | Manifest ~<1s; 0 callers duplicados |
| 2026-07-31 | P2-2 | pssa-gate: cache granular per-file (stamps len/mtime/sha256) — key sin git HEAD, solo sobrevive a commits; score-auto: compositeKey sin HEAD (solo content hashes) | pssa hit 5.5s (antes: miss 33.4s post-commit); granular 4.7s con 1 archivo tocado; score recompute 35.2s→12.5s, hit 3.4s |

## Resultados Verificados

| Mejora | Antes | Despues | Ahorro Real |
|--------|-------|---------|-------------|
| P0-2: ThreadJob | 37s (sin cache) | 32.3s (sin cache) | **4.7s (12.7%)** |
| P0-1: Incremental | 28.5s (full scan) | ~1-3s (solo cambios) | **~25s (cuando hay archivos staged)** |

**Nota:** P0-1 solo muestra mejora cuando hay archivos .ps1 en `git diff --cached`. Sin archivos staged, cae a full scan.

## Instrucciones para Subagentes

Al completar una mejora:
1. Actualizar el **Estado** de la fila correspondiente (🔲 → ✅ o 🔄 en progreso)
2. Agregar entrada en **Log de Cambios** con resultado medido
3. Si es P0, **re-medicar** y actualizar tabla de Resultados Verificados
4. Commit con mensaje: `perf(name): descripcion`
5. Actualizar **Ultima actualizacion** arriba

## Proximo Paso

Todos los items del plan completados (P0-1..3, P1-1..3, P2-1..3). El cache granular de pssa-gate hace que el post-commit de `!ship` pague solo los archivos cambiados (~5s en vez de ~33s). Hash lazy en el manifest (solo SHA256 cuando len/mtime cambian) implementado: warm 4.9s→1.79s, score hit 3.4s→2.5s. Opcional futuro: filtrar node_modules antes del Get-ChildItem recursivo para bajar el warm a <1s.
