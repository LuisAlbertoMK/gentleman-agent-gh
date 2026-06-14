---
name: immune-system
description: >  immune-system skill
triggers: "Immune System, anti-pattern, permanent immunity"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1", changelog: "1.0->1.1 (sprint 1: 72->55 lines, -23.6%, condensed Immunity Levels table, inlined Anti-patterns)"
---

Trigger: Repeated errors, failure patterns, "same mistake", user says "ya te dije", frustration signals, post-error recovery.
## ProtocolEvery failure = asset. Once documented â†’ permanent immunity.
### 1. DETECT â€” immunity event| Signal | Means ||--------|-------|| "ya te dije" | Engram miss â€” prior context lost || Same error 2x | Pattern exists â€” needs doc || User corrects approach | Knowledge gap â€” doc correct way || Unexpected tool behavior | Tool/API quirk â€” doc gotcha || Near-miss | Close call â€” could have been error. Still document. || Over-scope warning | Taking on too many tasks â†’ split, prioritize |
### 2. DIAGNOSE â€” root cause
```Context miss â€” didn't read EngramPattern miss â€” skill exists, not loadedKnowledge gap â€” agent doesn't knowTool misuse â€” wrong params/toolHallucination â€” fabricated API/fileOver-engineering â€” wrong problemPremature declaration â€” "done" w/o evidence```
### 3. DOCUMENT â†’ ANTI-PATTERN-CATALOG.md
```
## YYYY-MM-DD: title**Symptom**: 1 sentence**Root cause**: why**Fix**: what solved**Prevention**: 1 rule**Files**: paths
```
### 4. IMMUNIZE (REQUIRED â€” both steps)- **Catalog entry** = loaded at session start (documents the failure)- **Prevention rule** â†’ add to AGENTS.md Rules (changes future behavior)- Fix requires code/skill change â†’ `mem_save` + update SKILL.md- Rule: "Catalog documents. AGENTS.md prevents. Both or it's not immunized."
### 5. VERIFYPre-task: "Seen this before?" If yes â†’ apply prevention BEFORE starting.
## Immunity LevelsSession (in-mem) â†’ Skill (auto-load) â†’ Catalog (session-start) â†’ AGENTS.md (always). Each level = stronger enforcement.
## Workflow
```Error â†’ STOP â†’ Diagnose â†’ Document (catalog) â†’ Immunize (skill/AGENTS.md/mem_save) â†’ Verify â†’ Continue```
## Anti-patterns- Silent retry same approach â†’ Document first, change approach- "I'll remember next time" â†’ Write it in catalog- Fix symptom â†’ Trace to root cause- Only fix current case â†’ Generalize prevention rule
