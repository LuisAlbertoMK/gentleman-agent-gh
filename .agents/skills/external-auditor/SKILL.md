---
name: external-auditor
description: "Blind second-opinion audit via subagent. Catches overconfidence in auto-metrics self-score."
license: Apache-2.0
metadata:
  tags: [engineering, quality]
  author: gentleman-vMK
  version: "1.1"
triggers: after auto-metrics (code changes), "external audit", "blind review", "verificá mi auto-score", "second opinion"
---
## FLOW
1. Trigger after `auto-metrics` on code-change tasks | 2. Skip if no auto-metrics baseline (warn) | 3. Gather `git diff` + scores | 4. Delegate subagent `general` with blind audit prompt | 5. Timeout/unparseable → retry once, abort 2nd fail | 6. Regex `-\s*(Correctness|Tokens|ErrPrev|Skill|Speed|Breadth):\s*(\d+)`. <4 dims → unparseable | 7. Compare `gap = abs(self - audit)` | 8. Double-save guard: if already saved + audit aligned → skip | 9. Gaps ≤1.5 all → PASSED · 1 dim >1.5 (self higher) → immune-system · 2+ → full stop · under-scored → update bias · mixed → immune on over-scored only | 10. Log: bitacora + `mem_save(type="audit")` | 11. Bias calibration: offset per dim, rolling 3, avg stored (AGENTS.md §L)
## BLIND AUDIT PROMPT
```
Task: {brief}
Git diff:
{diff}
Score 1-10 with BRIEF evidence. Be critical.
Return one per line:
- Correctness: X — {evidence}
- Tokens: X — {evidence}
- ErrPrev: X — {evidence}
- Skill: X — {evidence}
- Speed: X — {evidence}
- Breadth: X — {evidence}
```
## ERROR HANDLING
Subagent error/timeout → retry simpler prompt, abort+log 2nd fail | <4 dims → WARNING, skip | No baseline → skip | Double-trigger → skip "already audited: {id}"
## INTEGRATION
PASSED + avg≥9 + gaps≤1 → `mem_save(type="pattern")` | OVERSCORE → immune-system | Bitácora: `[audit] {date} — {result}: self={s} audit={a} gaps={g}`
## ANTI-PATTERNS
Skip "I'm sure" · Rationalize discrepancy · Audit only easy tasks · Ignore parsing failures · Re-audit for better score
