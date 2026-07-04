# GAPS · Funcional · gentleman-agent-gh

**Fecha**: 2026-07-03
**Auditor**: Análisis estático — comparación entre documentación, código fuente y skills registrados.
**Metodología**: Glob + Grep + Read sobre todos los archivos del repo. Verificación cruzada entre README, AGENTS.md, CYCLE.md, SKILLS-INDEX.md, \.project.json\ y el estado real del sistema de archivos.

---

## Hallazgos

| # | Severidad | Archivo(s) | Descripción | Recomendación |
|---|---|---|---|---|
| 1 | 🟠 Alto | \.agents/skills/\ (no existe), \CYCLE.md\ (L185) | **\capture-learnings\ skill faltante.** CYCLE.md Cycle 11 Item 11 (L185) declara "capture-learnings SKILL.md created (delegates to session-miner.ps1)" como ✅ Done. Pero el directorio \.agents/skills/capture-learnings/\ NO existe. Tampoco hay SKILL.md en ninguna otra ubicación. La funcionalidad fue documentada como implementada pero nunca se materializó (o se perdió). | Crear el skill \capture-learnings/SKILL.md\ con frontmatter YAML, triggers, y delegación documentada a \session-miner.ps1\. O eliminar la referencia de CYCLE.md si se descartó. |
| 2 | 🟠 Alto | \.agents/skills/chained-pr/SKILL.md\ (L2), \CYCLE.md\ (L170, L184) | **\chained-pr\ metadata name mismatch — fix declarado pero no aplicado.** CYCLE.md Cycle 11 Item 10 declara "Fix chained-pr metadata name mismatch (gentle-ai-chained-pr→chained-pr)" como ✅ Done (L184). Sin embargo, \chained-pr/SKILL.md\ L2 sigue teniendo \
ame: gentle-ai-chained-pr\. El fix fue revertido o nunca se aplicó realmente. | Sincronizar \
ame:\ en el frontmatter de \chained-pr/SKILL.md\ con el nombre del directorio (\chained-pr\). Verificar si \ranch-pr/SKILL.md\ y \issue-creation/SKILL.md\ necesitan el mismo cambio (actualmente \gentle-ai-branch-pr\, \gentle-ai-issue-creation\). |
| 3 | 🟠 Alto | \.agents/skills/branch-pr/SKILL.md\, \.agents/skills/issue-creation/SKILL.md\, \AGENTS.md\ (L112) | **Skills \ranch-pr\, \issue-creation\, \chained-pr\ diseñados para upstream \gentle-ai\, no para este repo.** Sus SKILL.md referencian \Gentleman-Programming/gentle-ai\, \GGa issues\, y tienen names \gentle-ai-*\. AGENTS.md (L112) los lista en el router como \gentle-ai-branch-pr\, \gentle-ai-chained-pr\, \gentle-ai-issue-creation\. Un usuario de gentleman-agent-gh que invoque \ranch-pr\ recibirá instrucciones para el proyecto equivocado. | Fork/adaptar estos skills para gentleman-agent-gh, o crear wrappers que redirijan al skill upstream correspondiente. O documentar explícitamente que son upstream re-exportados. |
| 4 | 🟡 Medio | \docs/ciclos/\ (ausente), \CYCLE.md\ | **Falta reporte de Cycle 10.** CYCLE.md documenta Cycle 10 como completado (16/18 items, score 10/10, inter 105/30). Sin embargo, no existe \docs/ciclos/cycle10-*.md\. Los ciclos 11-17 tienen reportes; el 10 no. | Generar reporte retrospectivo de Cycle 10, o al menos un placeholder explicando por qué no se generó. |
| 5 | 🟡 Medio | \docs/ciclos/README.md\ (L78-80) | **\docs/ciclos/README.md\ solo lista Cycle 11.** El índice de reportes de ciclo muestra únicamente "Cycle 11 \| 2026-06-25". Faltan los ciclos 10, 12, 13, 14, 15, 16 y 17 que sí tienen reportes en el mismo directorio. | Actualizar la tabla de reportes para incluir todos los ciclos del 10 al 17, con fechas y estados reales. |
| 6 | 🟡 Medio | \docs/metricas/SUMMARY.md\ (L13, L18) | **Métricas desactualizadas.** SUMMARY.md reporta "Scripts: 42" cuando el conteo real es 48 \.ps1\. La fecha del benchmark dice "2026-06-26" pero es 2026-07-03. | Actualizar SUMMARY.md con los valores actuales (48 scripts, fecha correcta). |
| 7 | 🟡 Medio | \docs/operations/scoring-protocol.md\ (L9) | **Confusión 9 vs 13 dimensiones.** El protocolo dice "This protocol covers 9 core dimensions. The current scoring system (\score-auto.ps1\) measures 13" — es contradictorio. Si el sistema mide 13, el protocolo debería cubrir 13. | Reescribir el párrafo introductorio para reflejar que el protocolo cubre las 13 dimensiones actuales, o separar claramente core vs total. |
| 8 | 🟡 Medio | \PLAN-OPTIMIZACION-GENTLEMAN.md\ (L3), \README.md\ (L3), \SKILLS-INDEX.md\ (L3), \.project.json\ | **Inconsistencia menor en conteo de skills.** \PLAN-OPTIMIZACION-GENTLEMAN.md\ L3 dice "69 skills". README dice "68 skills (+ _shared)" = 69 total. \.project.json\ dice 68 (excluye _shared). La inconsistencia está en que \PLAN...md\ cuenta _shared como skill mientras los demás lo separan. | Estandarizar: o todos cuentan 68+_shared o todos cuentan 69. Recomendación: mantener 68+_shared (es más preciso). |
| 9 | 🟢 Bajo | \README.md\ (L117-141) | **Tabla de scripts incompleta.** README documenta solo 22 scripts en la tabla, pero hay 48 \.ps1\ en \scripts/\. Faltan 27 scripts: \uto-clean.ps1\, \ackup.ps1\, \ash-safe.ps1\, \ench-compare.ps1\, \ench-file-io.ps1\, \ootstrap.ps1\, \capture-errors.ps1\, \check-mcp-security.ps1\, \dev-server.ps1\, \xtract-skill.ps1\, \intake-debug.ps1\, \intake-verify.ps1\, \list-skills.ps1\, \optimize-system.ps1\, \ponytail-audit.ps1\, \project-cycle.ps1\, \project-profile.ps1\, \ps5-detect.ps1\, \pull-upstream.ps1\, \estore.ps1\, \un-improvement-cycle.ps1\, \setup-machine.ps1\, \skill-test-suite.ps1\, \skillspector-gate.ps1\, \sync-global.ps1\, \	est-downstream.ps1\, \	okenize-all.ps1\. | Agregar los scripts faltantes a la tabla de README, o al menos agruparlos por categoría para no alargar excesivamente la tabla. |
| 10 | 🟢 Bajo | \PROJECT-SCORE.md\ (L10) | **Encoding corruption.** La línea 10 contiene caracteres mojibake (acentos no UTF-8). | Re-guardar el archivo en UTF-8 sin BOM. |
| 11 | 🟢 Bajo | \docs/operations/agent-capabilities.md\ | **Encoding corruption general.** Múltiples caracteres mojibake: em dash roto, vocales acentuadas corruptas, etc. | Re-guardar en UTF-8 sin BOM. Verificar que el editor no convierta a Latin-1. |
| 12 | 🟢 Bajo | \README.md\ (L137) | **Path incorrecto a smoke-all.ps1.** README referencia \smoke/smoke-all.ps1\ (ruta relativa a scripts/), pero el archivo real es \scripts/smoke-all.ps1\ (está en la raíz de scripts/, no en subdirectorio \smoke/\). Existe \scripts/smoke/\ con tests individuales pero no contiene \smoke-all.ps1\. | Corregir la ruta en README a \smoke-all.ps1\ o mover \smoke-all.ps1\ a \smoke/\ y actualizar. |
| 13 | 🟢 Bajo | \scripts/check-mcp-security.ps1\, \scripts/test-downstream.ps1\ | **Scripts huérfanos sin documentación.** Dos scripts existen en \scripts/\ pero no son referenciados en ningún \.md\ del repo: \check-mcp-security.ps1\ (auditoría de seguridad MCP, 320 líneas) y \	est-downstream.ps1\ (validación downstream de skills CYCLE-3). Nadie sabe que existen ni cómo usarlos. | Documentarlos en README o AGENTS.md, o moverlos a \scripts/archive/\ si están obsoletos. |

