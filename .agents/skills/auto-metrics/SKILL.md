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
## BIAS CALIBRATION — HARD GATE (pre-scoring)
### Pre-check
If `.learnings/bias-calibration.json` exists with `samples >= 2`:
1. **CHECK bitácora for today's audit entry**: search for `[audit] {today}` pattern
2. **If no audit found**: STOP. Load `external-auditor` skill and run blind audit first.
   - Rationale: offsets exist from past sessions, may not reflect current bias.
   - Fresh audit ensures latest diff is evaluated.
3. **If audit found**: proceed to correction.

### Correction
1. Subtract each dim's avg offset from self-score BEFORE threshold checks
2. Log: "Bias corrected: {dim}={offset}"
3. Only THEN check thresholds (<7→immune, ≥9→mem_save)
4. Update calibration: append today's self/audit pair to `.learnings/bias-calibration.json`

### Fail behavior
- No bias-calibration.json → OK (no data yet)
- Exists, samples≥2, no today audit → **MUST NOT score without fresh audit**
- Audit exists, offsets applied → proceed normally

Offsets persist; repeat every auto-metrics run. See AGENTS.md §L.
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
