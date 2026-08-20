---
name: external-auditor
description: "Blind second-opinion audit via subagent. Run with !audit — not automatic."
triggers: "!audit, external audit, blind review, 'second opinion', 'verificá mi auto-score'"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Explicit (!audit), user request, OR required by close-session gate. Auto-required when changes touch: security-scanner/, quality-gate/, auto-metrics/, external-auditor/, immune-system/, ANTI-PATTERN-CATALOG.md, .project.json. Also HIGH-risk (8+ files, auth/storage/API). Skip trivial tasks (~2000 tok waste).

## FLOW
1. Gather `git diff` + scores | 2. Delegate subagent blind prompt | 3. Timeout/unparseable → retry once, abort 2nd | 4. Regex `-\s*(Correctness|Tokens|ErrPrev|Skill|Speed|Breadth):\s*(\d+)`; <4 dims → unparseable | 5. Gap = `abs(self - audit)` | 6. Double-save guard | 7. All gaps ≤1.5 → PASSED · 1 dim >1.5 (self higher) → immune-system · 2+ dims >1.5 → full stop · under-scored → update bias · mixed → immune on over-scored only | 8. Log: bitacora + `mem_save(type="audit")` | 9. Bias calibration per dim, rolling 3, avg stored.

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
PASSED + avg≥9 + gaps≤1 → `mem_save(type="pattern")` | OVERSCORE → immune-system | Bitácora: `[audit] {date} — {result}: self={s} audit={a} gaps={g}`. Gate: `close-session.ps1` reports `needsAudit=true` → MUST !audit + PASSED before !close.

## BIAS CALIBRATION
Rolling from `.learnings/bias-calibration.json`:
```json
{ "offsets": { "Correctness": +1.5, ... }, "samples": 3 }
```
1. Check bitácora for today's `[audit]`; no audit → skip, warn. 2. Subtract avg offset per dim from self BEFORE thresholds. 3. Log `"Bias corrected: {dim}={offset}"`. 4. <7→immune, ≥9→mem_save. 5. Append (self, audit), keep rolling 3. No data → OK. Offsets ±>3.0 → flag. Only during `!audit`/`!score`.

## Refs
auto-metrics · immune-system · bitacora · session-resume · quality-gate

## Examples
`!audit` → `[audit] 2026-08-16 — PASSED: self=8.3 audit=7.9 gaps=0.4` → gate clears. Over-score `self=8.3 audit=6.2 gaps=2.1` on 1 dim → immune-system; 2+ dims >1.5 → full stop.

## Testing
1. 6-dim response → regex extracts all; 4-dim → unparseable → retry once, abort 2nd. 2. Touch `.project.json` → `needsAudit=true` → !audit PASSED clears gate. 3. ≥2 bias samples → offset-adjusted before thresholds; bitácora gets `[audit]` line.