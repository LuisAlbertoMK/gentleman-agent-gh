# Índice de Auditoría Consolidada — gentleman-agent-gh

> **Fuente única de verdad** para todos los hallazgos de auditoría.
> Consolida 3 fuentes previas: `auditoria-adaptada/`, `hallazgos-completos.md`, `AUDITORIA-EXTERNA-gentleman-agent-gh.md`
> Creado: 2026-07-03 | Metodología: 3 subagentes de análisis + verificación contra código real

---

## Estado Actual

| Métrica | Valor |
|---------|-------|
| **Total hallazgos únicos** | 31 |
| ✅ **Resueltos** | 21 |
| 🔴 **Pendientes** | 1 |
| 🟡 **En progreso** (parcial) | 2 |
| ⏸️ **Deferidos** | 4 |
| ❌ **Falso positivo** | 1 |
| ➖ **No aplica** | 1 |
| ⏹️ **Intencional** | 1 |
| Última actualización | 2026-07-03 |

---

## Hallazgos Pendientes

Sin hallazgos 🔴 pendientes. Todos resueltos o deferidos.

### Deferidos (⏸️)

| ID | Severidad | Categoría | Descripción |
|----|-----------|-----------|-------------|
| H-024 | 🟢 Bajo | OPS | git-fast.ps1 no existe (propuesta GD2) |
| H-025 | 🟢 Bajo | OPS | .husky/pre-commit no existe (propuesta GD3) |
| H-003 | 🟡 Medio | ARC | 8 scripts (3=skill names, 5=planning debt — reclasificado) |
| H-016 residual | 🟢 Bajo | ARC | ~19 params inner-function de 1 letra |

### Parciales

| ID | Severidad | Categoría | Descripción |
|----|-----------|-----------|-------------|
| H-011 (ARC) | 🟡 Medio | ARC | GA2: Parallel + evidencias parciales |
| H-015 | 🟡 Medio | ARC | restore.ps1 path traversal — fix aplicado | 🟡 Parcial |
| H-016 | 🟢 Bajo | ARC | Parámetros 1 letra (3 scripts fix, 19 inner pendientes) | 🟡 Parcial |

---

## Archivos de Detalle

| Archivo | Cobertura | Hallazgos |
|---------|-----------|-----------|
| [02-hallazgos-SEG-seguridad.md](02-hallazgos-SEG-seguridad.md) | Seguridad: download cradles, inyección, secrets | H-001, H-002, H-009, H-010 |
| [02-hallazgos-ARC-arquitectura.md](02-hallazgos-ARC-arquitectura.md) | Deuda técnica, scripts faltantes, race conditions | H-003, H-004, H-008, H-011, H-015, H-016, H-018 |
| [02-hallazgos-PERF-rendimiento.md](02-hallazgos-PERF-rendimiento.md) | PS7, Parallel, .NET, tokens, PSSA | H-012, H-013, H-014, H-017, H-020, H-021, H-022, H-023 |
| [02-hallazgos-OPS-operaciones.md](02-hallazgos-OPS-operaciones.md) | CI, infra, pre-commit, paths, BOM | H-005, H-006, H-007, H-019, H-024, H-025, H-026 |
| [02-hallazgos-ORTO-consistencia.md](02-hallazgos-ORTO-consistencia.md) | Docs, naming, scores, encoding | H-027, H-028, H-029, H-030, H-031 |

---

## Enlaces Rápidos

| Documento | Descripción |
|-----------|-------------|
| [01-resumen-ejecutivo.md](01-resumen-ejecutivo.md) | Top hallazgos, matriz de riesgo, priorización |
| [03-plan-implementacion.md](03-plan-implementacion.md) | Plan P0-P3 detallado (GA1-GD3) |
| [04-lecciones-aprendidas.md](04-lecciones-aprendidas.md) | Regresiones, causas raíz, prevención |
| [05-archivo/](05-archivo/) | Documentos históricos (prompt original, categorías web) |

---

## Mantenimiento

**Cada sesión:**
1. Revisar este índice al inicio si hay hallazgos 🔴 Pendientes
2. Si trabajás en un hallazgo, movelo a 🟡 En progreso
3. Si resolvés uno, cambiá a ✅ Resuelto + anotá commit/PR
4. Si reaparece uno resuelto → 🔄 Regresión + entrada en `04-lecciones-aprendidas.md`

**Triggers automáticos:**
- `!health` mostrar conteo de pendientes
- Pre-commit: si toca archivo listado en hallazgo, recordar
