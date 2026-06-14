---
name: auto-metrics
description: Post-task self-evaluation. Score 7 dims + skill validation with multi-trial benchmark.
license: Apache-2.0
metadata: version: "3.0"
triggers: task completion, "score/metric/auto-score/cómo lo hice", session end, skill validation, benchmark
---

## Mandatory
After EVERY "done/listo". Score BEFORE next task. Avg<7→immune-system.

## Scoring Philosophy (inspired by SkillsBench + Galileo + mgechev/skill-eval)
- **Outcome metrics**: what the agent produced (correctness, quality)
- **Trajectory metrics**: how the agent got there (tokens, speed, errors)
- **Component metrics**: per-skill delta (SkillEval)
- Multi-trial: every new skill gets 3 trials before verdict
- Pre/post baseline: compare WITH skill vs WITHOUT skill

## 7 Dimensions (1-10)
| Dim | 1-3 | 4-6 | 7-9 | 10 |
|-----|-----|-----|-----|----|
| **Correctness** | Wrong output | Partial/buggy | Minor gap | 0 rework |
| **Tokens** | Verbose/waste | Some bloat | Lean | Minimal |
| **ErrPrev** | Repeated error | Partial fix | No repeat | +Immune pattern |
| **Skill** | Wrong skill | None loaded | Correct | +anti-pattern save |
| **Speed** | >5 wasted iters | Back-and-forth | Efficient | 0 redundant steps |
| **Breadth** | Only 1 dim | 2-3 dims | All relevant | +unexpected value |
| **SkillEval** | No baseline | <10% delta | ≥10% delta | ≥20% + mem_save |

### Detailed Scoring Guide

| Dim | What to measure | How to score |
|-----|----------------|-------------|
| **Correctness** | Did the output match the task? Any rework needed? | 10 = shipped as-is. 7 = minor tweak. 4 = major redo. 1 = wrong answer. |
| **Tokens** | How many tool calls + context tokens used vs minimum needed? | 10 = under 600t equiv. 7 = 600-900. 4 = 900-1500. 1 = >1500. |
| **ErrPrev** | Did I make the same mistake I made before? Check immune-system + engram. | 10 = no, and I saved new pattern. 7 = no repeat. 4 = partially. 1 = same error again. |
| **Skill** | Did I load the correct skill for this task? | 10 = correct + saved anti-pattern. 7 = correct. 4 = none loaded. 1 = wrong. |
| **Speed** | Did I iterate efficiently or waste rounds? | 10 = delivered in 1 pass. 7 = 2-3 rounds. 4 = 4-6. 1 = >6 with no progress. |
| **Breadth** | Did I cover all relevant quality dimensions? | 10 = 13-dim full + extra. 7 = core dims. 4 = only what was asked. 1 = missed key dims. |
| **SkillEval** | Did the loaded skill improve performance vs doing it raw? | 10 = ≥20% better in ≥3 metrics. 7 = ≥10%. 4 = <10%. 1 = no baseline recorded. |

## Action by Avg
| Avg | Action |
|:---:|--------|
| ≥8 | Maintain |
| 6-7.9 | Light review · update skill/AGENTS.md |
| 4-5.9 | Improvement cycle · immune+dreaming |
| <4 | Full stop · root cause · AGENTS.md rewrite |

## Storage
`mem_save(type="learning", title="auto-score:{task}", content="**Correctness**:X/10|**Tokens**:X/10|**ErrPrev**:X/10|**Skill**:X/10|**Speed**:X/10|**Breadth**:X/10|**SkillEval**:X/10|**Avg**:X.X/10|**Pattern**:{what}")`

## Trend Check (mandatory)
Run EVERY time a score is saved AND at session end. Always when count % 10 == 0.

1. `mem_search(query="auto-score:", limit=20)` → collect last N scores
2. Parse averages → compute per-dimension means
3. Compare: prev period (oldest 5) vs recent (newest 5)
4. Report:
```
## Trend Report: {date}
Period: {oldest_date} → {newest_date} ({N} scores)
| Dim | Prev | Recent | Delta |
|-----|------|--------|-------|
| Correctness | X.X | X.X | +X.X |
| Tokens | X.X | X.X | +X.X |
| ... | ... | ... | ... |
| **Avg** | **X.X** | **X.X** | **±X.X** |
Verdict: improving/stable/declining
Action: {none|diagnose|gap-cycle|rewrite}
```
5. If declining (>0.5 drop in any dim) → `immune-system` + diagnose root cause
6. If avg < 6 → full gap analysis + improvement cycle
7. Save report: `mem_save(type="pattern", title="trend:{date}", content="<report>")`

## Skill Validation Protocol
### When to trigger
Cada skill nueva o modificada → track primeros 3 usos.

### Step 1: Baseline (before 1st use)
Antes de cargar la skill por primera vez, registrar:
```
Baseline: {skill_name}
- Tool calls (est.): X
- Tokens (est.): X
- Avg score (est.): X.X
- Errors (est.): X
- Iterations (est.): X
```

### Step 2: 3-Trial Execution
Usar la skill en 3 tareas independientes (misma categoría).
Por cada uso, registrar:
```
Trial {N}: {task}
- Tool calls: X
- Tokens: X
- Avg score: X.X
- Errors: X
- Iterations: X
```

### Step 3: Verdict (after 3rd use)
Comparar promedio de trials vs baseline:

```
SkillValidation: {skill_name}
| Métrica | Baseline | Avg 3 trials | Delta |
|---------|----------|-------------|-------|
| Tool calls | 8.0 | 5.0 | -37% ✅ |
| Tokens | 1200 | 850 | -29% ✅ |
| Score | 6.0 | 8.2 | +37% ✅ |
| Errors | 2.0 | 0.5 | -75% ✅ |
| Iterations | 14.0 | 8.0 | -43% ✅ |
```

### Decision Rules (inspired by SkillsBench normalized gain)
| Condición | Veredicto | Acción |
|-----------|-----------|--------|
| Δ ≥20% en ≥3 métricas | 🟢 Excelente | `skill-registry` priorizar + mem_save pattern |
| Δ ≥10% en ≥3 métricas | 🟢 Mantener | Registrar en registry |
| Δ ≥5% en ≥2 métricas | 🟡 Mejorar | `skill-improver` para pulir |
| Δ <5% o negativo en ≥2 | 🔴 Descartar | `skill-improver` podar + mem_save discard reason |
| Score avg <7 | 🔴 Descartar | No pasa umbral de calidad |

### Criterios de Baseline (SkillsBench-referenced)
| Métrica | Baseline típico | Bueno (7) | Excelente (10) |
|---------|----------------|-----------|----------------|
| Tool calls | 8 avg | ≤5 | ≤3 |
| Tokens | 1200 avg | ≤800 | ≤500 |
| Score | 6.0/10 | ≥7.5 | ≥9.0 |
| Errors | 2 avg | ≤1 | 0 |
| Iteraciones | 14 avg | ≤8 | ≤5 |

Estos valores se recalibran automáticamente cada 10 scores vía Trend Check.

## Anti-Patterns
❌ Score w/o data → evidence first · always 7+ → be critical, 5 is fine · skip simple tasks → score all · score+ignore → if<7, ACT · forget baseline → always record BEFORE 1st use
