---
name: auto-metrics
description: Post-task self-evaluation. Score 7 dims + skill validation with multi-trial benchmark.
license: Apache-2.0
metadata: version: "3.1"
triggers: task completion, "score/metric/auto-score/cómo lo hice", session end, skill validation, benchmark
---

## Mandatory
After EVERY "done/listo". Score BEFORE next task. Avg<7→immune-system.

## Philosophy (SkillsBench + Galileo + mgechev/skill-eval)
**Outcome**: correctness, quality · **Trajectory**: tokens, speed, errors · **Component**: per-skill delta (SkillEval)
Multi-trial: 3 trials per new skill before verdict. Pre/post baseline comparison.

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

**Measure**: Correctness=rework needed? Tokens=tool calls+context vs min. ErrPrev=immune+engram check. Skill=loaded correct? Speed=iterations wasted? Breadth=13-dim coverage? SkillEval=delta vs baseline.

## Action by Avg
| Avg | Action |
|:---:|--------|
| ≥8 | Maintain |
| 6-7.9 | Light review · update skill/AGENTS.md |
| 4-5.9 | Improvement cycle · immune+dreaming |
| <4 | Full stop · root cause · AGENTS.md rewrite |

## Storage
`mem_save(type="learning", title="auto-score:{task}", content="**Correctness**:X/10|**Tokens**:X/10|**ErrPrev**:X/10|**Skill**:X/10|**Speed**:X/10|**Breadth**:X/10|**SkillEval**:X/10|**Avg**:X.X/10|**Pattern**:{what}")`

## Trend Check (mandatory every 10 scores OR session end)
1. `mem_search(query="auto-score:", limit=20)` → parse per-dim means, compare prev(5) vs recent(5)
2. Report:
```
## Trend Report: {date} | {N} scores
| Dim | Prev | Recent | Delta |
| Correctness | X.X | X.X | +X.X | ... | **Avg** | **X.X** | **X.X** | **±X.X** |
Verdict: improving/stable/declining
```
3. If dim drop >0.5 → `immune-system` · If avg <6 → gap analysis + improvement cycle
4. Save: `mem_save(type="pattern", title="trend:{date}", content="<report>")`

## Skill Validation Protocol
### When: cada skill nueva/modificada → primeros 3 usos
**Step 1 — Baseline** (antes del 1er uso): tool calls, tokens, score (est.), errors, iterations
**Step 2 — 3 Trials**: registrar los mismos datos en 3 tareas independientes
**Step 3 — Verdict**: comparar promedio trials vs baseline

| Métrica | Baseline típico | Bueno (7) | Excelente (10) |
|---------|----------------|-----------|----------------|
| Tool calls | 8 avg | ≤5 | ≤3 |
| Tokens | 1200 avg | ≤800 | ≤500 |
| Score | 6.0/10 | ≥7.5 | ≥9.0 |
| Errors | 2 avg | ≤1 | 0 |
| Iteraciones | 14 avg | ≤8 | ≤5 |

**Decision** (SkillsBench normalized gain):
| Δ | Veredicto |
|---|-----------|
| ≥20% en ≥3 métricas | 🟢 Excelente — registry + mem_save |
| ≥10% en ≥3 métricas | 🟢 Mantener — registry |
| ≥5% en ≥2 métricas | 🟡 Mejorar — skill-improver |
| <5% o negativo en ≥2 | 🔴 Descartar — podar + discard reason |
| Score avg <7 | 🔴 Descartar |

Valores recalibrados cada 10 scores vía Trend Check.

## Anti-Patterns
❌ Score w/o data · always 7+ → be critical, 5 is fine · skip simple tasks → score all · score+ignore → if<7, ACT · forget baseline → record BEFORE 1st use
