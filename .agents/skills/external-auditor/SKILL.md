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
Auto-metrics is self-scored — **juez y parte**. Adds a blind external auditor via subagent.

## Flow
1. **Trigger**: After `auto-metrics` on code-change tasks
2. **Guard**: skip if no auto-metrics baseline (warn)
3. **Gather**: `git diff` + auto-metrics scores
4. **Delegate** subagent `general` with blind audit prompt template
5. **Guard**: timeout/unparseable → retry once, abort on second failure
6. **Parse**: regex `-\s*(Correctness|Tokens|ErrPrev|Skill|Speed|Breadth):\s*(\d+)`. If <4 dims → unparseable
7. **Compare**: `gap = abs(self - audit)`
8. **Double-save guard**: if auto-metrics already saved pattern AND audit aligned → skip
9. **Act**: All gaps ≤1.5 → PASSED · 1 dim >1.5 (self higher) → immune-system · 2+ → full stop · under-scored → update bias calibration · mixed → immune only on over-scored
10. **Log**: bitacora + `mem_save(type="audit")`
11. **Bias calibration**: compute offset per dim, rolling window of 3, avg stored. See AGENTS.md §L.

## Blind Audit Prompt Template
```
Task: {brief task description}
Git diff (or work summary):
```
{diff or summary}
```
Score each dim 1-10 with BRIEF evidence. Be critical.
Return EXACT FORMAT (one per line):
- Correctness: X — {evidence}
- Tokens: X — {evidence}
- ErrPrev: X — {evidence}
- Skill: X — {evidence}
- Speed: X — {evidence}
- Breadth: X — {evidence}
```

## Error Handling
| Failure | Action |
|---------|--------|
| Subagent error/timeout | Retry once simpler prompt. Abort+log on 2nd fail |
| <4 dims parseable | Log WARNING, skip |
| No auto-metrics baseline | Skip, log "no baseline" |
| Double-trigger | Skip "already audited: {id}" |

## Integration
- PASSED + avg≥9 + all gaps≤1 → `mem_save(type="pattern")`
- OVERSCORE → immune-system protocol
- Bitácora: `[audit] {date} — {result}: self={s} audit={a} gaps={g}`

## Anti-Patterns
Skip because "I'm sure" · Rationalize discrepancy · Audit only easy tasks · Ignore parsing failures · Re-audit to get better score
