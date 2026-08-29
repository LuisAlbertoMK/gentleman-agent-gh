# Perf Pruning 4000 — A/B Test Plan (P2, Ciclo P2)

- **Fecha**: 2026-08-28
- **Rama**: `experiment/perf-deep-2026-08-28`
- **Objetivo**: Evaluar bajar `compaction.keep.tokens` de 6000 → 4000 (y `reserved` 4000 → 2000) midiendo tokens/turno, latencia y calidad; decidir con evidencia estadística, no intuición.
- **Tipo**: P2 (una config reversible, blast radius medio: solo `opencode.json` + gate de calidad).

## 1. ContextSpy — contexto del problema

Datos de referencia (ContextSpy / benchmarks de pruning, 2026):

- Ratio input/output típico: **20–50×** — el contexto de entrada domina el costo por turno.
- Contexto fresco: **5–10K tokens** en sesiones cortas; **30–50K en turno 25**.
- Ventana rotativa: **100K (Ctx 100K)** — el techo no es el límite real; el grow es lo que comprime.
- **GemFilter**: pruning 1000× (modelo 1000× más pequeño) → **2.4× speedup**, **30% menos GPU mem**, calidad preservada en tareas estándar.
- **SWE-Pruner**: 2601 issues reales (SWE-bench) validando que prune agresivo no degrada tareas de ingeniería — la evidencia respalda que 4000 keep es viable para tareas tipo repo-agent.
- Implicación: el keep actual 6000 reserva contexto a costa de más tokens por turno; 4000 reduce rotación y bytes/turno, riesgo acotado a tareas multi-archivo largas.

## 2. Estado actual (evidencia, file:line)

| Campo | Valor actual | Fuente |
|---|---|---|
| `compaction.auto` | `true` | `opencode.json:244` |
| `compaction.prune` | `true` | `opencode.json:245` |
| `compaction.reserved` | `4000` | `opencode.json:246` |
| `compaction.keep.tokens` | `6000` | `opencode.json:248` |
| Último commit que tocó el config | `d66bd93e` (perf(deep) P0 RAM/CPU) | `git log -- opencode.json` |
| Rama actual | `experiment/perf-deep-2026-08-28` | `git branch --show-current` |

**hardware-profile.ps1** (SSoT de perfiles — nota: difiere de la premisa del ticket en MED):

- LOW  → `reserved 4000 / keep 8000` — `scripts/hardware-profile.ps1:132`
- MED  → `reserved 6000 / keep 12000` — `scripts/hardware-profile.ps1:158`
- HIGH → `reserved 8000 / keep 15000` — `scripts/hardware-profile.ps1:182`
- Definición de perfiles (RAM/cores/GPU): `scripts/hardware-profile.ps1:14-22`

> **Fidelity flag**: la premisa del ticket decía "LOW 4000/8000 MED 4000/8000 HIGH 8000/15000"; la evidencia real es LOW 4000/8000, MED 6000/12000, HIGH 8000/15000. El A/B se diseña contra el SSoT real (`hardware-profile.ps1:132,158,182`). impactado: solo el copy del ticket; el plan no cambia.

## 3. Plan A/B

**Diseño**: mismo repo, rama `experiment/perf-deep-2026-08-28`, toggle de config con backup/restore vía `scripts/test-compaction-ab.ps1` (stub creado junto a este doc).

| | **A — Baseline (control)** | **B — Prune 4000 (experimento)** |
|---|---|---|
| `keep.tokens` | 6000 (`opencode.json:248`) | 4000 |
| `reserved` | 4000 (`opencode.json:246`) | 2000 |
| `prune` / `auto` | true / true (sin cambios) | true / true (sin cambios) |

**Alternativa aceptada**: se permite correr B en la misma rama con toggle (rama de experimento ya dedicada), sin forzar branch nueva — evita churn de merge y el toggle es el propio script.

### Métricas

| Métrica | Instrumento | Umbral de decisión |
|---|---|---|
| Tokens por turno (T25, sesión larga) | ContextSpy / monitor de sesión | B < A (esperado 15–30% menos) |
| Latencia | `scripts/benchmark-regression.ps1 -Runs 10 -Json` — **median**, no media (protocolo §0.7) | B ≤ A + 1.5×IQR (sin regresión statistical) |
| Calidad (no bajar) | gate manual en tareas benchmark: 3 tareas representativas, resultado ≥ A (no regresión funcional) | **calidad no debe bajar** |
| Budget de skills/prompts | `scripts/check-token-budget.ps1 -Json` | sin violaciones nuevas (ADR-007, keep 2000B / prompt 4000B) |

### Protocolo de ejecución (10 runs)

1. `git status` limpio (solo los 2 archivos de este A/B) → backup `opencode.json` vía `test-compaction-ab.ps1` (escritura protegida: backup automático + restore en `finally`).
2. **Fase A**: config 6000/4000 → correr `benchmark-regression.ps1 -Command <bench> -Runs 10 -Json` → capturar `median_ms` → `check-token-budget.ps1 -Json`.
3. Toggle a **Fase B**: config 4000/2000 → mismas 10 runs → capturar `median_ms`.
4. Comparar median A vs B + calidad (3 tareas benchmark manuales por fase).
5. Restore config original; reportar tabla de decisión: `Prune 4000 → adoptar / rechazar / re-test`.
6. Decisión final se documenta en este file (sección 5) y, si adoptar → se persiste el cambio con commit conventional.

**Criterio de veredicto**:
- Adoptar 4000 solo si: median(B) ≤ median(A)×1.15 (threshold default del gate) **y** calidad ≥ A **y** token-budget sin violaciones.
- Si calidad baja o latencia peor >15% → rechazar, restaurar 6000, documentar en mejora-log.

## 4. Riesgo y mitigación

| Riesgo | Severidad | Mitigación |
|---|---|---|
| **Calidad con 4000 keep si contexto rot < 6000 en Ctx 100K** — tareas que necesitan >4000 tokens de historial reciente pierden detalle post-compactación | MEDIA | Ventana es 100K (Ctx 100K), el rot ocurre muy por encima de keep; `small_model` (GemFilter pattern) ayuda a resumir sin perder señal — el pruning 1000× valida speedup 2.4× con calidad estable (ContextSpy). Gate de calidad manual (3 tareas) antes de decidir |
| Benchmarks ruidosos (carga HW) | MEDIA | 10 runs + median/IQR (protocolo §0.7), mismo hardware, ventana horaria fija |
| Error de edición de `opencode.json` rompe config | ALTA | `test-compaction-ab.ps1` valida JSON con `ConvertFrom-Json` antes de aplicar; backup + restore en `finally`; éste es el motivo del stub |
| Drift con SSoT (hardware-profile) | BAJA | El toggle modifica exclusivamente `compaction.*`; no toca perfiles |

## 5. Resultado (a completar post-ejecución)

| Fase | median_ms | tokens/turno T25 | calidad (3 tareas) | check-token-budget |
|---|---|---|---|---|
| A (6000/4000) | — | — | — | — |
| B (4000/2000) | — | — | — | — |

**Veredicto**: pendiente.

## Referencias

- Protocolo estadístico: `protocolo_mejora_autonoma_v3.md` §0.7 (5–10 runs, median + IQR — implementado en `scripts/benchmark-regression.ps1:5-9`).
- Config SSoT: `opencode.json:243-250`; perfiles: `scripts/hardware-profile.ps1`.
- Gate ADR-007: `scripts/check-token-budget.ps1` (target 2000B skills / 4000B prompts).