---
name: auto-metrics
description: "Self-evaluation scoring. Trigger via !score or !metrics — not automatic."
triggers: "!score, !metrics, explicit score/metric request, session end via !close"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
Only run on explicit request (!score, !metrics, !close) or user asking for score.
NOT automatic after every task — eliminated to reduce ceremony for trivial changes.

## PRE-FLIGHT (HARD GATE)
If `.learnings/bias-calibration.json` exists with `samples >= 2`:
- Check bitácora for today's audit entry (`[audit] {today}`)
- If no audit found: **FAIL** — "no audit today — scoring without bias correction is forbidden. Run !audit first."
- This is a HARD gate. Do NOT skip. Do NOT score without audit if biases exist.

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

## Refs
external-auditor · dreaming · immune-system · metricas · bitacora

## EXAMPLES (4-5)

### Example 1: Correct Implementation — Score 8.2 (Maintain)
**Task**: Fixed N+1 query in UserList component
**Scores**: Correctness:9 | Tokens:8 | ErrPrev:8 | Skill:8 | Speed:8 | Breadth:7 | SkillEval:9
**Avg**: 8.1 → **Maintain**
**Reason**: Loaded testing-strategy skill, wrote test first, fixed in 1 pass, no repeat bugs
**Storage**: `mem_save(type="learning", title="auto-score:fix-n1-userlist", content="Correctness:9|Tokens:8|ErrPrev:8|Skill:8|Speed:8|Breadth:7|SkillEval:9|Avg:8.1|Pattern:test-first-n1-fix")`

### Example 2: Partial Gap — Score 5.7 (Improve + immune + dream)
**Task**: Added pagination to API endpoint
**Scores**: Correctness:6 | Tokens:5 | ErrPrev:4 | Skill:5 | Speed:6 | Breadth:6 | SkillEval:5
**Avg**: 5.3 → **Improve + immune + dream**
**Reason**: Missed edge case (empty page), verbose response, didn't load api-testing skill
**Action**: immune-system save pattern "pagination-empty-page", dreaming queue
**Storage**: `mem_save(type="learning", title="auto-score:pagination-api", content="Correctness:6|Tokens:5|ErrPrev:4|Skill:5|Speed:6|Breadth:6|SkillEval:5|Avg:5.3|Pattern:missed-empty-page")`

### Example 3: Critical Failure — Score 3.1 (Full stop + root cause)
**Task**: Refactored auth middleware
**Scores**: Correctness:3 | Tokens:4 | ErrPrev:2 | Skill:3 | Speed:3 | Breadth:4 | SkillEval:3
**Avg**: 3.1 → **Full stop + root cause**
**Reason**: Introduced 2 regressions, wrong skill (used code-generation instead of auth-hardening), 3 back-and-forth cycles
**Action**: recovery-protocol, immune-system catalog both regressions, gap-analysis on auth flow
**Storage**: `mem_save(type="learning", title="auto-score:auth-refactor-fail", content="Correctness:3|Tokens:4|ErrPrev:2|Skill:3|Speed:3|Breadth:4|SkillEval:3|Avg:3.1|Pattern:regression-auth")`

### Example 4: Excellent — Score 9.3 (Maintain + mem_save pattern)
**Task**: Implemented WebSocket reconnection with exponential backoff
**Scores**: Correctness:10 | Tokens:9 | ErrPrev:9 | Skill:10 | Speed:9 | Breadth:10 | SkillEval:9
**Avg**: 9.4 → **Maintain** + mem_save anti-pattern
**Reason**: Loaded performance + llm-security skills, zero redundant calls, covered all edge cases, 20% skill delta
**Storage**: `mem_save(type="learning", title="auto-score:ws-reconnect", content="Correctness:10|Tokens:9|ErrPrev:9|Skill:10|Speed:9|Breadth:10|SkillEval:9|Avg:9.4|Pattern:ws-resilience-complete")`

### Example 5: Bias-Corrected Score — Audit Applied
**Task**: Code review on PR #342
**Raw scores**: Correctness:8 | Tokens:7 | ErrPrev:7 | Skill:8 | Speed:7 | Breadth:8 | SkillEval:7
**Bias offsets** (from `.learnings/bias-calibration.json`): Correctness:-0.8 | Tokens:-0.5 | Skill:-0.6
**Corrected**: Correctness:7.2 | Tokens:6.5 | ErrPrev:7 | Skill:7.4 | Speed:7 | Breadth:8 | SkillEval:7
**Avg**: 7.1 → **Light review** (was 7.4 Maintain pre-correction)
**Log**: "Bias corrected: Correctness=-0.8 Tokens=-0.5 Skill=-0.6"

