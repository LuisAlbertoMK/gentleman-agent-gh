---
name: external-auditor
description: "Blind second-opinion audit via subagent. Catches overconfidence in auto-metrics self-score."
license: Apache-2.0
metadata:
  tags: [engineering, quality]
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.1: structured parsing, error handling, double-save guard, bitacora integration, auto-metrics fallback"
triggers: after auto-metrics (code changes), "external audit", "blind review", "verificá mi auto-score", "second opinion"
---

## Why
Auto-metrics is self-scored. **Juez y parte** — sesgo de sobreconfianza. Este skill agrega un **contralor externo** ciego.

## Flow
1. **Trigger**: After `auto-metrics` on tasks with code changes
2. **Guard**: if auto-metrics was NOT run this session → skip gracefully (warn: "no baseline")
3. **Gather**: collect `git diff` output (or task summary if no diff) + auto-metrics scores
4. **Delegate**: launch subagent `general` with BLIND audit prompt (see template)
5. **Guard**: if subagent times out, errors, or returns unparseable → `mem_save(type="audit", content="FAILED: {reason}")` + retry once with simpler prompt. If retry fails → abort, log warning
6. **Parse**: extract each dim score from subagent response via `- (Correctness|Tokens|ErrPrev|Skill|Speed|Breadth): (\d+)` regex. If <4 dims parseable → treat as unparseable (go to step 5 guard)
7. **Compare**: dimension-by-dimension: `gap = abs(self_score - audit_score)`
8. **Double-save guard**: if auto-metrics already `mem_save(type="pattern")` AND audit is aligned → skip second save
9. **Act**:
   - **Aligned** (all gaps ≤1.5) → `mem_save(type="audit", content="PASSED")` on topic_key, silent pass
   - **I over-scored** (self > audit by >1.5 on any dim) → `immune-system` for each over-scored dim, log `ANTI-PATTERN-CATALOG` entry
    - **I under-scored** (audit > self by >1.5) → update bias calibration (positive offset), no immune
    - **Mixed** (some over, some under) → immune ONLY on over-scored dims
10. **Log**: `bitacora` append audit entry: `external-auditor: {PASSED|OVERSCORE|FAILED}`
11. **Update bias calibration**: compute `offset = self_score - audit_score` per dim. Update `.learnings/bias-calibration.json` with rolling window (keep last 3). Average offsets → stored. See AGENTS.md §L.

## Thresholds
| Signal | Action |
|--------|--------|
| All gaps ≤1.5 | ✅ Pass — `mem_save` audit record |
| 1 dim >1.5 (self higher) | ⚠️ immune-system — anti-pattern entry |
| 2+ dims >1.5 (self higher) | 🔴 Full stop — re-evaluate task before continuing |
| Subagent scores me HIGHER | 📊 Note for calibration (I'm too hard on myself) |
| Subagent fails/abort | ⚠️ Log warning, continue without audit |

## Blind Audit Prompt Template
```
Task: {brief task description}
Git diff (or work summary):
```
{diff or summary}
```

Score each dimension 1-10 with BRIEF evidence. Be critical — 5 is fine, 7 is good, 10 is exceptional.
Return ONE line per dimension in EXACT format:
- Correctness: X — {evidence}
- Tokens: X — {evidence}
- ErrPrev: X — {evidence}
- Skill: X — {evidence}
- Speed: X — {evidence}
- Breadth: X — {evidence}
```

## Parsing
Extract scores via regex: `-\s*(Correctness|Tokens|ErrPrev|Skill|Speed|Breadth):\s*(\d+)`
If <4 of 6 dims parseable → abort + retry.

## Error Handling
| Failure | Action |
|---------|--------|
| Subagent timeout/error | Retry once with simpler prompt. If retry fails → abort, log warning |
| <4 dims parseable | Mark unparseable, log as WARNING, skip audit |
| No auto-metrics baseline | Skip audit entirely, log: "no auto-metrics baseline found" |
| Double-trigger (same task re-audited) | Skip: "already audited: {audit_id}" |

## Integration
- When PASSED with avg ≥9 AND all gaps ≤1 → `mem_save(type="pattern")` for future reference
- When OVERSCORE → follow `immune-system` protocol (update behavior, propagate)
- Bitácora entry: `[audit] {date} — {result}: self={scores} audit={scores} gaps={deltas}`

## Anti-Patterns
- **Skip audit because "I'm sure"** → that's exactly when you need it most
- **Rationalize discrepancy** ("the subagent didn't understand") → if evidence is weak, accept the audit
- **Audit only easy tasks** → must trigger on complex tasks, not just convenient ones
- **Ignore parsing failures** → a subagent returning garbage IS a finding (prompt quality issue)
- **Re-audit same task to get better score** → defeats the purpose
