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
| "no catalogar tras el 2º error" | mismo error 2x sin entrada en catálogo | §3 DOCUMENT→ANTI-PATTERN-CATALOG.md mandatorio |
| "saltar inmunización en AGENTS.md" | catálogo sin regla AGENTS.md | DOCUMENT+IMMUNIZE: catálogo + AGENTS.md rule |
| "ignorar near-misses" | near-miss no documentado como asset | §1 DETECT near-miss → doc anyway |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: security-scanner | best-practices | quality-gate | auto-metrics | external-auditor

