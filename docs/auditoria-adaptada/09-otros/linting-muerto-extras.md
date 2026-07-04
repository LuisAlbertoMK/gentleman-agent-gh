# Otros · Transversal · gentleman-agent-gh

**Auditoria:** Hallazgos no categorizados — sintaxis, codigo muerto, imports huerfanos, extras
**Fecha:** 2026-07-03
**Area:** `scripts/*.ps1`, `.agents/skills/*/SKILL.md`, `commands/*.md`, `prompts/**/*.md`, raiz del repo

---

## Hallazgos

| # | Severidad | Archivo:Linea | Descripcion | Recomendacion |
|---|---|---|---|---|
| 1 | Alta | `scripts\dev-server.ps1:1` | `#requires -Version 7.0` — el estandar del repo es 7.6. Solo `setup-machine.ps1` comparte 7.0, los otros 53 scripts usan 7.6 | Unificar a `#requires -Version 7.6` o documentar por que 7.0 es suficiente |
| 2 | Alta | `scripts\setup-machine.ps1:1` | Misma inconsistencia que #1: `#requires -Version 7.0` vs 7.6 del resto | Unificar a 7.6 o agregar comentario de version minima requerida |
| 3 | Alta | `scripts\backup.ps1:1,13`, `bench-file-io.ps1:1,16`, `ensure-tools.ps1:1,13`, `restore.ps1:1,15`, `score-auto.ps1:1,9`, `skill-test-suite.ps1:1,11`, `token-count.ps1:1,15`, `tokenize-all.ps1:1,16` | `#requires -Version 7.6` duplicado en 8 scripts (2 instancias cada uno). Sin efecto funcional (PS usa la primera), pero es ruido de linting | Eliminar la segunda instancia de `#requires -Version 7.6` en cada archivo |
| 4 | Media | `scripts\lib\JsonFast.psm1:4-11` | La funcion `ConvertTo-JsonFast` se exporta con `Export-ModuleMember` pero **nunca es llamada** por ningun script del repo. El modulo solo es cargado por `smoke-jsonfast.ps1` para tests internos, y listado en `smoke-all.ps1` | Considerar eliminar `JsonFast.psm1` si no hay consumo real, o agregar un consumidor |
| 5 | Media | `commands\sdd-continue.md` | Comando huerfano: **cero referencias** en `SKILLS-INDEX.md`, `AGENTS.md`, `opencode.json`. No tiene prompt equivalente en `prompts/sdd/` | Eliminar o documentar su proposito y agregar referencias cruzadas |
| 6 | Media | `commands\sdd-ff.md` | Comando huerfano: mismo caso que #5. Sin referencias en ningun archivo de indice o config | Idem #5 |
| 7 | Media | `commands\sdd-new.md` | Comando huerfano: mismo caso que #5 y #6. Sin referencias | Idem #5 |
| 8 | Media | `prompts\sdd\sdd-orchestrator.md` | Prompt sin comando counterpart. Referenciado solo en `opencode.json` linea 147 como prompt del agente `sdd-orchestrator`. No existe `commands/sdd-orchestrator.md` | Evaluar si necesita un command stub o renombrar comandos existentes |
| 9 | Media | `scripts\bash-safe.ps1:51-56` | El parametro `-Command` es `[Parameter(Mandatory, Position=0)]` pero no tiene `.PARAMETER` en el bloque de ayuda (`<# ... #>` lineas 3-28). Solo tiene `.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`, `.NOTES` | Agregar `.PARAMETER Command` y `.PARAMETER CaptureOutput` al help |
| 10 | Media | `.githooks\pre-commit` | Git hooks (`pre-commit`, `post-commit`) configurados via `core.hooksPath` en `.git/config`, pero **no documentados** en ningun archivo raiz (`README.md`, `AGENTS.md`, `CYCLE.md`, etc.) | Agregar seccion en `README.md` o `AGENTS.md` documentando los hooks y como desactivarlos (`--no-verify`) |
| 11 | Baja | `scripts\ps5-detect.ps1:1` | `#requires -Version 5.1` — es intencional (detecta `&&`/`||` en scripts para compatibilidad PS5), pero es el unico script con version 5.1. Todos los demas scripts requieren 7+ | Agregar comentario explicito: `# PS5-only detector — must NOT require 7+` |
| 12 | Baja | `.agents\skills\sdd-*` | Duality SDD: existen 10 skills individuales (`sdd-apply`, `sdd-archive`, etc.) CADA UNO con su propio `SKILL.md`, que duplica contenido de `sdd/phases/` (08-archive.md, etc.). No son symlinks ni junctions — archivos reales separados | Unificar: convertir skills individuales en symlinks/junctions a `sdd/phases/`, o eliminar los que sobran |
| 13 | Baja | `skills-lock.json` | `skills-lock.json` referencia 5 skills del source `addyosmani/web-quality-skills` con hashes. No hay un mecanismo periodico que verifique integridad contra esos hashes | Agregar check en `verify.ps1` o script CI que valide hashes vs disco |
| 14 | Baja | `SKILLS-INDEX.md:48,68` | Dos skills tienen anotacion `(merged)` en el INDEX: `skill-improver (merged)` y `performance (merged)`. Esto puede confundir parsers automatizados que esperen nombres exactos de directorio | Normalizar: en el INDEX usar nombre canonico `skill-improver` y `performance`, y mover la nota de merge al changelog |

---

## Resumen

| Tipo | Total |
|---|---|
| **Total hallazgos** | 14 |
| Criticos | 0 |
| Altos | 3 |
| Medios | 7 |
| Bajos | 4 |

### Distribucion por area

| Area | Hallazgos |
|---|---|
| `scripts/*.ps1` (linting/sintaxis) | #1, #2, #3, #9, #11 |
| `scripts/lib/` (codigo muerto) | #4 |
| `commands/*.md` (huerfanos) | #5, #6, #7 |
| `prompts/sdd/*.md` (asimetria) | #8 |
| `.githooks/` (documentacion) | #10 |
| `.agents/skills/` (estructura) | #12 |
| Raiz del repo (config) | #13, #14 |

### Notas

- El proyecto esta **muy bien mantenido**: 0 criticos, score general 10.0 segun `.project.json`.
- Los hallazgos altos (#1-#3) son cosmeticos (inconsistencias de version) o ruido (duplicados).
- Los hallazgos medios (#5-#8) indican **comandos huerfanos** que deberian podarse o documentarse.
- `JsonFast.psm1` (#4) es el unico modulo de script que parece no tener consumidor real fuera de testing.
- No se detectaron errores de sintaxis PowerShell, llamadas a cmdlets inexistentes, ni modulos importados sin uso.
- No hay `Import-Module` dispersos (solo 1 en todo el repo: `smoke-jsonfast.ps1` carga `JsonFast.psm1`).
