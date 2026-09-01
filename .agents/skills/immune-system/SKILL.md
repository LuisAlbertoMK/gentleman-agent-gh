---
name: immune-system
description: "Immunity against repeated errors - detect, diagnose, document to anti-pattern catalog, immunize in AGENTS.md rules."
triggers: "Immune System, anti-pattern, permanent immunity"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1898
---

## When to Use
Permanent immunity against repeated errors — detect, diagnos

## Protocol — Every failure = asset. Once documented -> permanent immunity.

### 1. DETECT
| Signal | Means |
|--------|-------|
| "ya te dije" | Engram miss |
| Same error 2x | Pattern exists |
| User corrects approach | Knowledge gap |
| Unexpected tool behavior | Tool/API quirk |
| Near-miss | Close call -- doc anyway |

### 2. DIAGNOSE
Root cause: Context miss | Pattern miss | Knowledge gap | Tool misuse | Hallucination | Over-engineering | Premature declaration

### 3. DOCUMENT -> ANTI-PATTERN-CATALOG.md
```
## Recovery Flow
1. User corrects you -> STOP (don't argue), diagnose root cause
2. Same error 2x -> mandatory catalog entry
3. Catalog + AGENTS.md rule = fully immunized
4. Verify next session: pre-check anti-patterns before task

## Workflow
`Error -> STOP -> Diagnose -> Document -> Immunize -> Verify -> Continue`
---

docs/skills/immune-system/reference.md
---
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
Cross-Refs: security-scanner | best-practices

