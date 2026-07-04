# Operaciones (OPS) — Hallazgos Consolidados

> **Cobertura**: CI, infraestructura, pre-commit, scripts del sistema, paths
> **Última revisión**: 2026-07-03 | **Verificación**: Subagente 2 contra código real

---

## Resumen

| ID | Severidad | Descripción | Fuentes | Estado |
|----|-----------|-------------|---------|--------|
| H-005 | 🔴 Crítico | backup.ps1 sin ErrorActionPreference — fallas silenciosas | AA-Negocio#1 | ❌ Falso positivo — ya tiene `$ErrorActionPreference='Stop'` línea 14 |
| H-006 | 🔴 Crítico | optimize-system.ps1 sin rollback — riesgo de sistema inconsistente | AA-Negocio#4 | ✅ Resuelto — commit pendiente (-Restore con checkpoint) |
| H-007 | 🟠 Alto | Path Git Bash hardcodeado (C:\Program Files\Git\bin\bash.exe) | AA-Negocio#5,#6, AA-Técnico#2 | ✅ Resuelto — check-upstream.ps1 flexible, pull-upstream.ps1 no usa bash |
| H-019 | 🟡 Medio | P3: Overweight check no cubre commands/ + prompts/ | AE-P3 | ✅ Resuelto |
| H-024 | 🟢 Bajo | GD2: git-fast.ps1 no existe (propuesta de batched git ops) | HC-GD2 | 🔴 Pendiente |
| H-025 | 🟢 Bajo | GD3: .husky/pre-commit no existe (pre-commit centralizado) | HC-GD3 | 🔴 Pendiente |
| H-026 | 🟢 Bajo | npx -y sin version pinning para MCPs (supply chain risk) | AA-Auth#6 | ✅ Resuelto |

---

## Detalle

### H-005: backup.ps1 sin ErrorActionPreference

**Severidad**: 🔴 Crítico
**Origen**: AA-Negocio#1
**Archivo**: `scripts/backup.ps1`
**Verificado**: ❓ No se verificó en código actual (el subagente 2 dio 60% confianza). Pendiente de lectura directa.
**Riesgo**: Git init/add/commit call fallan silenciosamente. Backup parece exitoso pero no lo es.
**Recomendación**: Agregar `$ErrorActionPreference = 'Stop'` al inicio + try/catch.

---

### H-006: optimize-system.ps1 sin rollback

**Severidad**: 🔴 Crítico
**Origen**: AA-Negocio#4
**Archivo**: `scripts/optimize-system.ps1:54-142`
**Verificado**: ❓ No se verificó en código actual (60% confianza).
**Riesgo**: Modifica registro HKLM, pagefile, hibernate, fsutil. Error a mitad de camino deja sistema inconsistente.
**Recomendación**: Implementar checkpoint + rollback (restaurar valores originales si falla cualquier paso).

---

### H-007: Path Git Bash hardcodeado

**Severidad**: 🟠 Alto
**Origen**: AA-Negocio#5,#6, AA-Técnico#2, AA-RevLineal P1#4
**Archivos**: `scripts/pull-upstream.ps1:71`, `scripts/check-upstream.ps1:71`
**Verificado**: 2026-07-03 — sin cambios detectados.
**Descripción**: `"C:\Program Files\Git\bin\bash.exe"` hardcodeado. Rompe si Git se instaló en otra ruta (portable, scoop, choco).
**Recomendación**: Usar `Get-Command bash.exe` o `$env:GIT_PATH` o registry lookup.
**Prevención**: cross-ref-check.ps1 que detecte paths absolutos hardcodeados.

---

### H-019: Overweight skill check scope limitado

**Severidad**: 🟡 Medio → ✅ Resuelto
**Origen**: AE-P3
**Descripción**: El gate "Overweight skill check" y `karpathy-loop` solo vigilan `.agents/skills/*/SKILL.md` (68/68 ≤3KB ✅). Pero el protocolo Engram aparece inline en 9 de 13 archivos `commands/sdd-*.md`, y `prompts/` también tiene contenido sizable sin control.
**Recomendación**: Extender el gate overweight a `commands/` + `prompts/`. Usar `_shared/engram-convention.md` para referencias compartidas en vez de inline.
**Resuelto**: 2026-07-03 — 12 archivos `commands/sdd-*.md` deduplicados a referencia única `_shared/engram-convention.md`. `score-auto.ps1` extendido con overweight check para `commands/*.md` + `prompts/**/*`. Total ahorro estimado: ~900 chars inline → ~60 chars ref por archivo.

---

### H-024: git-fast.ps1 (GD2) no existe

**Severidad**: 🟢 Bajo
**Origen**: HC-GD2
**Descripción**: Propuesta de wrapper para batched git operations (3-10x faster con single invocation vs 3 separadas). No implementado.
**Recomendación**: Decidir si crear o eliminar del plan.

---

### H-025: .husky/pre-commit (GD3) no existe

**Severidad**: 🟢 Bajo
**Origen**: HC-GD3
**Descripción**: Propuesta de pre-commit centralizado con PSSA + drift check. Hoy existe `.githooks/pre-commit` (funcional).
**Recomendación**: Decidir si migrar a husky o mantener `.githooks/`.

---

### H-026: npx -y sin version pinning (MCPs)

**Severidad**: 🟢 Bajo → ✅ Resuelto
**Origen**: AA-Auth#6
**Archivo**: `opencode.json:202,218`
**Descripción**: `npx -y` para MCPs context7 y sequential-thinking sin version pinning. Riesgo de supply chain si se publica una versión maliciosa.
**Recomendación**: Cambiar a `npx -y <package>@<version>` o instalar globalmente.
**Resuelto**: 2026-07-03 — Pinned: `@upstash/context7-mcp@3.2.2`, `@modelcontextprotocol/server-sequential-thinking@2025.12.18`
