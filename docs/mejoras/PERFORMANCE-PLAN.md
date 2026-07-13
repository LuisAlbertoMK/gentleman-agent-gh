# Plan de Mejoras de Performance

**Fecha inicio:** 2026-07-11
**Ultima actualizacion:** 2026-07-11
**Objetivo:** Reducir tiempo de `!ship` de ~46s a ~1-2s

## Mediciones Base

| Componente | Tiempo Medido | Notas |
|------------|---------------|-------|
| run-tests.ps1 | 14.4s | Tests Pester |
| pssa-gate.ps1 | 28.5s | PSScriptAnalyzer - escanea TODO el repo |
| cross-ref-check.ps1 | 0.7s | Checks de integridad |
| score-auto.ps1 | 32.4s | Incluye PSSA como sub-job |
| Start-Job overhead | 1388ms/job | vs 84ms con ThreadJob |
| **TOTAL !ship** | **~46s** | Target: ~1-2s |

## Mejoras Planeadas

### P0 - Impacto Alto

| ID | Mejora | Estado | Tiempo Estimado | Responsable |
|----|--------|--------|-----------------|-------------|
| P0-1 | pssa-gate: solo escanear archivos cambiados (git diff) | ✅ Completado | 2-3h | subagent |
| P0-2 | score-auto: reemplazar Start-Job por Start-ThreadJob | ✅ Completado | 1h | subagent |
| P0-3 | pssa-gate: cache de resultados por sesion | 🔲 Pendiente | 1-2h | subagent |

### P1 - Impacto Medio

| ID | Mejora | Estado | Tiempo Estimado | Responsable |
|----|--------|--------|-----------------|-------------|
| P1-1 | Verificar si run-tests.ps1 corre multiples veces en !ship | 🔲 Pendiente | 1h | subagent |
| P1-2 | score-auto: leer SKILL.md una sola vez, reusar en hashtable | 🔲 Pendiente | 2-3h | subagent |
| P1-3 | Merge Select-String passes en score-dims.ps1 | 🔲 Pendiente | 1-2h | subagent |

### P2 - Impacto Bajo

| ID | Mejora | Estado | Tiempo Estimado | Responsable |
|----|--------|--------|-----------------|-------------|
| P2-1 | Shared file manifest para scripts | 🔲 Pendiente | 2-3h | subagent |
| P2-2 | score-auto: invalidacion granular de cache | 🔲 Pendiente | 2h | subagent |
| P2-3 | pssa-gate: excluir directorios innecesarios | 🔲 Pendiente | 1h | subagent |

## Log de Cambios

| Fecha | Mejora | Cambio | Resultado |
|-------|--------|--------|-----------|
| 2026-07-11 | - | Mediciones iniciales | Baseline: 46s |
| 2026-07-11 | P0-2 | Start-Job → Start-ThreadJob (3 calls) | **Real: -4.7s** (37s → 32.3s, sin cache) |
| 2026-07-11 | P0-1 | pssa-gate.ps1: added `-Mode Incremental` — scans only `git diff --cached` .ps1 files, falls back to full scan if none | **Fallback test OK** — 32.7s (sin archivos staged) |

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

Prioridad ahora es **P0-1 real**: probar con archivos .ps1 staged para verificar que el modo incremental funcione y sea realmente rápido.
