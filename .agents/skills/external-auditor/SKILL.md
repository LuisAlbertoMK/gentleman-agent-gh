---
name: external-auditor
description: "Blind second-opinion audit via subagent. Run with !audit — not automatic."
triggers: "!audit, external audit, blind review, 'second opinion', 'verificá mi auto-score'"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2525
---
## When to Use
Explicit (!audit), user request, OR required by close-session gate. Auto-required when changes touch: security-scanner/, quality-gate/, auto-metrics/, external-auditor/, immune-system/, ANTI-PATTERN-CATALOG.md, .project.json. Also HIGH-risk (8+ files, auth/storage/API). Skip trivial tasks (~2000 tok waste).
## FLOW
1. Gather `git diff` + scores | 2. Delegate subagent blind prompt | 3. Timeout/unparseable → retry 1, abort 2nd | 4. Regex `-\s*(Correctness|Tokens|ErrPrev|Skill|Speed|Breadth):\s*(\d+)`; <4 dims → unparseable | 5. Gap = `abs(self - audit)` | 6. Double-save guard | 7. All gaps ≤1.5 → PASSED · 1 dim >1.5 (self higher) → immune-system · 2+ dims >1.5 → full stop · under-scored → update bias · mixed → immune on over-scored only | 8. Log: bitacora + `mem_save(type="audit")` | 9. Bias calibration per dim, rolling 3, avg stored.
## INTEGRATION
PASSED + avg≥9 + gaps≤1 → `mem_save(type="pattern")` | OVERSCORE → immune-system | Bitácora: `[audit] {date} — {result}: self={s} audit={a} gaps={g}`. Gate: `close-session.ps1` → `needsAudit=true` → !audit + PASSED before !close.
## BIAS CALIBRATION
Rolling from `.learnings/bias-calibration.json`:
```json
{ "offsets": { "Correctness": +1.5, ... }, "samples": 3 }
```
1. Bitácora `[audit]` today; none → skip, warn. 2. Subtract avg offset per dim BEFORE thresholds. 3. Log `Bias corrected: {dim}={offset}`. 4. <7→immune, ≥9→mem_save. 5. Append (self, audit), rolling 3. No data → OK. Offsets ±>3.0 → flag. Only during `!audit`/`!score`.
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
auto-metrics · immune-system · bitacora · session-resume · quality-gate
## Reference
> docs/skills/external-auditor/reference.md

