# Metrics Summary

> Resumen ejecutivo de `docs/metricas/` — evidencia de scoring y tracking del proyecto.
> Los datos completos y detallados están en los archivos individuales de este directorio.

---

## 🏆 Benchmark Actual (2026-06-25)

| Métrica | Valor |
|---------|-------|
| AGENTS.md | 20,071B / 365 líneas |
| Skills totales | 69 |
| Total skill bytes | 122,000B |
| Skills >3KB | 0 |
| Avg skill size | 1,700B |
| Junctions globales OK | 69/69 |
| Frontmatter coverage | 100% |
| Scripts | 40 |

## 🚦 Quality Gate (2026-06-21)

| Resultado | Valor |
|-----------|-------|
| Passed | 9/9 |
| Failed | 0 |
| Bloqueado | No |
| Errores | 0 |
| Warnings | 0 |

## 📈 Rendimiento (2026-06-13 baseline → 2026-06-15 final)

| Ronda | Foco | Mejora |
|-------|------|--------|
| Intake | Baseline inicial | — |
| Phase 1 | Compactación skills | Skills >3KB eliminados |
| Sparse loading | Skill-graph dependency resolver | -85-92% skills cargadas |
| Tools compression | Compresión de herramientas | Reducción significativa |
| Plugin optimization | Hermes Agent plugin | Optimización de 7 tools |
| Perf optimization | Rendimiento general | Mejora integral |
| Final round | Última ronda | Consolidación |

## ⚙️ Baselines

| Baseline | Archivo | Propósito |
|----------|---------|-----------|
| Intake | `intake-baseline.json` | Estado inicial del proyecto |
| PSSA | `pssa-baseline.json` | PowerShell Script Analyzer baseline |

---

> **⚠️ Important**: No eliminar este directorio. 6 scripts del proyecto (`score-auto.ps1`, `trend.ps1`,
> `capture-errors.ps1`, `benchmark.ps1`, `intake-verify.ps1`, `pssa-gate.ps1`) dependen
> funcionalmente de archivos en `docs/metricas/`. Ver `docs/INDEX.md` para más detalles.
