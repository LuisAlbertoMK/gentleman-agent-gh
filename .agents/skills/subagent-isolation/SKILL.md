---
name: subagent-isolation
description: "Clean context boundaries between agents - prevent hallucination cascades, cross-contamination, enforce error isolation."
triggers: "Subagent isolation, context boundaries"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2533
---

## When to Use
Maintain clean context boundaries between delegated agents —

## Isolation Rules
### Fresh context per delegation
Each `delegate` starts CLEAN. Include ALL context needed. Reference Engram IDs. File context -> paths + what to look for.

### No cross-contamination
| Rule | Why |
|------|-----|
| Never share state between subagents | Prevents hallucination cascades |
| Independent tool access per subagent | Error isolation |
| Serialize if B depends on A | Don't parallelize dependent work |

### Dependency declaration
Declare what subagent needs (file paths, Engram IDs). NOT: full history, system prompt.

### Result isolation
Each delegate returns OWN output. Conflicts -> raise to orchestrator. Subagents NEVER modify global state without explicit instructions.

### Preservation contract
Every delegation output MUST include this 4-field block AS-IS (never summarized):
```
## Decision Taken    ## Files Changed
## Key Findings      ## Nuance (what detail would be lost if summarized)
```

### Error boundaries
| Error | Action |
|-------|--------|
| Timeout | Retry once with cleaner prompt, then escalate |
| Wrong output | Log to Engram, re-delegate with corrected context |
| Hallucinates | Flag as contamination -> check isolation rules |

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
delivery-harness · command-wrapper · lean-context · context-watchdog · execution-mode

## Anti-Patterns
Share state between subagents · Parallelize dependent tasks · Skip 4-field contract · Keep full subagent output in context · No error isolation

---

> See [reference.md](docs/skills/subagent-isolation/reference.md) for extended details, examples, and detailed patterns.

