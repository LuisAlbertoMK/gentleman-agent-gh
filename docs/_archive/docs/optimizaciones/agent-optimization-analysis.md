# Agent Optimization Analysis — 2026-07-05

> Análisis multi-agente + research web sobre cómo mejorar velocidad, calidad y eficiencia de tokens.
> Pendiente para Cycle 20.

---

## 1. AGENTS.md Compression (Target: 20KB → 12-15KB)

### Hallazgo
ETH Zurich AGENTbench (arXiv 2602.11988, 2026) demostró que LLM-generated context files **decrease** success rates (−0.5% to −2%) con +20% inference cost. Architecture overviews in AGENTS.md actively hurt — redundant with docs the agent already reads.

### Recomendaciones

| # | Acción | Ahorro estimado | Riesgo |
|---|--------|-----------------|--------|
| 1 | Sacar secciones de arquitectura (Project Context, Project Overrides) que el agente ya descubre solo | ~3KB | Bajo |
| 2 | Comprimir Ponytail ladder: convertir 9 rungs en 3 líneas de decisión + referencias a skill | ~2KB | Medio |
| 3 | Fusionar reglas duplicadas entre AGENTS.md global y local (D:\gentleman-agent-gh\AGENTS.md vs ~\.config\opencode\AGENTS.md) | ~2KB | Bajo |
| 4 | Mover engram protocol a skill file (ya existe `code-memory` + `engram` MCP) | ~4KB | Medio (protocolo referenciado en cada sesión) |
| 5 | Simplificar TRIANGULATE: de 3 enfoques obligatorios a 2 + auto según zona | ~1KB | Medio |
| 6 | Remover reglas de hace >3 meses sin triggers (Mitchell Hashimoto discipline) | ~1-2KB | Bajo |

### Prioridad
**Quick win**: items 1+3+6 = ~6KB ahorro, riesgo bajo. Hacer primero.

---

## 2. Token Budget Optimization

### Hallazgo
- Zylos/Chroma research: 65% of failures caused by **drift**, not exhaustion. Performance degrades past 30K tokens even in large-window models.
- ACON (arXiv Oct 2025): 26-54% memory reduction at 95%+ task accuracy via failure-driven compression.
- Anthropic tool response study: tool output is the primary token killer.

### Recomendaciones

| # | Acción | Ahorro | Esfuerzo |
|---|--------|--------|----------|
| 7 | **Upgrade context-watchdog**: agregar detección de drift (re-lecturas, re-statements del usuario) además de agotamiento | Previene ~30% de fallas | Medio |
| 8 | **ACON-style lean-context**: ajustar prompts de compresión por dominio de skill (analizar dónde falla L2/L3) | 26-54% en skills comprimidas | Alto |
| 9 | **Tool output filter**: en subagent return, strip raw logs, keep solo conclusiones | Variable, ~20% por subagent | Medio |
| 10 | **Trigger compaction at 70%** (no esperar a truncación reactiva) | Previene pérdida de estado | Bajo |
| 11 | **Compact_prompt pipeline**: preserve decisions, drop raw output después de cada paso | ~15% por ciclo | Medio |

---

## 3. File Operations Optimization

