# 01 — Análisis detallado · Unit C: benchmark y Gap D (ses_021558, ses_021593)

## Datos medidos (orquestador, sesiones del ciclo)

| Medición | Contexto | Mediana |
|---|---|---|
| §0 baseline (regen) | Orquestador | 263.8 ms |
| C intento 1 | Subagente | +42.8% vs baseline |
| C retry warm | Subagente | 520.9 ms → +97.4% vs baseline |

## Veredicto

Benchmark no regresivo = **FAIL** (DoD §1.4).

## Causa raíz — Gap D (metodología)

1. El baseline §0 se mide en **contexto orquestador** (proceso principal, cache caliente del runtime del agente, estado de máquina distinto).
2. Las mediciones del ciclo (Unit C) se toman en **contexto subagente** (proceso delegado, cache fría o semi-fría, overhead de delegación).
3. Comparar ambas series = comparar peras con manzanas → la regresión +42.8% → +97.4% NO es atribuible a cambios de código del ciclo.
4. Unit A es test-only (no toca runtime: crea fixtures en `$env:TEMP`, no modifica `scripts/lib/` ni `opencode.json`) → excluida como causa por diseño.

## Acciones (Cycle #2)

- Medir baseline y ciclo en el MISMO contexto de ejecución (subagente o orquestador, elegido explícitamente).
- 5 runs + mediana + IQR (per plan-v3 §2, ya mandatado — el incumplimiento fue de ejecución, no de definición).
- **Persistir los runs en artefacto machine-readable** (`docs/metricas/` o `benchmarks.md`): hoy los números solo existen en sesión — descubrimiento de Unit D.
- Re-ejecutar benchmark del ciclo tras corregir metodología para re-clasificar el FAIL.