---

## Resumen

| Tipo | Cantidad |
|------|:--------:|
| 🔴 Crítico | 0 |
| 🟠 Alto | 3 |
| 🟡 Medio | 5 |
| 🟢 Bajo | 5 |
| **Total** | **13** |

### Distribución por categoría

| Categoría | # Hallazgos |
|-----------|:-----------:|
| Skills faltantes / no implementados | 1 (#1) |
| Fixes documentados que no persisten | 1 (#2) |
| Skills upstream mezclados con locales | 1 (#3) |
| Documentación faltante (ciclos, métricas) | 2 (#4, #6) |
| Documentación desactualizada / inconsistente | 4 (#5, #7, #8, #9) |
| Encoding corruption | 2 (#10, #11) |
| Paths incorrectos en docs | 1 (#12) |
| Scripts huérfanos sin documentar | 1 (#13) |

### Notas

- **Hallazgo #2** es particularmente preocupante porque indica que el pipeline de verificación (triple verify + quality gate) no detectó que un fix documentado como "Done" no estaba realmente aplicado. Esto sugiere un gap en el proceso de verificación mismo.
- **Hallazgo #3** es un problema de diseño: 3 skills que deberían ser genéricos o adaptados al proyecto actual están fuertemente acoplados al upstream \gentle-ai\. Esto puede confundir a nuevos contribuidores.
- **Hallazgo #10 y #11** indican que algunos archivos markdown perdieron su encoding UTF-8 en algún momento, probablemente por un save con encoding incorrecto.
