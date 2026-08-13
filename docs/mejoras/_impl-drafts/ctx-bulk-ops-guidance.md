# ctx-bulk-ops-guidance (P2.15 — draft, NOT applied)

**Fuente**: plan-kimi-k3 §3 P2.15 — "Bulk-ops vía ctx_execute: forzar en prompts que listings/greps masivos pasen por sandbox, no a contexto."

## Regla
Toda operación bulk (listings recursivos, greps de repo, escaneos de directorios, conteos) DEBE ejecutarse envuelta en `ctx_batch_execute` (o `ctx_execute`) y devolver solo el derivado (agregados, conteos, filas filtradas), NUNCA el raw al contexto.

## Candidatos obligatorios (con cita)

| Operación | Cita | Por qué |
|---|---|---|
| Escaneo de skills para benchmark | `scripts/benchmark.ps1:40` — `Get-ChildItem $cd -Directory ... PSForEach({...SKILL.md...})` recorre TODAS las skills y lee cada SKILL.md raw | O(n) bytes crudos por ciclo benchmark |
| Resolución sparse de skills | `.agents/skills/skill-graph/SKILL.md` (sección `## RESOLVE` — BFS sobre registro de skills) | BFS keyed por task-hash; hoy recorre el grafo completo sin cache |
| Greps/listings masivos en análisis | skills `analysis-mode`/`research` (fases de barrido) | contenido externo/raw no debe entrar a contexto |
| Cualquier `Get-ChildItem -Recurse` + `Get-Content` en scripts de reporte | patrón en `scripts/*.ps1` (benchmark, check-skill-drift) | idem |

## Contrato de uso
1. `ctx_batch_execute(commands=[...], queries=[...])` para gather-and-query en un round-trip.
2. Procesamiento con `ctx_execute(language, code)` — solo `console.log()` del derivado.
3. Archivos grandes → `ctx_execute_file` (raw queda en sandbox).
4. Si la operación genera >~5KB, pasar `intent` para auto-indexar y recuperar por tópico.

## Estado
- [ ] Revisado por humano
- [ ] Prompts canonicalizados con la regla (analysis-mode/research)
- [ ] Scripts benchmark/skill-graph alineados
