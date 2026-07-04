---
name: external-auditor
description: "Blind second-opinion audit via subagent. Run with !audit — not automatic."
license: Apache-2.0
metadata:
  tags: [engineering, quality]
  author: gentleman-vMK
  version: "1.2"
  changelog: "1.2: opt-in only (!audit). No longer auto-triggers after every task."
triggers: "!audit, external audit, blind review, 'second opinion', 'verificá mi auto-score'"
---
## TRIGGER
Only on explicit request (!audit) or user asking for audit.
Automatically recommended for HIGH-risk changes (8+ files, auth/storage/API).
Do NOT auto-run after every task — that added ~2000 tokens of ceremony per commit.

## FLOW
1. Gather `git diff` + scores | 2. Delegate subagent `general` with blind audit prompt | 3. Timeout/unparseable → retry once, abort 2nd fail | 4. Regex `-\s*(Correctness|Tokens|ErrPrev|Skill|Speed|Breadth):\s*(\d+)`. <4 dims → unparseable | 5. Compare `gap = abs(self - audit)` | 6. Double-save guard: if already saved + audit aligned → skip | 7. Gaps ≤1.5 all → PASSED · 1 dim >1.5 (self higher) → immune-system · 2+ → full stop · under-scored → update bias · mixed → immune on over-scored only | 8. Log: bitacora + `mem_save(type="audit")` | 9. Bias calibration: offset per dim, rolling 3, avg stored

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

## INTEGRATION
PASSED + avg≥9 + gaps≤1 → `mem_save(type="pattern")` | OVERSCORE → immune-system | Bitácora: `[audit] {date} — {result}: self={s} audit={a} gaps={g}`

## ANTI-PATTERNS
Skip "I'm sure" · Rationalize discrepancy · Audit only easy tasks · Ignore parsing failures · Re-audit for better score
