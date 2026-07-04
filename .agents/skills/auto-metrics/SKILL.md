---
name: auto-metrics
description: "Self-evaluation scoring. Trigger via !score or !metrics — not automatic."
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "3.3"
  changelog: "3.3: opt-in only (no auto post-task). Risk-adaptive: only scores on !score/!metrics"
triggers: "!score, !metrics, explicit score/metric request, session end via !close"
---
## TRIGGER
Only run on explicit request (!score, !metrics, !close) or user asking for score.
NOT automatic after every task — eliminated to reduce ceremony for trivial changes.

## PRE-FLIGHT
If `.learnings/bias-calibration.json` exists with `samples >= 2`:
- Check bitácora for today's audit entry (`[audit] {today}`)
- If no audit found: skip bias correction, log "no audit today — scoring without bias correction"

## CORRECTION (if audit available)
1. Subtract each dim's avg offset from self-score BEFORE threshold checks
2. Log: "Bias corrected: {dim}={offset}"
3. Then check thresholds (<7→immune, ≥9→mem_save)
4. Update calibration: append today's self/audit pair

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
`mem_search(query="auto-score:", limit=20)` → per-dim means, compare prev(5) vs recent(5). Dim drop >0.5 → immune-system. Avg<6 → gap analysis.

## ANTI-PATTERNS
Score w/o data · Always 7+ (be critical, 5 is fine) · Skip simple tasks · Score+ignore · No baseline
