# Revisión Lineal · Consistencia Global · gentleman-agent-gh
Fecha: 2026-07-03

## Hallazgos

| # | Severidad | Archivo | Descripción | Recomendación |
|---|---|---|---|---|
| 1 | 🔴 Crítico | `AGENTS.md` (L112) | **Skill name mismatch**: referencia `gentle-ai-chained-pr`, `gentle-ai-branch-pr`, `gentle-ai-issue-creation`. Las skills reales se llaman `chained-pr`, `branch-pr`, `issue-creation`. | Renombrar referencias en AGENTS.md a los nombres reales de las skills. |
| 2 | 🔴 Crítico | `AGENTS.md` (L112) | **Skill name mismatch**: referencia `a11y`. La skill real se llama `accessibility`. | Cambiar la referencia a `accessibility` o agregar alias. |
| 3 | 🔴 Crítico | `AGENTS.md` (L112) | **Skill name mismatch**: referencia `model-router`. La skill real se llama `opencode-model-router`. | Corregir referencia al nombre exacto de la skill. |
| 4 | 🔴 Crítico | `docs/hallazgos-completos.md` | **Referencia a scripts inexistentes**: menciona `git-fast.ps1`, `measure-ps.ps1`, `memory-tune.ps1`, `skill-auto-generator.ps1`, `vmk-safety-check.ps1`. Ninguno existe en `scripts/`. | Eliminar referencias o crear los scripts si son necesarios. |
| 5 | 🔴 Crítico | `docs/auditoria-adaptada/01-gaps/funcional.md`, `negocio.md` | **Ruta incorrecta** a `scripts/smoke-all.ps1`: el archivo real está en `scripts/smoke/smoke-all.ps1`, no en la raíz de scripts/. | Corregir ruta a `scripts/smoke/smoke-all.ps1` en ambos archivos. |
| 6 | 🟠 Alto | `scripts/dev-server.ps1` | **Sin `Set-StrictMode` ni `$ErrorActionPreference`**: es el único script del proyecto que carece de ambos. Riesgo de errores silenciosos. | Agregar `Set-StrictMode -Version Latest` y `$ErrorActionPreference = 'Stop'`. |
| 7 | 🟠 Alto | `scripts/backup.ps1`, `scripts/ponytail-audit.ps1`, `scripts/score-auto.ps1`, `scripts/trend.ps1` | **Falta `$ErrorActionPreference = 'Stop'`**: 4 scripts no declaran `$ErrorActionPreference`. | Agregar `$ErrorActionPreference = 'Stop'` al inicio. |
| 8 | 🟠 Alto | `scripts/install.ps1`, `scripts/setup-machine.ps1`, `scripts/dev-server.ps1` | **Falta `Set-StrictMode`**: 3 scripts no usan `Set-StrictMode -Version Latest`. | Agregar `Set-StrictMode -Version Latest` después del `#requires`. |
| 9 | 🟠 Alto | Múltiples scripts (20 de 55) | **BOM inconsistente**: 35 scripts con BOM (UTF-8 with BOM), 20 sin BOM (UTF-8 no BOM). Las skills .md y root .md usan UTF-8 sin BOM. | Estandarizar a UTF-8 sin BOM (como recomienda `pssa-gate.ps1`). |
| 10 | 🟠 Alto | `scripts/trend.ps1`, `scripts/intake-verify.ps1`, `scripts/benchmark.ps1`, `scripts/smoke-jsonfast.ps1` | **Funciones sin nombre Verb-Noun**: `TA`, `D`, `FI`, `FP`, `FB` (trend.ps1), `wr`, `sz`, `ic` (intake-verify.ps1), `dump` (benchmark.ps1), `Check` (smoke-jsonfast.ps1). | Renombrar funciones con el patrón `Verb-Noun` estándar de PowerShell. |
| 11 | 🟡 Medio | `scripts/` (múltiples archivos) | **Parámetros con nombres de una letra**: `N`, `M`, `J`, `s`, `f`, `x`, `d`, `p`, `D`, `e`, `a`, `_`. 11 scripts usan parámetros de una sola letra. | Usar nombres descriptivos PascalCase para parámetros. |
| 12 | 🟡 Medio | `.agents/skills/sdd/` + `.agents/skills/sdd-*/` | **Solapamiento estructural SDD**: existe un skill monolítico `sdd/` Y 10 skills individuales `sdd-*`. SKILLS-INDEX.md documenta ambos. | Decidir si consolidar (eliminar `sdd/` si las individuales lo cubren) o mantener ambas documentando la relación. |
| 13 | 🟡 Medio | `commands/` vs `prompts/sdd/` | **Asimetría commands/prompts**: `sdd-continue.md`, `sdd-ff.md`, `sdd-new.md` existen solo en commands/. `sdd-orchestrator.md` existe solo en prompts/sdd/. | Sincronizar: todo command debe tener su prompt correspondiente y viceversa. |
| 14 | 🟡 Medio | 9 scripts | **`#requires` duplicado**: backup.ps1, bench-file-io.ps1, ensure-tools.ps1, pssa-gate.ps1, restore.ps1, score-auto.ps1, skill-test-suite.ps1, token-count.ps1, tokenize-all.ps1 tienen 2 líneas `#requires`. | Eliminar la línea duplicada. |
| 15 | 🟡 Medio | Múltiples scripts | **`#requires` con versiones mixtas**: `ps5-detect.ps1` requiere 5.1; `setup-machine.ps1`, `dev-server.ps1` requieren 7.0; el resto 7.6. No hay criterio claro. | Documentar política de versiones o unificar a 7.6 (mínimo soportado). |
| 16 | 🟡 Medio | `docs/hallazgos-completos.md` | **Referencia a skill `karpathy-prompt`**: menciona `karpathy-prompt` (skill renombrada a `karpathy-loop`). | Actualizar referencia al nombre actual. |
| 17 | 🟡 Medio | `scripts/benchmark.ps1` | **Estilo de ayuda comprimido**: usa `<#.SYNOPSIS ... #>` en una sola línea, diferente al resto que usa bloque `<# ... #>` con `.SYNOPSIS` en línea aparte. | Unificar formato de ayuda al estándar del proyecto. |
| 18 | 🟡 Medio | `AGENTS.md` (L60) | **Alias inconsistente**: `!extimprove` como shortcut para la skill `external-improvement` omite el guion. | Documentar que `extimprove` es alias, no el nombre de la skill. |
| 19 | 🟢 Bajo | `.githooks/pre-commit`, `.githooks/post-commit` | **Git hooks no documentados**: existen hooks de pre-commit y post-commit que corren quality gate y sync global, pero no se mencionan en AGENTS.md ni README. | Documentar los hooks y cómo activarlos (`git config core.hooksPath .githooks`). |
| 20 | 🟢 Bajo | `.learnings/` | **`.gitignore` vs tracking real**: `.gitignore` tiene `/learnings/` pero el directorio está siendo trackeado. | Decidir: si debe trackearse, quitar de .gitignore; si no, `git rm --cached`. |
| 21 | 🟢 Bajo | `scripts/check-mcp-security.ps1`, `scripts/test-downstream.ps1` | **Scripts huérfanos**: no son referenciados en ningún .md del repositorio. | Documentarlos en README/AGENTS.md o moverlos a archive/. |
| 22 | 🟢 Bajo | `docs/auditoria-adaptada/09-otros/` | **Directorio vacío**: `09-otros/` no contiene archivos. | Eliminar o poblar con contenido. |
| 23 | 🟢 Bajo | `errors/.gitkeep` | **Archivo `.gitkeep` placeholder**: en un directorio que nunca se usa. | Evaluar si el directorio `errors/` es necesario. |
| 24 | 🟢 Bajo | `skills/` (root) | **Directorio espejo redundante**: `skills/` en raíz es un mirror de `.agents/skills/`. Documentado como junctions git-ignored, pero no se verifica que realmente lo sean. | Agregar verificación en scripts/setup-machine.ps1. |

