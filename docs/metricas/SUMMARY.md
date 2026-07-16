# Metrics Summary

> Resumen ejecutivo de `docs/metricas/` — evidencia de scoring y tracking del proyecto.
> Los datos completos y detallados están en los archivos individuales de este directorio.

---

## 🏆 Benchmark Actual (2026-07-06)

| Métrica | Valor |
|---------|-------|
| Skills totales | 68 |
| Total skill bytes | ~124,000B |
| Skills >3KB | 0 |
| Avg skill size | 1,800B |
| Junctions globales OK | 68/68 |
| Frontmatter coverage | 100% |
| Scripts | 68 |

## 🚦 Quality Gate (2026-06-26)

| Resultado | Valor |
|-----------|-------|
| Passed | 9/9 |
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
