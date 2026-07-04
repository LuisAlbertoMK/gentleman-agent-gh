# Consistencia (ORTO) — Hallazgos Consolidados

> **Cobertura**: Documentación desactualizada, naming, encoding, scores
> **Última revisión**: 2026-07-03 | **Verificación**: Subagente 2 contra código real

---

## Resumen

| ID | Severidad | Descripción | Fuentes | Estado |
|----|-----------|-------------|---------|--------|
| H-027 | 🟢 Bajo | AGENTS.md skill names incorrectos (3 names) | AA-Funcional#3, AA-Consistencia#1-3 | ✅ Resuelto |
| H-028 | 🟢 Bajo | Score desync entre 4 fuentes | AE-F2 | ✅ Resuelto |
| H-029 | 🟢 Bajo | Skill count inconsistente (README vs real) | AE-F1 | ✅ Resuelto |
| H-030 | 🟢 Bajo | BOM inconsistente (35/55 con BOM, 20 sin) | AA-Consistencia#9 | ✅ Resuelto |
| H-031 | 🟢 Bajo | SDD skills duplicadas (sdd/ folder + sdd-* naming) | AA-Técnico#12, AA-Consistencia#12 | ⏹️ Intencional |

---

## Detalle

### H-027: AGENTS.md skill names incorrectos (✅ RESUELTO)

**Severidad**: 🟢 Bajo → ✅ Resuelto
**Origen**: AA-Funcional#3, AA-Consistencia#1-3
**Descripción**: 3 skill names incorrectos: `gentle-ai-chained-pr` → `chained-pr`, `a11y` → `accessibility`, `model-router` → `opencode-model-router`
**Resuelto en**: Commits a656b27 + 70aeffc

---

### H-028: Score desync (✅ RESUELTO)

**Severidad**: 🟢 Bajo → ✅ Resuelto
**Origen**: AE-F2
**Descripción**: 4 fuentes con 4 números diferentes (PROJECT-SCORE.md, project-score.md, README, hallazgos-completos.md, docs/ciclos/)
**Resuelto en**: Commit 99c36fe — consolidado a 10/10 en todas las fuentes

---

### H-029: Skill count inconsistente (✅ RESUELTO)

**Severidad**: 🟢 Bajo → ✅ Resuelto
**Origen**: AE-F1
**Descripción**: README decía 67 skills vs 69 en package.json vs 68 reales
**Resuelto en**: Commit 99c36fe — sincronizado a 68 + `_shared`

---

### H-030: BOM inconsistente (✅ RESUELTO)

**Severidad**: 🟢 Bajo → ✅ Resuelto
**Origen**: AA-Consistencia#9
**Descripción**: 35/55 scripts con BOM, 20 sin BOM. PSSA recomienda sin BOM (UTF8NoBOM).
**Resuelto**: 2026-07-03 — Stripeado BOM de 31 scripts (todos excepto ps5-detect.ps1 que necesita BOM para compatibilidad PS5). Quedan 0/54 sin BOM.

---

### H-031: SDD skills duplicadas (⏹️ INTENCIONAL)

**Severidad**: 🟢 Bajo → ⏹️ Intencional
**Origen**: AA-Técnico#12, AA-Consistencia#12
**Descripción**: `.agents/skills/sdd/` (unificada) coexiste con 9 skills `sdd-*` (wrappers con `{file:}` references).
**Decisión**: 2026-07-03 — Mantener capa de compatibilidad. El sistema descubre skills por nombre de directorio; sin wrappers las fases no serían discoverables individualmente. No hay duplicación de contenido real.
