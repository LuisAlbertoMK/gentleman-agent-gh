# Rendimiento (PERF) — Hallazgos Consolidados

> **Cobertura**: PS7 migration, Parallel, .NET methods, token optimization, PSSA
> **Última revisión**: 2026-07-03 | **Verificación**: Subagente 2 contra código real

---

## Resumen

| ID | Severidad | Descripción | Fuentes | Estado |
|----|-----------|-------------|---------|--------|
| H-012 | 🟡 Medio | GA1: #requires -Version 7 (✅ 54/55 scripts en 7.6) | HC-GA1, AE-P0 | ✅ Resuelto |
| H-013 | 🟡 Medio | GA3: JsonFast module (scripts/lib/JsonFast.psm1) | HC-GA3 | ✅ Resuelto |
| H-014 | 🟡 Medio | GC1: PSSA Gate con auto-fix (scripts/pssa-gate.ps1) | HC-GC1 | ✅ Resuelto |
| H-011 | 🟡 Medio | GA2: ForEach-Object -Parallel en hot paths | HC-GA2 | 🟡 Parcial (ver ARC) |
| H-017 | 🟡 Medio | GA4: .NET hot paths restantes (backup, restore) | HC-GA4 | ✅ No aplica — backup/restore son wrappers git, no I/O |
| H-020 | 🟢 Bajo | GB1: TALE Token Budgets en skills | HC-GB1 | ✅ Resuelto — regla única en lean-context |
| H-021 | 🟢 Bajo | GB2: Compression decision tree formalizado | HC-GB2 | ✅ Resuelto — árbol mejorado en context-watchdog |
| H-022 | 🟢 Bajo | GB3: Dynamic skill loading (top-3 pre-turn) | HC-GB3 | ⏸️ Deferido — requiere diseño (2-4h) |
| H-023 | 🟢 Bajo | GB4: Structured Output (TOON format) | HC-GB4 | ⏸️ Deferido — experimental |

---

## Detalle

### H-012: GA1 — #requires -Version 7 (✅ RESUELTO)

**Severidad**: 🟡 Medio → ✅ Resuelto
**Origen**: HC-GA1, AE-P0
**Verificado**: 2026-07-03 — `Select-String` sobre todos los .ps1:
- 54/55 scripts con `#requires -Version 7.6`
- 1 script con `#requires -Version 5.1` (ps5-detect.ps1 — intencional)
- CI gate bloquea .ps1 nuevos sin `#requires -Version 7`
**Resuelto en**: Commit 3b144ab (barrido final de 8 scripts restantes)
**Progreso**: 19% → 98% en este ciclo

---

### H-013: GA3 — JsonFast Module (✅ RESUELTO)

**Severidad**: 🟡 Medio → ✅ Resuelto
**Origen**: HC-GA3
**Verificado**: 2026-07-03 — `scripts/lib/JsonFast.psm1` existe (1,123 bytes) + smoke test
**Resuelto en**: Commit 3b144ab

---

### H-014: GC1 — PSSA Gate (✅ RESUELTO)

**Severidad**: 🟡 Medio → ✅ Resuelto
**Origen**: HC-GC1
**Verificado**: 2026-07-03 — `scripts/pssa-gate.ps1` existe con modos Check/Fix/Trend, auto-heal BOM + alias
**Pendiente**: Verificar conteo de warnings PSSA < 50 (objetivo GC1)

---

### H-017: GA4 — .NET hot paths restantes

**Severidad**: 🟡 Medio → ✅ No aplica
**Origen**: HC-GA4
**Verificado**: 2026-07-03 — commit 3b144ab aplicó StreamReader + EnumerateFiles en hot paths principales (score-auto.ps1, pssa-gate.ps1, verify.ps1, cross-ref-check.ps1).
**Razón**: backup.ps1 y restore.ps1 son wrappers de git — no hacen file I/O sobre archivos grandes. La optimización .NET no aplica. Hot paths principales ya cubiertos.

---

### H-020: GB1 — TALE Budgets

**Severidad**: 🟢 Bajo → ✅ Resuelto
**Origen**: HC-GB1
**Descripción**: Agregar estimación de tokens por skill load para planificación de contexto.
**Resuelto**: 2026-07-03 — Regla única en `lean-context/SKILL.md` (vs spray de 68 skills): "~200 tokens per loaded skill" con ejemplo de presupuesto (4-8 skills → ~1-1.6K tokens).

### H-021: GB2 — Compression Tree

**Severidad**: 🟢 Bajo → ✅ Resuelto
**Origen**: HC-GB2
**Descripción**: Documentar árbol de decisión en context-watchdog skill.
**Resuelto**: 2026-07-03 — Árbol de decisión mejorado en `context-watchdog/SKILL.md` con TALE recalc en checkpoint (25 tool calls).

### H-022: GB3 — Dynamic Loading

**Severidad**: 🟢 Bajo → ⏸️ Deferido
**Origen**: HC-GB3
**Descripción**: Skill-graph + skill-digestion: cargar top-3 pre-turn. 2-4h (cambio arquitectura).
**Recomendación**: Requiere diseño. Deferido a próximo ciclo.

### H-023: GB4 — TOON Format

**Severidad**: 🟢 Bajo → ⏸️ Deferido
**Origen**: HC-GB4
**Descripción**: Prompts en formato TOON (pipe-separated) vs JSON. Experimental.
**Recomendación**: Deferido. Evaluar overhead vs beneficio.
