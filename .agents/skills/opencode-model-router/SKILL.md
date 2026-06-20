---
name: opencode-model-router
description: "Route tasks by model strength — delegated vs direct handling, with security gates and fallback chains"
triggers: "model router, routing, qué modelo, qué hacer con esta tarea, delegate or direct, model decision, trial risk, security gate"
license: Apache-2.0
metadata:
  tags: [engineering, routing, orchestration]
  author: gentleman-vMK + Big Pickle
  version: "1.0"
  changelog: "1.0: decision tree from free-specialities v3+v3(1) cross-analysis"
---

# opencode-model-router

Decision tree para que Big Pickle (agente primario) decida **cuándo delegar, cuándo manejar directo, y qué skills cargar** según el tipo de tarea, el tamaño de contexto, y el nivel de riesgo del modelo disponible.

> **Origen**: Análisis cruzado de `opencode-free-specialities-v3.md` + `v3(1).md`
> Ver `MODEL-ROUTER-VERDICT.md` para el análisis completo

---

## ⚠️ SECURITY GATE (ejecutar SIEMPRE primero)

Antes de cualquier routing, verificar:

```
1. ¿La tarea involucra credenciales, secrets, tokens, datos personales o PII?
   → SÍ: MANEJO DIRECTO. NUNCA delegar a trial models.
   → NO: continuar.

2. ¿Es una tarea recurrente (cron, CI/CD, workflow automatizado)?
   → SÍ: MANEJO DIRECTO. Trial models pueden desaparecer sin aviso.
   → NO: continuar.

3. ¿El contexto actual supera 150K tokens?
   → SÍ: MANEJO DIRECTO. Solo Big Pickle maneja >150K establemente.
   → NO: continuar al routing.
```

Si cualquiera de los 3 gates se activa → cargar skill según tipo de tarea y manejar directo.

---

## Routing Table

| Tipo tarea | Acción 🥇 | Fallback 🥈 | Skill a cargar |
|---|---|---|---|
| **UI/UX • CSS • Tailwind** | Delegar a subagente (syntax-preferred) | Manejo directo | `baseline-ui` |
| **React • Frontend (<100K ctx)** | Delegar a subagente | Manejo directo | `baseline-ui` |
| **E2E Testing (Playwright/Cypress)** | Delegar a subagente (async-preferred) | Manejo directo | según stack (`go-testing`, `python-async`) |
| **Performance • Core Web Vitals** | Delegar a subagente | Manejo directo | `performance`, `core-web-vitals` |
| **Syntax • Linting • Code Quality** | Delegar a subagente | Manejo directo | `code-review-agent` |
| **SEO • Content • Metadata** | Delegar a subagente (multimodal si posible) | Manejo directo | `seo` |
| **🏆 Architecture • Best Practices** | MANEJO DIRECTO | — | `senior-engineer` |
| **🏆 Codebase Audit (>150K)** | MANEJO DIRECTO | — | `project-mapper`, `gap-analysis` |
| **🏆 Code Review** | MANEJO DIRECTO | — | `code-review-agent` |
| **🏆 Full Feature Set** | MANEJO DIRECTO | — | `sdd-*` pipeline |
| **🏆 Recurrentes / Cron** | MANEJO DIRECTO | — | según tarea |
| **Default (sin match)** | MANEJO DIRECTO | — | `skill-graph` → resolver |

---

## Cómo delegar (acción "Delegar a subagente")

```pseudocode
DELEGATE(subagent, prompt)
  → Si el subagente responde OK → integrar resultado
  → Si el subagente falla (timeout/error) → MANEJO DIRECTO con skill
  → Si el resultado es parcial/incompleto → completar con manejo directo
```

No especificar modelo en el delegate — OpenCode decide el backend. El prompt debe pedir el estilo deseado (e.g., "priorizar sintaxis precisa sobre verbosidad").

---

## Fallback Chain Universal

```
DeepSeek V4 Flash (trial, riesgo medio)
  → Big Pickle (estable, siempre disponible)

MiMo-V2.5 (trial, riesgo alto)
  → Big Pickle (estable, capacidad SEO básica)

Nemotron 3 Ultra (trial, riesgo alto — no datos sensibles)
  → Big Pickle (estable)

Big Pickle (estable)
  → Fondo de cadena. No hay más fallback.
```

---

## Context Window Rules

| Contexto actual | Acción |
|---|---|
| <50K | Routing normal aplica |
| 50K-100K | Priorizar delegación para tareas que beneficiarían de modelo más rápido |
| 100K-150K | Solo delegar tareas críticas de sintaxis/performance |
| >150K | Security Gate → manejo directo forzado |
| >200K | Manejo directo obligatorio. Sin excepción. |

---

## Tabla de Riesgo por Modelo

| Modelo | Riesgo | Implica |
|---|---|---|
| Big Pickle | Bajo | Disponibilidad garantizada. Usar para producción y larga duración. |
| DeepSeek V4 Flash Free | Medio | Puede desaparecer. Usar para tareas activas, no para recurrentes. |
| MiMo-V2.5 Free | Alto | Experimental. Solo para exploración. |
| North Mini Code Free | Alto | Sin use case asignado actualmente. |
| Nemotron 3 Ultra | Alto | One-off. No usar con datos sensibles. |

---

## Notas de Implementación

- Este skill se activa automáticamente en cada sesión (vía AGENTS.md o contextual loading)
- La tabla de routing es el default — puede sobreescribirse con `mem_save(topic_key="routing/override")`
- El security gate es innegociable: si hay duda sobre sensibilidad de datos, tratar como sensible
- `ponytail:` La delegación no controla qué modelo usa el subagente — es un hint, no una instrucción. Si OpenCode agrega model hint en delegate(), actualizar.
