---
name: auto-metrics
description: > Post-task self-evaluation. Score correctness, token efficiency, error prevention, skill resolution. Auto-trigger improvement when score <7.
  Trigger: Task completion, session end, "score", "metric", "auto-score", "cómo lo hice".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.1"
---

## Auto-Score (after EVERY completion — mandatory)

Required after: "done" / "listo" / "next" / task complete. 
Score BEFORE starting next task. < 7 → immune-system primero.

Score 4 dimensions (1-10), log to Engram.

### Dimensions

| Dimension | 1-3 (poor) | 4-6 (ok) | 7-9 (good) | 10 (elite) |
|-----------|:----------:|:--------:|:----------:|:----------:|
| **Correctness** | Wrong answer | Partial fix | Solves problem, minor gap | First-time correct, zero rework |
| **Token Efficiency** | Verbose, repeated | Some waste | Compact, no filler | Minimal tokens, max signal |
| **Error Prevention** | No evidence | Evidence partial | Default-FAIL applied | Immune/Dreaming also used |
| **Skill Resolution** | Wrong skill | No skill loaded | Correct skill | Correct skill + anti-pattern check |

### Scoring rules
- **≤4**: Auto-trigger immune-system → document as anti-pattern
- **5-6**: Review gap → update skill or AGENTS.md
- **7+**: OK. Log only.
- **10**: `mem_save` as pattern to replicate

### Storage format
```
mem_save(type="learning", title="auto-score: {task-summary}", content="**Correctness**: X/10 | **Tokens**: X/10 | **Error Prevention**: X/10 | **Skill**: X/10 | **Avg**: X.X/10 | **Pattern**: {what worked or failed}")
```

## Periodic Trend Check (~every 10 scores)
1. `mem_search(query="auto-score:")` — collect last 10 scores
2. Trend up? → good, no action
3. Trend down? → diagnose cause → update AGENTS.md or skills
4. Avg < 6? → full gap analysis → improvement cycle

## Thresholds
| Avg Score | Action |
|:---------:|--------|
| ≥8 | Maintain. No action needed. |
| 6-7.9 | Light review. Skill or AGENTS.md tweak. |
| 4-5.9 | Improvement cycle. Immune system + Dreaming. |
| <4 | Full stop. Root cause analysis + AGENTS.md rewrite. |

## Workflow
```
Task complete → Auto-score 4 dims → Log to Engram
Score < 7? → Trigger improvement mode
Score ≥ 7? → Continue. Periodic trend check.
```

## Anti-Patterns
| ❌ Don't | ✅ Do |
|----------|-------|
| Score without data | Check evidence first |
| Always score 7+ (optimism bias) | Be critical. 5 is fine. |
| Skip scoring for "simple tasks" | Score even small wins. Pattern detection. |
| Score then ignore | If < 7, ACT on it. |