## TESTING PATTERNS (3)

### Pattern 1: Self-Consistency Check (3-Run Variance)
```powershell
# Run scoring 3x on same task, compute variance
$runs = 1..3 | % { pwsh scripts/score-auto.ps1 -Task "fix-n1-userlist" -Json }
$variance = ($runs | Measure-Object -Property Avg -StandardDeviation).StandardDeviation
if ($variance -gt 0.8) { "INCONSISTENT - investigate bias" } else { "STABLE" }
```
**Pass**: Variance ≤ 0.8 across 3 runs

### Pattern 2: Audit Agreement Delta
```powershell
# Compare self-score vs external-auditor on same task
$self = pwsh scripts/score-auto.ps1 -Task "pagination-api" -Json
$audit = pwsh scripts/external-audit.ps1 -Task "pagination-api" -Json
$delta = [math]::Abs($self.Avg - $audit.Avg)
if ($delta -gt 1.5) { "CALIBRATION DRIFT - update bias-calibration.json" }
```
**Pass**: Self vs audit delta ≤ 1.5

### Pattern 3: Trend Regression Detection
```powershell
# Every 10 scores, check per-dim mean drop >0.5
$scores = mem_search "auto-score:" -Limit 20
$recent5 = $scores | Select -First 5 | % { $_.content -split '\|' } | ForEach { $_[0].Split(':')[1] }
$prev5 = $scores | Select -Skip 5 -First 5 | % { $_.content -split '\|' } | ForEach { $_[0].Split(':')[1] }
$dims = @("Correctness","Tokens","ErrPrev","Skill","Speed","Breadth","SkillEval")
$dims | % {
  $r = [double]($recent5 | Where { $_ -like "$_:*" } | % { $_.Split(':')[1] } | Measure -Average).Average
  $p = [double]($prev5 | Where { $_ -like "$_:*" } | % { $_.Split(':')[1] } | Measure -Average).Average
  if ($p - $r -gt 0.5) { "IMMUNE: $_ dropped $([math]::Round($p-$r,2))" }
}
```
**Pass**: No dimension drops > 0.5 between prev(5) and recent(5)

## EDGE CASES (4)

### Edge Case 1: No Prior Audit — Hard Gate Block
**Scenario**: `.learnings/bias-calibration.json` exists with `samples >= 2` but no `[audit] {today}` in bitácora
**Behavior**: **FAIL immediately** — "no audit today — scoring without bias correction is forbidden. Run !audit first."
**Resolution**: Run `!audit` or wait for next day's audit cycle before scoring

### Edge Case 2: Single Sample Calibration — No Correction Applied
**Scenario**: `.learnings/bias-calibration.json` exists but `samples < 2`
**Behavior**: Skip bias correction, score normally, append this run as sample #2
**Log**: "Calibration samples < 2 — no correction applied, appended as sample 2"

### Edge Case 3: Task Too Small — Skip Scoring
**Scenario**: Task touches ≤ 1 file, < 10 lines changed, no skill loaded
**Behavior**: **Auto-skip** with log: "Task below threshold — not scored (1 file, 5 lines, 0 skills)"
**Rationale**: Reduces ceremony for trivial changes (typo fixes, config tweaks)

### Edge Case 4: SkillEval Baseline Missing — Neutral Score
**Scenario**: No prior skill baseline exists for this skill type
**Behavior**: SkillEval = 5 (neutral), do not penalize, log: "No baseline for skill X — SkillEval=5 neutral"
**Next run**: This run becomes the baseline for future comparisons

## ANTI-PATTERNS (2 Additional)

### Anti-Pattern 5: "Always Maintain" — Inflating scores to avoid immune/dream
**Symptom**: 10+ consecutive scores ≥ 8.0 with zero immune-system entries
**Root cause**: Fear of triggering improvement workflow, gaming the metric
**Fix**: External audit mandatory after 5 consecutive ≥ 8.0; immune-system.save("score-inflation") if confirmed

### Anti-Pattern 6: "Score and Forget" — No action on < 6.0
**Symptom**: Score < 6.0 logged but no immune-system entry, no dreaming queue, no gap-analysis
**Root cause**: Treating score as vanity metric instead of action trigger
**Fix**: HARD RULE — score < 6.0 MUST create at least one immune-system entry OR gap-analysis task within same session
