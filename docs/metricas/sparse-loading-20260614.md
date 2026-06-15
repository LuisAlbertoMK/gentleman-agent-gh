# Sparse Loading — Metricas

> Ronda: 2026-06-14
> Impacto: Sistema de resolución de skills por dependencias

## Before

- Sistema carga todos los 54 skills disponibles en el listado `available_skills`
- SKILLS-INDEX.md contiene tabla completa de triggers (92L)
- session-resume hace recall genérico vía `mem_search` sin pre-loading de skills
- Sin mecanismo para determinar qué skills son relevantes para una tarea específica

## After

- `scripts/skill-graph.ps1` — resolvedor basado en grafo de dependencias (55 skills, 10 categorías)
- `skill-graph` skill — sparse loading: 55 skills → 4-8 típicamente (−85-92%)
- `session-resume` v2 — integra skill-graph para pre-loading contextual
- SKILLS-INDEX.md v2.0 — categorías de dependencia añadidas

## Métricas

| Dimensión | Before | After | Δ |
|-----------|--------|-------|---|
| Skills en contexto | 55 | 4-8 | −85-92% tokens de skill |
| Tiempo de resolución | N/A (manual) | ~50ms (script) | Automatizado |
| Precisión de matching | Manual (leer SKILLS-INDEX) | Algorítmica (trigger BFS) | +sistemática |
| Dependencias visibles | 0 (ocultas) | 1-hop expandido | +visibilidad |

## Verificación

```
Task: "security audit" → matched: 3 (security-scanner, gap-analysis, skill-improver)
                         expanded: 1 (project-mapper vía gap-analysis)
                         total: 4 (−93% vs 55)

Task: "performance, optimize" → matched: 3 (performance-tracker, karpathy-loop, prompt-engineering)
                                expanded: 0
                                total: 3 (−95% vs 55)

Task: "resume session" → matched: 2 (session-resume, code-memory)
                         expanded: 2 (dreaming vía session-resume, auto-metrics vía dreaming)
                         total: 4 (−93% vs 55)
```

## Próximos pasos
- Integrar skill-graph en el router automático de AGENTS.md
- Añadir cache de resolución (evitar re-ejecutar script para mismas keywords)
- Expandir registry con edge weights para ranking de relevancia
