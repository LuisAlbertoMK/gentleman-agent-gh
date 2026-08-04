# Metrics Summary

> Resumen ejecutivo de `docs/metricas/` — evidencia de scoring y tracking del proyecto.
> Los datos completos y detallados están en los archivos individuales de este directorio.

---

## 🏆 Benchmark Actual (2026-08-03, `benchmark.ps1 -Gate` + snapshot)

| Métrica | Valor |
|---------|-------|
| Skills totales | 78 |
| Total skill bytes | 196,262B (4,576 líneas) |
| Skills >3KB | 0 |
| Avg skill size | 2,516B (median 2,476B) |
| Junctions globales OK | 78/78 (modelo híbrido, ver ADR-009) |
| Frontmatter coverage | 100% (WhenToUse 98.7%, Rules 43.6%) |
| Scripts | 83 |
| Suite E2E completa | 702 pass / 0 fail |
| Gate pre-commit | 16/16 |

> Snapshots machine-readable históricos en `docs/metricas/snapshots/` (p.ej. `20260803-051109_benchmark.json`, baseline hybrid junction 78/78).

## 🚦 Quality Gate (2026-08-04)

| Resultado | Valor |
|-----------|-------|
| Passed | 16/16 |
| Failed | 0 |

## ⚙️ Baselines

| Baseline | Archivo | Propósito |
|----------|---------|-----------|
| Intake | `intake-baseline.json` | Estado inicial del proyecto |
| PSSA | `pssa-baseline.json` | PSSA baseline (41 warnings manuales) |

---

> **⚠️ Note**: No eliminar este directorio. Scripts del proyecto (`score-auto.ps1`, `trend.ps1`,
> `capture-errors.ps1`, `intake-verify.ps1`, `pssa-gate.ps1`) dependen
> de archivos en `docs/metricas/`.
