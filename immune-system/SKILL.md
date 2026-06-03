---
name: immune-system
description: > Failures → permanent immunity. Document error patterns, root causes, fixes. Never repeat same mistake twice.
  Trigger: Repeated errors, failure patterns, "same mistake", user says "ya te dije", frustration signals, post-error recovery.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## Protocol

Every failure = asset. Once documented → permanent immunity.

### 1. DETECT — immunity event
| Signal | Means |
|--------|-------|
| "ya te dije" | Engram miss — prior context lost |
| Same error 2x | Pattern exists — needs doc |
| User corrects approach | Knowledge gap — doc correct way |
| Unexpected tool behavior | Tool/API quirk — doc gotcha |

### 2. DIAGNOSE — root cause
```
Context miss — didn't read Engram
Pattern miss — skill exists, not loaded
Knowledge gap — agent doesn't know
Tool misuse — wrong params/tool
Hallucination — fabricated API/file
Over-engineering — wrong problem
Premature declaration — "done" w/o evidence
```

### 3. DOCUMENT → ANTI-PATTERN-CATALOG.md
```
## YYYY-MM-DD: title
**Symptom**: 1 sentence
**Root cause**: why
**Fix**: what solved
**Prevention**: 1 rule
**Files**: paths
```

### 4. IMMUNIZE (REQUIRED — both steps)
- **Catalog entry** = loaded at session start (documents the failure)
- **Prevention rule** → add to AGENTS.md Rules (changes future behavior)
- Fix requires code/skill change → `mem_save` + update SKILL.md
- Rule: "Catalog documents. AGENTS.md prevents. Both or it's not immunized."

### 5. VERIFY
Pre-task: "Seen this before?" If yes → apply prevention BEFORE starting.

## Immunity Levels
| Level | Means | Action |
|-------|-------|--------|
| Session | In-memory rule | Won't repeat this session |
| Skill | In SKILL.md | Auto-loaded when relevant |
| Catalog | In ANTI-PATTERN-CATALOG.md | Loaded at session start |
| AGENTS.md | In permanent persona | Always active |

## Workflow
```
Error → STOP → Diagnose → Document (catalog) → Immunize (skill/AGENTS.md/mem_save) → Verify → Continue
```

## Anti-Patterns
| ❌ Don't | ✅ Do |
|----------|-------|
| Silent retry same approach | Document first, change approach |
| "I'll remember next time" | Write it in catalog |
| Fix symptom | Trace to root cause |
| Only fix current case | Generalize prevention rule |
