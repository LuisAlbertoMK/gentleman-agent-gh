# Skill Ecosystem Audit — gentleman-agent-gh (2026-07-31)

> **Trigger**: `!analisis` — validar hallazgos de uso real de skills (6 sin uso, 4 refs colgadas, runtime roto, clusters de redundancia) antes de actuar.
> **Método**: Análisis de `opencode.db` (716 sessions, SQL directo) + 4 subagentes validadores read-only en paralelo + prueba en vivo del tool `skill`.
> **Gate**: Solo análisis y plan — sin cambios de código.

## Summary

Los hallazgos originales se **confirman con matices**: 3 de 6 skills sin uso son realmente muertas (no 6), las 4 refs colgadas se mapean a sucesores (2 con refs STALE vivas por corregir), el runtime del tool `skill` está **roto por misconfiguración** (causa raíz encontrada: plugin `opencode-lazy-loader` escanea `skill/` singular vs `skills/` plural) y solo 1 cluster de redundancia es solape real + 1 colisión de triggers.

## Findings (8 dims)

| Dim | Estado | Hallazgo |
|-----|--------|----------|
| Arch | ✅ CORREGIDO | Runtime roto NO es diseño: plugin sombrea al tool nativo y escanea `skill/` (singular) mientras los skills viven en `skills/` (plural) → `loadedSkills=[]` → error exacto "Available skills: none". Fallback por-Read documentado en 3 capas (SKILLS-INDEX:49-53, analysis-mode:12, registry delegator) |
| Arch | ⚠️ CONFIG MALFORMADA | `skills.paths: [".agents/skills/*"]` — el core opencode exige dir real sin glob; `/*` falla el check `isDir` |
| DX | ⚠️ 3 refs STALE | `skill-creator` sigue en self-improvement/SKILL.md:17-18, docs/ARCHITECTURE.md:87, docs/cross-project/PLAN.md:53, opencode-skill-creator/references/schemas.md:3 (deleted `1c477dd3` 07-18) |
| DX | 🟡 3 skills muertas | cognitive-doc-design (45d, 0 loads), prompt-engineering (48d, solapa karpathy-loop), senior-engineer (48d, redundante con la persona del AGENTS.md) |
| DX | 🟢 3 justificadas | external-improvement (31d, triggers ultra-específicos), vision-analyze (18d, depende de Ollama local), comment-writer (niche, sin wiring) |
| DX | ⚠️ Colisión triggers | `metricas` vs `auto-metrics` ambos responden a `!metrics`/`Metricas` |
| Data | ✅ Validado | 724 lecturas de SKILL.md / 716 sessions; 89 de 90 skills cargadas ≥1 vez; drift de conteo AGENTS.md "79" vs 81 reales |
| Biz | 🟢 | 81 skills canónicas; solo ~7 acciones accionables; ecosistema sano |

## Synthesis

| Finding | Consensus | Riesgo | Files | Recomendación |
|---------|-----------|--------|-------|---------------|
| Runtime skill tool roto (plugin lazy-loader `skill/` vs `skills/`) | UNANIMOUS | ALTO | plugin `opencode-lazy-loader` dist/skill-loader.js + skill.js:138 | Corregir path del plugin o reconfigurar; habilitar tool nativo |
| `skills.paths` con glob inválido | UNANIMOUS | MEDIO | opencode.json (proyecto + global) | Cambiar `".agents/skills/*"` → `".agents/skills"` |
| skill-creator: 3 refs STALE vivas | UNANIMOUS | MEDIO | self-improvement:17-18, ARCHITECTURE:87, PLAN:53, schemas.md:3 | Renombrar a opencode-skill-creator |
| 3 skills muertas (doc-design, prompt-eng, senior-eng) | MAJORITY | BAJO | .agents/skills/{3} | Archivar o merge (prompt-eng → karpathy-loop) |
| vision-analyze vs visual-testing solapan | MAJORITY | BAJO | .agents/skills/{2} | Documentar diferenciación (LLM-local vs diff) |
| metricas vs auto-metrics colisión !metrics | MAJORITY | BAJO | .agents/skills/{2} | Disambiguar triggers |
| external-improvement 0 uso | SPLIT | BAJO | .agents/skills/external-improvement | Dejar ventana de uso; decidir en 30d |
| Drift AGENTS.md "79 skills" | UNANIMOUS | BAJO | AGENTS.md | Actualizar a 81 |

## Risk Matrix

| Severidad | Items |
|-----------|-------|
| 🟥 ALTO | Runtime skill tool roto (1) — mitigado de facto por fallback Read, pero todo intento oficial falla silenciosamente |
| 🟧 MEDIO | Refs STALE skill-creator (3 archivos) · skills.paths glob (2 configs) |
| 🟨 BAJO | 3 skills muertas · colisión !metrics · drift conteo |

## Recommendations (plan — sin ejecutar)

1. **P0 — Habilitar runtime**: corregir `opencode-lazy-loader` (paths `skill` → `skills`) o desinstalar el sombra y dejar el tool nativo (que sí resuelve: available_skills lista 91 globales). Verificar con `skill(name="analysis-mode")` → debe cargar.
2. **P0 — Config**: `skills.paths: [".agents/skills"]` en opencode.json (proyecto + global).
3. **P1 — Refactor STALE**: 3 archivos apuntan a `skill-creator` → `opencode-skill-creator`.
4. **P1 — Archivar**: cognitive-doc-design, prompt-engineering (merge karpathy-loop), senior-engineer. Mover a `.agents/skills/_archived/` (patrón existente).
5. **P2 — Documentar**: vision-analyze vs visual-testing; triggers metricas/auto-metrics disambiguados.
6. **P2 — Docs**: AGENTS.md 79→81; verificar tras cleanup con `cross-ref-check.ps1` (allClean) y `!score`.

## Engram Persistence

- Obs: `analysis:gentleman-agent-gh:2026-07-31` (architecture)
- topic_key: `analysis/gentleman-agent-gh`

## Trend vs Previous

Previo: `#2014` (analysis:gentleman-agent-gh:2026-07-29, Cycle 28). Delta:
- **Nuevo**: causa raíz del runtime roto (misconfig lazy-loader) — antes se asumía fallback por diseño.
- **Regresión**: refs STALE de skill-creator reintroducidas por cleanup incompleto del 07-18 (delete+replace sin actualizar refs).
- **Mejora**: SKILLS-INDEX v5.1 ya limpio (zombie analysis-executor corregido; changelog 93→81).
- **Stale**: hallazgo "Skill Effectiveness 10/10" (score-dims) no contempla uso real — este análisis aporta la métrica faltante.
