---
name: auto-metrics
description: Post-task self-evaluation. Score 6 dims. Trigger avg<7→immune-system.
license: Apache-2.0
metadata: version: "1.4"
triggers: task completion, "score/metric/auto-score/cómo lo hice", session end
---

## Mandatory
After EVERY "done/listo". Score BEFORE next task. Avg<7→immune-system.

## 6 Dimensions (1-10)
| Dim | 1-3 | 4-6 | 7-9 | 10 |
|-----|-----|-----|-----|----|
| **Correctness** | Wrong | Partial | Minor gap | 0 rework |
| **Tokens** | Verbose | Some waste | Compact | Min tokens |
| **ErrPrev** | No evidence | Partial | Default-FAIL | +Immune/Dream |
| **Skill** | Wrong | None loaded | Correct | +anti-pattern |
| **Speed** | >5 iter waste | Back-forth | Efficient | 0 redo |
| **Breadth** | Basic | 1-2 skills | Correct stack | All relevant |

## Action by Avg
| Avg | Action |
|:---:|--------|
| ≥8 | Maintain |
| 6-7.9 | Light review · update skill/AGENTS.md |
| 4-5.9 | Improvement cycle · immune+dreaming |
| <4 | Full stop · root cause · AGENTS.md rewrite |

## Storage
`mem_save(type="learning", title="auto-score:{task}", content="**Correctness**:X/10|**Tokens**:X/10|**ErrPrev**:X/10|**Skill**:X/10|**Speed**:X/10|**Breadth**:X/10|**Avg**:X.X/10|**Pattern**:{what}")`

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

## Anti-Patterns
❌ Score w/o data → evidence first · always 7+ → be critical, 5 is fine · skip simple tasks → score all · score+ignore → if<7, ACT
