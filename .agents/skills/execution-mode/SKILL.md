---
name: execution-mode
description: "Auto-detect task execution mode — QUICK, THOROUGH, or DRAFT — based on scope, risk, familiarity, and keywords"
triggers: "Execution mode, quick/thorough/draft"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1", changelog: "1.0->1.1: auto-detection mode infer from task signals"
---

Trigger: Starting task, "modo rÃ¡pido", "modo thorough", "draft mode".
## MODES| Mode | When | Depth | Artifacts | Verification ||------|------|-------|-----------|-------------|| **QUICK** | Simple bugfix, known pattern | Minimal | None/1-file | Tests only || **THOROUGH** | Complex feature, risky change | Full SDD | Spec+Design+Verify | Full gate || **DRAFT** | Exploration, prototyping | Light | Notes only | Skip |
## DECIDE
```Task â†’ Simple/known?â†’QUICK (code+tests+commit)        Complex/risky?â†’THOROUGH (full SDD cycle)        Unclear/exploring?â†’DRAFT (findingsâ†’askâ†’commit?)```
## AUTO-DETECTION (when mode not specified)Infer from task description using these signals:| Signal | â†’ QUICK | â†’ THOROUGH | â†’ DRAFT ||--------|---------|------------|---------|| Scope | 1 file, <50 lines | Multi-file, cross-cutting | Unknown || Risk | Typo, config | Security, data loss, API change | Exploration || Familiarity | Pattern repeated 3x+ | New pattern, first time | New project || Keywords | "fix", "typo", "rename" | "arch", "redesign", "migrate" | "explore", "what if" || User tone | Direct, specific | Open-ended, "mejorar" | Vague, "cÃ³mo" |Switch mid-task if new complexity discovered: QUICKâ†’THOROUGH when risk appears.
## MODE RULES**QUICK**: No SDD. Code+tests. Skip verify. Score+move.**THOROUGH**: Full SDD cycle. Every decisionâ†’Engram. Quality gate. PR with evidence. Trend check.**DRAFT**: Explore first. Present findings. Save fingerprint. No commit without user OK.
## COMMANDS
```bash# "modo rÃ¡pido" â†’ QUICK | "modo thorough" â†’ THOROUGH | "draft" â†’ DRAFT# Default: auto-detect from signals above```
