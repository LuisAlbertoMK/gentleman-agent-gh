---
name: auto-metrics
description: >
  Post-task self-evaluation. Score 6 dims (correctness, tokens, error prevention, skill, speed, breadth). Auto-trigger improvement when avg <7.
  Trigger: Task completion, "score", "metric", "auto-score", "cómo lo hice", session end.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.2"
---

## Auto-Score (mandatory)
After EVERY "done"/"listo"/"next"/task complete. Score BEFORE next task. Avg < 7 → immune-system primero.

## 6 Dimensions (1-10)
| Dim | 1-3 poor | 4-6 ok | 7-9 good | 10 elite |
|-----|----------|--------|----------|----------|
| **Correctness** | Wrong | Partial | Solves, minor gap | First-time correct, 0 rework |
| **Token Efficiency** | Verbose, repeated | Some waste | Compact, no filler | Min tokens, max signal |
| **Error Prevention** | No evidence | Partial evidence | Default-FAIL applied | + Immune/Dreaming used |
| **Skill Resolution** | Wrong skill | No skill loaded | Correct skill | + anti-pattern check |
| **Execution Speed** | >5 iter waste | Some back-forth | Efficient, minor waste | First-time right, 0 redo |
| **Tool Breadth** | Basic only | 1-2 skills | Correct stack | All relevant + anti-pattern |

## Scoring
- **≤4** → immune-system → anti-pattern doc
- **5-6** → review gap → update skill/AGENTS.md
- **7+** → log only
- **10** → `mem_save` pattern to replicate

## Storage
```bash
mem_save(type="learning", title="auto-score: {task}",
content="**Correctness**: X/10 | **Tokens**: X/10 | **ErrPrev**: X/10 | **Skill**: X/10 | **Speed**: X/10 | **Breadth**: X/10 | **Avg**: X.X/10 | **Pattern**: {what worked/failed}")
```

## Trend Check (~every 10 scores)
1. `mem_search(query="auto-score:")` → collect last 10
2. Up? → no action
3. Down? → diagnose → update AGENTS.md/skills
4. Avg < 6? → full gap analysis → improvement cycle

| Avg | Action |
|:---:|--------|
| ≥8 | Maintain |
| 6-7.9 | Light review · skill/AGENTS.md tweak |
| 4-5.9 | Improvement cycle · immune+dreaming |
| <4 | Full stop · root cause · AGENTS.md rewrite |

## Anti-Patterns
- ❌ Score without data → ✅ evidence first
- ❌ Always 7+ (optimism) → ✅ be critical, 5 is fine
- ❌ Skip "simple tasks" → ✅ score all, pattern detection
- ❌ Score and ignore → ✅ if < 7, ACT
