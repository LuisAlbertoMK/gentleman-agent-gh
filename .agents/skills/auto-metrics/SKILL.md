---
name: auto-metrics
description: "Post-task self-evaluation. Score 7 dims + skill validation with multi-trial benchmark."
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "3.2"
  changelog: "3.2: karpathy compress"
triggers: "task completion, score/metric/auto-score, session end, skill validation, benchmark"
---
Post EVERY done/listo before next task. Avg<7 → immune-system.
## 7 Dimensions (1-10)
| Dim | 1-3 | 4-6 | 7-9 | 10 |
|-----|-----|-----|-----|----|
| Correctness | Wrong | Partial/buggy | Minor gap | 0 rework |
| Tokens | Verbose | Some bloat | Lean | Minimal |
| ErrPrev | Repeated | Partial fix | No repeat | +Immune pattern |
| Skill | Wrong | None loaded | Correct | +anti-pattern |
| Speed | >5 wasted | Back-forth | Efficient | 0 redundant |
| Breadth | 1 dim | 2-3 dims | All relevant | +unexpected |
| SkillEval | No baseline | <10% delta | >=10% | >=20% +mem_save |
## Action by Avg: ≥8 Maintain · 6-7.9 Light review · 4-5.9 Improve+immune+dream · <4 Full stop+root cause
## Storage: `mem_save(type="learning", title="auto-score:{task}", content="Correctness:X|Tokens:X|...|Avg:X.X|Pattern:{what}")`
## Trend (every 10 or session end)
`mem_search(query="auto-score:", limit=20)` → per-dim means, compare prev(5) vs recent(5). Dim drop >0.5 → immune-system. Avg<6 → gap analysis.
## Skill Validation (first 3 uses of new/modified skill)
| Metric | Baseline | Good (7) | Excel (10) |
|--------|----------|----------|------------|
| Tool calls | 8 avg | ≤5 | ≤3 |
| Tokens | 1200 avg | ≤800 | ≤500 |
| Score | 6.0 | ≥7.5 | ≥9.0 |
| Errors | 2 avg | ≤1 | 0 |
Verdict: ≥20% in ≥3→Excel · ≥10% in ≥3→Keep · ≥5% in ≥2→Improve · <5% or negative→Discard · Avg<7→Discard
## Anti-Patterns: Score w/o data · Always 7+ (be critical, 5 is fine) · Skip simple tasks · Score+ignore · No baseline
