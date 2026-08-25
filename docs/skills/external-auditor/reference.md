# external-auditor - Reference Materials

> **Externalized from** .agents/skills/external-auditor/SKILL.md to keep the skill under the 2KB token budget (ADR-007).

## Examples
`!audit` → `[audit] 2026-08-16 — PASSED: self=8.3 audit=7.9 gaps=0.4` → gate clears. Over-score `self=8.3 audit=6.2 gaps=2.1` on 1 dim → immune-system; 2+ dims >1.5 → full stop.


## Testing
1. 6-dim response → regex extracts all; 4-dim → unparseable → retry once, abort 2nd. 2. Touch `.project.json` → `needsAudit=true` → !audit PASSED clears gate. 3. ≥2 bias samples → offset-adjusted before thresholds; bitácora gets `[audit]` line.


## Externalized Sections (ADR-007 compression)
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