### Hallazgo
- Aider benchmark: ~105K tokens/task con repo-map + targeted reads. Claude Code: ~479K/task (4.2× más tokens por solo 7% más accuracy).
- Morphllm 2026: Cursor gets best token-to-quality ratio (1.53 accuracy/Ktok vs Claude Code's 0.16).
- Coding Agent Study (Preprints.org, Oct 2025): AST-based indexing > embeddings > grep > naive read.

### Recomendaciones

| # | Acción | Ahorro | Esfuerzo |
|---|--------|--------|----------|
| 12 | **Repo-map cache**: generar índice estructural del repo post-commit, usar para navegación sin leer archivos enteros | ~30% en tareas multi-archivo | Alto |
| 13 | **Explorer subagent pattern**: para tareas read-heavy (>3 archivos), delegar a subagente explorer con contexto fresco | ~2-5K tokens por tarea | Bajo (ya existe el patrón) |
| 14 | **Batch reads**: cuando se necesitan múltiples archivos, leerlos en paralelo no secuencial | ~3K por batch | Bajo |
| 15 | **Auditar scripts para output verboso**: agregar `-Quiet` flag donde falte, recortar output por defecto | ~5-10% en invocaciones de script | Medio |

---

## 4. Subagent Delegation Optimization

### Hallazgo
- Codex KB (Mar 2026): "Single thread trap" — cada grep, cat, test output lands in same context. Delegation prevents it.
- Inngest/Hermes Agent: subagent gets **completely fresh context** — parent must pass everything. max_depth = 1 is optimal.
- Morphllm: short tasks cost MORE tokens to delegate than execute inline.

### Recomendaciones

| # | Acción | Impacto | Esfuerzo |
|---|--------|---------|----------|
| 16 | **Codificar reglas de delegación**: max 6 concurrentes, depth 1, small model para explore | Previene over-delegation | Bajo |
| 17 | **Explicit delegation triggers** en AGENTS.md: "delegate to subagent si >3 archivos o tarea exploratoria" | ~2-5K/tarea | Bajo (cambio de prompt) |
| 18 | **Threshold mínimo**: no delegar tareas de <3 pasos (el overhead del subagent supera el ahorro) | ~2K/tarea evitada | Bajo |
| 19 | **Parallel fan-out para validaciones**: `!score` puede lanzar skill-validation en paralelo | 3× latencia mejora | Medio |

---

## 5. Self-Improvement System

### Hallazgo
- Anthropic (Jun 2026): 80%+ of code at Anthropic written by Claude. Self-improvement = capturing failure trajectories → converting to rules.
- Mitchell Hashimoto (Feb 2026): "Every time an agent makes a mistake, engineer a solution so it never makes that mistake again."
- Future AGI (2026): BayesianSearch converges in 10-30 iterations for prompt tuning.

### Recomendaciones

| # | Acción | Impacto | Esfuerzo |
|---|--------|---------|----------|
| 20 | **Version-control rule additions** linked to specific failure observations (AGENTS.md commit msg = engram-obs-{id}) | Previene regresión | Bajo |
| 21 | **BayesianSearch** para skill prompt tuning en `self-improvement` skill | 10-30 iteraciones vs 100+ | Medio |
| 22 | **Pruning discipline**: remover reglas de AGENTS.md sin trigger en >3 meses | Mantiene 12-15KB target | Bajo (revisión periódica) |
| 23 | **AGENTS.md bloat gate**: warning si supera 15KB (actual: 20KB) | Previene regresión | Bajo |

---

## 6. Harness Engineering (Confirmación del enfoque)

### Hallazgo
- OCTO Talks (May 2026): "Agentic Engineering" → "Harness Engineering". El harness (tools, permissions, context structure) determina performance más que el modelo.
- SWE-agent paper: mismo modelo (GPT-4), diferente tool interface: 11% → 18% en SWE-bench.
- Mitchell Hashimoto: "Your AGENTS.md is the primary lever."

**Conclusión**: El enfoque actual (AGENTS.md + skills + protocols) está validado por la investigación más reciente. No cambiar la estrategia — optimizarla.

### Recomendaciones

| # | Acción | Impacto |
|---|--------|---------|
| 24 | **Seguir invirtiendo en tool design quality** sobre prompt engineering | Alto |
| 25 | **Cada script debe tener output mode** (normal/quiet/json) para que el agente consuma solo lo necesario | Medio |
| 26 | **Skills como units atómicas**: cada skill debe poder cargarse independientemente sin dependencias del sistema prompt | Alto |

---

## Resumen Ejecutivo

### Prioridad Alta (Cycle 20)
1. Comprimir AGENTS.md (20KB → 12-15KB)
2. Upgradear context-watchdog con detección de drift
3. Tool output filtering (scripts -Quiet, subagent return filtering)
4. Thresholds de delegación explícitos

### Prioridad Media
5. ACON-style lean-context tuning
6. Repo-map cache
7. Parallel skill validation
8. BayesianSearch para self-improvement

### Quick Wins (1 hora)
9. Items 1, 3, 6 de AGENTS.md compression (~6KB)
10. Agregar `compact_prompt` flag en pipeline
11. Codificar reglas de delegación en AGENTS.md

---

*Generado: 2026-07-05 | Fuentes: ETH Zurich AGENTbench, Zylos Research, Codex KB, OCTO Talks, Presenc AI, Morphllm, Mitchell Hashimoto, Anthropic, Future AGI, Amplify Partners*
