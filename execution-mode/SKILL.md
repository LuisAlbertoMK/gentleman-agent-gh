---
name: execution-mode
description: > Execution modes: quick/thorough/draft. Define speed vs control per task.
  Trigger: Starting task, "modo rápido", "modo thorough", "draft mode".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## MODES

| Mode | When | Depth | Artifacts | Verification |
|------|------|-------|-----------|-------------|
| **QUICK** | Simple bugfix, known pattern | Minimal | None/1-file | Tests only |
| **THOROUGH** | Complex feature, risky change | Full SDD | Spec+Design+Verify | Full gate |
| **DRAFT** | Exploration, prototyping | Light | Notes only | Skip |

## DECIDE
```
Task → Simple/known?→QUICK (code+tests+commit)
        Complex/risky?→THOROUGH (full SDD cycle)
        Unclear/exploring?→DRAFT (findings→ask→commit?)
```

## MODE RULES
**QUICK**: No SDD. Code+tests. Skip verify.
**THOROUGH**: Full SDD cycle. Every decision→Engram. Quality gate. PR with evidence.
**DRAFT**: Explore first. Present findings. No commit without user OK.

## COMMANDS
```bash
# "modo rápido" → QUICK | "modo thorough" → THOROUGH | "draft" → DRAFT
# Default: infer from complexity
```
