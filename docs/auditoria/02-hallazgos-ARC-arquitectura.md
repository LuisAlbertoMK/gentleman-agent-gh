# Arquitectura (ARC) — Hallazgos Consolidados

> **Cobertura**: Deuda técnica, scripts faltantes, race conditions, patrones
> **Última revisión**: 2026-07-03 | **Verificación**: Subagente 2 contra código real

---

## Resumen

| ID | Severidad | Descripción | Fuentes | Estado |
|----|-----------|-------------|---------|--------|
| H-003 | 🟡 Medio | 8 scripts: 3=skill names, 5=planning debt (reclasif) | AA-RevLineal#19-21, HC-tabla-modificar, AE-#4 | 🔴 Pendiente |
| H-004 | 🔴 Crítico | Race condition inter-track.ps1 JSON read-modify-write | AA-Negocio#7 | ✅ Resuelto |
| H-008 | 🟠 Alto | docs/hallazgos-completos.md refs inexistentes | AA-Consistencia#4 | ✅ Resuelto |
| H-011 | 🟡 Medio | GA2: ForEach-Object -Parallel no implementado | HC-GA2 | 🟡 Parcial |
| H-015 | 🟡 Medio | restore.ps1 path traversal — fix aplicado (usa $resolved) | AA-Inyección#2 | ✅ Resuelto |
| H-016 | 🟢 Bajo | Parámetros 1 letra (3 scripts fix, 19 inner pendientes) | AA-Consistencia#11 | 🟡 Parcial |
| H-018 | 🟢 Bajo | Comandos huérfanos (sdd-continue, sdd-ff, sdd-new) sin implementación | AA-Linting#5-7 | ✅ Resuelto |

---

## Detalle

### H-003: 8 scripts referenciados no existen

**Severidad**: 🔴 Crítico
**Origen**: AA-RevLineal-P1#19-21, HC-tabla-modificar, AE-#4
**Archivos referenciados que NO existen**:
| Script | Referenciado en |
|--------|-----------------|
| `scripts/auto-metrics.ps1` | AGENTS.md (pipeline post-task) |
| `scripts/commit-crafter.ps1` | AGENTS.md (pipeline !ship) |
| `scripts/intake.ps1` | AGENTS.md (pipeline intake) |
| `scripts/git-fast.ps1` | hallazgos-completos.md (GD2) |
| `scripts/measure-ps.ps1` | hallazgos-completos.md |
| `scripts/memory-tune.ps1` | hallazgos-completos.md (GA4) |
| `scripts/skill-auto-generator.ps1` | hallazgos-completos.md (GA4) |
| `scripts/vmk-safety-check.ps1` | hallazgos-completos.md (GA4) |

**Verificado**: 2026-07-03 — 3 subagentes. 3/8 son realmente nombres de skills en AGENTS.md (auto-metrics, commit-crafter, intake), no scripts rotos. 5/8 son propuestas de planificación nunca implementadas (git-fast, measure-ps, memory-tune, skill-auto-generator, vmk-safety-check).
**Reclasificado**: 🔴 Crítico → 🟡 Medio. No hay pipelines rotos. Los 3 primeros son skills, no scripts. Los 5 restantes son deuda de planificación.
**Recomendación**: Mover docs de planificación GA4/GD2 a docs/auditoria/05-archivo/. No requiere crear scripts.

---

### H-004: Race condition inter-track.ps1 (✅ RESUELTO)

**Severidad**: 🔴 Crítico → ✅ Resuelto
**Origen**: AA-Negocio#7
**Archivo**: `scripts/inter-track.ps1:56,104`
**Verificado**: 2026-07-03 — Código actual **YA** implementa `Invoke-TrackLocked` (línea 56) que usa `[System.IO.FileStream]::new(... [System.IO.FileShare]::None)` para lock exclusivo durante read-modify-write. Escritura atómica: `SetLength(0) → Seek(Begin) → Write → Flush`.
**Resuelto**: File lock con `FileShare::None` implementado. Race condition mitigada.

---

### H-008: docs desactualizados — 5 scripts inexistentes referenciados

**Severidad**: 🟠 Alto → ✅ Resuelto
**Origen**: AA-Consistencia#4
**Archivo**: `docs/hallazgos-completos.md` (tabla "Archivos a Modificar")
**Descripción**: El documento referencia 5 scripts que no existen: git-fast.ps1, measure-ps.ps1, memory-tune.ps1, skill-auto-generator.ps1, vmk-safety-check.ps1.
**Resuelto**: 2026-07-03 — hallazgos-completos.md es artifacto histórico. Consolidado en docs/auditoria/. Los scripts son de planificación, no rotura real (ver H-003 reclasificado).

---

### H-011: GA2 — ForEach-Object -Parallel no implementado

**Severidad**: 🟡 Medio
**Estado**: 🟡 Parcial
**Origen**: HC-GA2
**Archivos**: `scripts/skill-graph.ps1`, `scripts/score-auto.ps1`, `scripts/pssa-gate.ps1`
**Verificado**: 2026-07-03 — commit 3b144ab menciona "optimizaciones GA4" pero no GA2. No hay evidencia de `-Parallel` implementado.
**Recomendación**: Implementar `ForEach-Object -Parallel -ThrottleLimit 4` en hot paths.
**Speedup estimado**: 4-8x en skill-graph.ps1 (BFS por keyword), 3-7x en score-auto.ps1 (7 dims secuenciales → paralelas).
**Prevención**: Incluir en benchmark CI (comparar tiempos antes/después).

---

### H-015: Path traversal potencial en restore.ps1 (✅ RESUELTO)

**Severidad**: 🟡 Medio → ✅ Resuelto
**Origen**: AA-Inyección#2
**Archivo**: `scripts/restore.ps1:28,37`
**Descripción**: `$Revision` de usuario sin validación en `git checkout "$Revision" -- .`. Podía contener `../` para path traversal.
**Resuelto**: 2026-07-03 — Se cambió a usar `$resolved` (commit hash ya validado por git rev-parse) en lugar de `$Revision` raw. Path traversal bloqueado porque git checkout rechaza paths fuera del repo.

---

### H-016: Parámetros de una letra (🟡 PARCIAL)

**Severidad**: 🟢 Bajo
**Origen**: AA-Consistencia#11, AA-Técnico#13
**Archivos**: 11 scripts usan parámetros de una letra (`$J`, `$D`, `$s`, `$i`, etc.)
**Resuelto parcial**: 2026-07-03 — 3 scripts con parámetros de script-level renombrados: cross-ref-check.ps1 ($R→$RepoRoot, $J→$Json), intake-verify.ps1 ($p→$Path, $i→$Level, $t→$Type, $m→$Minimal, $f→$Format), project-cycle.ps1 ($N→$Number). Quedan ~19 parámetros inner-function de 1 letra en scripts restantes — baja prioridad (contexto local claro).

---

### H-018: Comandos huérfanos SDD (✅ RESUELTO)

**Severidad**: 🟢 Bajo → ✅ Resuelto
**Origen**: AA-Linting#5-7, AA-Consistencia#13
**Descripción**: `sdd-continue`, `sdd-ff`, `sdd-new` referenciados en skills pero sin implementación.
**Resuelto**: 2026-07-03 — Los 3 comandos existen en `commands/` con contenido real: WORKFLOW, CONTEXT, ENGRAM. `sdd-new` (start → explore → propose), `sdd-ff` (propose → spec → design → tasks), `sdd-continue` (next phase from dep graph).
