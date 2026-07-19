# Return Contract — Canonical

Every delegation output MUST include this 4-field block AS-IS (never summarized):

```
## Decision Taken
[One sentence: what was decided/done]

## Files Changed
[list of files modified, or "None (read-only analysis)"]

## Key Findings
1. [SEVERITY] Finding — Evidence — Recommendation
2. ...

## Nuance
[What would be lost in summary — subtleties, edge cases, tradeoffs]
```

## Rules
- Preserve the 4-field block exactly — never merge or summarize fields
- `Decision Taken` = one sentence, max 30 words
- `Files Changed` = exact paths, or "None" for read-only work
- `Key Findings` = numbered list with SEVERITY (CRITICAL/HIGH/MEDIUM/LOW)
- `Nuance` = the "last mile" that summary would lose

## Legacy Format (deprecated)
The old 5-field format (`status | summary | files_changed | verification | escalation`) from `_core-behavior-gp.md` is superseded by this contract. All agents should use the 4-field block above.

## Enforcement
- `subagent-isolation` skill enforces this contract
- `delivery-harness` skill requires this format in delegation output
- Orchestrator synthesizes from this format, never from raw subagent output

---
*Canonical source for all agent return formats.*
