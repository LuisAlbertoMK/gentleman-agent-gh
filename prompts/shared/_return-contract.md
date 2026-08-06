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

## File-Based Output Fallback (MANDATORY when stdout may truncate)

If stdout is at risk of truncation (verbose verification, large output, multi-file tasks):
1. **Write the 4-field report to a file**: `docs/agentes/{task}/05-completion-report.md`
2. **Echo ONLY the file path** to stdout as your final message
3. **Never** rely on stdout alone for deliverable content — the orchestrator may receive an empty or truncated string

This prevents the "subagent completed but with no output" failure mode documented in `mejora-log.md:571`
and `RUNBOOK.md:26`.

---
*Canonical source for all agent return formats.*