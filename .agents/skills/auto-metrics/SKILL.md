---
name: auto-metrics
description: Post-task self-evaluation. Score 7 dims + skill validation with multi-trial benchmark.
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "3.1"
triggers: task completion, score/metric/auto-score, session end, skill validation, benchmark
---

Post EVERY done/listo before next task. Avg<7 -> immune-system.

## 7 Dimensions (1-10)
| Dim | 1-3 | 4-6 | 7-9 | 10 |
|-----|-----|-----|-----|----|
| Correctness | Wrong | Partial/buggy | Minor gap | 0 rework |
| Tokens | Verbose/waste | Some bloat | Lean | Minimal |
| ErrPrev | Repeated error | Partial fix | No repeat | +Immune pattern |
| Skill | Wrong skill | None loaded | Correct | +anti-pattern save |
| Speed | >5 wasted iters | Back-and-forth | Efficient | 0 redundant steps |
| Breadth | Only 1 dim | 2-3 dims | All relevant | +unexpected value |
| SkillEval | No baseline | <10% delta | >=10% delta | >=20% + mem_save |

Measuring: Correctness=rework needed | Tokens=vs min | ErrPrev=immune+engram | Skill=loaded correctly | Speed=wasted iterations | Breadth=all relevant | SkillEval=delta vs baseline

## Action by Avg
>=8: Maintain | 6-7.9: Light review+update | 4-5.9: Improvement+immune+dreaming | <4: Full stop+root cause+AGENTS.md rewrite

## Storage
mem_save(type="learning", title="auto-score:{task}", content="Correctness:X/10|Tokens:X/10|ErrPrev:X/10|Skill:X/10|Speed:X/10|Breadth:X/10|SkillEval:X/10|Avg:X.X/10|Pattern:{what}")

## Trend Check (every 10 scores or session end)
1. mem_search(query="auto-score:", limit=20) -> per-dim means, compare prev(5) vs recent(5)
2. Report: Trend Report {date} | {N} scores | per-dim delta table | Verdict: improving/stable/declining
3. Dim drop >0.5 -> immune-system. Avg <6 -> gap analysis.
4. Save: mem_save(type="pattern", title="trend:{date}")

## Skill Validation (every new/modified skill -> first 3 uses)
Baseline before 1st use. 3 trials on independent tasks. Compare avg vs baseline.

| Metric | Baseline | Good (7) | Excellent (10) |
|--------|----------|----------|----------------|
| Tool calls | 8 avg | <=5 | <=3 |
| Tokens | 1200 avg | <=800 | <=500 |
| Score | 6.0/10 | >=7.5 | >=9.0 |
| Errors | 2 avg | <=1 | 0 |
| Iterations | 14 avg | <=8 | <=5 |

Verdict: >=20% in >=3 metrics -> Excel (registry+mem_save) | >=10% in >=3 -> Keep (registry) | >=5% in >=2 -> Improve (skill-improver) | <5% or negative >=2 -> Discard | Avg<7 -> Discard

## Anti-Patterns
Score w/o data | Always 7+ (be critical, 5 is fine) | Skip simple tasks | Score+ignore (if<7, act) | Forget baseline (record before 1st use)
