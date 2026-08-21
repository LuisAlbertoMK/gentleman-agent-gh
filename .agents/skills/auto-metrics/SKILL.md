---
name: auto-metrics
description: "Self-evaluation scoring. Trigger via !score or !metrics — not automatic."
triggers: "!score, !metrics, explicit score/metric request, session end via !close"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1740
---
## When to Use
Only on explicit request (!score, !metrics, !close). NOT automatic after every task.
## PRE-FLIGHT (HARD GATE)
If `.learnings/bias-calibration.json` exists with `samples >= 2`: check bitácora for `[audit] {today}`. None → **FAIL** — run !audit first. Never score without audit if biases exist.
## CORRECTION (if audit available)
1. Subtract each dim's avg offset from self-score BEFORE thresholds 2. Log `Bias corrected: {dim}={offset}` 3. Thresholds (<7→immune, ≥9→mem_save) 4. Append today's self/audit pair
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
## ACTION
≥8 Maintain · 6-7.9 Light review · 4-5.9 Improve+immune+dream · <4 Full stop+root cause
## STORAGE
`mem_save(type="learning", title="auto-score:{task}", content="Correctness:X|Tokens:X|...|Avg:X.X|Pattern:{what}")`
## TREND (every 10 or session end)
`mem_search(query="auto-score:", limit=20)` → per-dim means, prev(5) vs recent(5). Drop >0.5 → immune-system. Avg<6 → gap analysis.
---
docs/skills/auto-metrics/reference.md
---