---
name: immune-system
description: "Immunity against repeated errors - detect, diagnose, document to anti-pattern catalog, immunize in AGENTS.md rules."
triggers: "Immune System, anti-pattern, permanent immunity"
changelog: docs/ciclos/cycle28-20260815.md
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
## YYYY-MM-DD: title
**Symptom**: | **Root cause**: | **Fix**: | **Prevention**: 1 rule | **Files**: paths
```

### 4. IMMUNIZE (both required)
- Catalog entry = loaded at session start (documents failure)
- Prevention rule -> AGENTS.md (changes behavior)
- Code/skill change -> `mem_save` + update SKILL.md
- Cross-project: also `mem_save(topic_key="pattern/{name}", type="pattern", scope="personal")` so wisdom loader can retrieve it
- Rule: "Catalog documents. AGENTS.md prevents. Both or not immunized."

#### Cross-Project Save Format
When saving to Engram for cross-project retrieval, use:
```
title: "pattern: {symptom}"
type: "pattern"
scope: "personal"
content: "**Domain**: {domain}\n**Symptom**: {symptom}\n**Root cause**: {root_cause}\n**Fix**: {fix}\n**Prevention**: {prevention}"
topic_key: "pattern/{normalized-title}"
```

### 5. VERIFY
Pre-task: "Seen this before?" If yes -> apply prevention BEFORE starting.

## Recovery Flow
1. User corrects you -> STOP (don't argue), diagnose root cause
2. Same error 2x -> mandatory catalog entry
3. Catalog + AGENTS.md rule = fully immunized
4. Verify next session: pre-check anti-patterns before task

## Workflow
`Error -> STOP -> Diagnose -> Document -> Immunize -> Verify -> Continue`

## Anti-patterns
- Silent retry -> Document first | "I'll remember" -> Write catalog
- Fix symptom -> Trace root cause | Fix current case -> Generalize prevention

## Refs
dreaming · recovery-protocol · cross-project-wisdom · session-resume · bitacora
