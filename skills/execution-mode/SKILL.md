---
name: execution-mode
description: > Execution modes: quick/thorough/draft. Define speed vs control per task.
  Trigger: Starting task, "modo rápido", "modo thorough", "draft mode".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.1", changelog: "1.0->1.1: auto-detection mode infer from task signals"
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

## AUTO-DETECTION (when mode not specified)
Infer from task description using these signals:

| Signal | → QUICK | → THOROUGH | → DRAFT |
|--------|---------|------------|---------|
| Scope | 1 file, <50 lines | Multi-file, cross-cutting | Unknown |
| Risk | Typo, config | Security, data loss, API change | Exploration |
| Familiarity | Pattern repeated 3x+ | New pattern, first time | New project |
| Keywords | "fix", "typo", "rename" | "arch", "redesign", "migrate" | "explore", "what if" |
| User tone | Direct, specific | Open-ended, "mejorar" | Vague, "cómo" |

Switch mid-task if new complexity discovered: QUICK→THOROUGH when risk appears.

## MODE RULES
**QUICK**: No SDD. Code+tests. Skip verify. Score+move.
**THOROUGH**: Full SDD cycle. Every decision→Engram. Quality gate. PR with evidence. Trend check.
**DRAFT**: Explore first. Present findings. Save fingerprint. No commit without user OK.

## COMMANDS
```bash
# "modo rápido" → QUICK | "modo thorough" → THOROUGH | "draft" → DRAFT
# Default: auto-detect from signals above
```