## Resumen
| Métrica | Total |
|---------|-------|
| **Total hallazgos** | 24 |
| 🔴 Críticos | 5 |
| 🟠 Altos | 5 |
| 🟡 Medios | 8 |
| 🟢 Bajos | 6 |

### Distribución por categoría
| Categoría | Hallazgos | Cantidad |
|-----------|-----------|----------|
| Convenciones de nomenclatura | #10, #11, #18 | 3 |
| Estructura de carpetas | #12, #13, #22, #24 | 4 |
| Estilo de código | #6, #7, #8, #9, #14, #15, #17 | 7 |
| Consistencia cross-file | #6-#9, #14-#15, #17 | 6 |
| Referencias cruzadas | #1-#5, #16, #19, #20, #21 | 8 |

### Notas
- **Fortaleza**: 55/56 scripts tienen ayuda documentada (`.SYNOPSIS`). 56/56 tienen `#requires`. Convención kebab-case consistente en scripts y skills.
- **Debilidad principal**: nombres de skills incorrectos en `AGENTS.md` (3 referencias desactualizadas + 2 alias incorrectos). Esto afecta al routing del agente directo.
- **Deuda técnica**: BOM inconsistente (35/55 scripts con BOM) y funciones no-Verb-Noun en varios scripts que podrían fallar PSScriptAnalyzer.
- **SDD duplicado**: la coexistencia de `sdd/` monolítico + `sdd-*` individuales es confusa y requiere decisión arquitectónica.
