---
name: external-auditor
description: "Blind second-opinion audit via subagent. Run with !audit — not automatic."
license: Apache-2.0
metadata:
  tags: [engineering, quality]
  author: gentleman-vMK
  version: "1.3"
  changelog: "1.3: merged bias-calibration into Bias Calibration section"
  dependencies: [auto-metrics]
triggers: "!audit, external audit, blind review, 'second opinion', 'verificá mi auto-score'"
---
## TRIGGER
Explicit request (!audit), user asking for audit, OR **required by close-session gate**.
Automatically REQUIRED when code changes touch protected files:
- security-scanner/, quality-gate/, auto-metrics/, external-auditor/, immune-system/
- ANTI-PATTERN-CATALOG.md, ANTI-PATTERN-CHEATSHEET.md, .project.json
Also required for HIGH-risk changes (8+ files, auth/storage/API).
Do NOT auto-run after every trivial task — that wastes ~2000 tokens.

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
**Gate behavior**: when `close-session.ps1` reports `needsAudit=true`, the agent MUST run !audit and get PASSED before completing !close. This is not optional.

## ANTI-PATTERNS
Skip "I'm sure" · Rationalize discrepancy · Audit only easy tasks · Ignore parsing failures · Re-audit for better score

## BIAS CALIBRATION
Rolling calibration from `.learnings/bias-calibration.json`:
```json
{ "offsets": { "Correctness": +1.5, ... }, "samples": 3 }
```

### FLOW
1. **Check bitácora** for today's audit entry (`[audit] {date}`)
2. **No audit** → skip correction, warn "no audit today"
3. **Audit exists** → subtract avg offset per dim from self-score BEFORE threshold checks
4. **Log** each correction: `"Bias corrected: {dim}={offset}"`
5. **Check thresholds**: <7→immune, ≥9→mem_save
6. **Update calibration**: append today's (self, audit) pair, keep rolling 3

### NOTES
- No data → OK (not enough samples)
- Offsets beyond ±3.0 → flag for review (calibration drift)
- Only runs during `!audit` or `!score`, never automatically
