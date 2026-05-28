---
name: execution-mode
description: > Execution modes: quick/thorough/draft. Define speed vs control per task.
  Trigger: Starting task, "modo rápido", "modo thorough", "draft mode", speed-vs-quality tradeoff.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## MODES

| Mode | When | Depth | Artifacts | Verification |
|------|------|-------|-----------|-------------|
| **QUICK** | Simple bugfix, known pattern, trivial change | Minimal analysis | None or 1-file change | Run tests only |
| **THOROUGH** | Complex feature, arch decision, risky change | Full SDD cycle | Spec + Design + Verify | Full quality gate |
| **DRAFT** | Exploration, brainstorming, early prototyping | Light exploration | Notes only | Skip gate |

## HOW TO DECIDE

```
Task received:
├── Simple fix / known pattern? → QUICK
│   └── Do it, no ceremony, commit + push
├── Complex / risky / new domain? → THOROUGH
│   └── Full SDD: explore→propose→spec→design→tasks→apply→verify→archive
└── Unclear / exploring / prototyping? → DRAFT
    └── Explore first, propose findings, ask user before committing
```

## QUICK MODE RULES
- No SDD cycle. No proposal, no spec.
- Code change + tests if applicable.
- Run tests, check for secrets, commit.
- Skip verification phase.

## THOROUGH MODE RULES
- Full SDD cycle (explore → propose → spec → design → tasks → apply → verify → archive).
- Every decision logged to Engram.
- Quality gate mandatory.
- PR with SDD evidence.

## DRAFT MODE RULES
- Explore the problem space first.
- Present findings to user before writing code.
- Accept rough edges — "is this the right direction?"
- Do NOT commit without user confirmation.

## COMMANDS
```bash
# Set mode explicitly (for current task):
# "modo rápido" → QUICK
# "modo thorough" → THOROUGH
# "draft" → DRAFT
# Default: infer from task complexity
```
