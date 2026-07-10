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
Explicit (!audit), user request, OR **required by close-session gate**. Auto-required when changes touch: security-scanner/, quality-gate/, auto-metrics/, external-auditor/, immune-system/, ANTI-PATTERN-CATALOG.md, ANTI-PATTERN-CHEATSHEET.md, .project.json. Also for HIGH-risk (8+ files, auth/storage/API). Skip trivial tasks (~2000 tok waste).

## FLOW
1. Gather `git diff` + scores | 2. Delegate subagent with blind prompt | 3. Timeout/unparseable → retry once, abort 2nd | 4. Regex `-\s*(Correctness|Tokens|ErrPrev|Skill|Speed|Breadth):\s*(\d+)`. <4 dims → unparseable | 5. Gap = `abs(self - audit)` | 6. Double-save guard | 7. All gaps ≤1.5 → PASSED · 1 dim >1.5 (self higher) → immune-system · 2+ dims >1.5 → full stop · under-scored → update bias · mixed → immune on over-scored only | 8. Log: bitacora + `mem_save(type="audit")` | 9. Bias calibration per dim, rolling 3, avg stored

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
**Gate**: `close-session.ps1` reports `needsAudit=true` → MUST run !audit and get PASSED before !close.

## ANTI-PATTERNS
Skip "I'm sure" · Rationalize discrepancy · Audit only easy tasks · Ignore parsing failures · Re-audit for better score

## BIAS CALIBRATION
Rolling from `.learnings/bias-calibration.json`:
```json
{ "offsets": { "Correctness": +1.5, ... }, "samples": 3 }
```
1. Check bitácora for today's `[audit]` entry. No audit → skip, warn. 2. Subtract avg offset per dim from self-score BEFORE thresholds. 3. Log: `"Bias corrected: {dim}={offset}"`. 4. <7→immune, ≥9→mem_save. 5. Append (self, audit), keep rolling 3.
- No data → OK. Offsets ±>3.0 → flag. Only runs during `!audit` or `!score`.

## Refs
auto-metrics · immune-system · bitacora · session-resume · quality-gate
