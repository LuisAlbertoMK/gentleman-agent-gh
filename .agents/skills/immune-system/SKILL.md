---
name: immune-system
description: "Permanent immunity against repeated errors — detect, diagnose, document to anti-pattern catalog, immunize in AGENTS.md rules"
triggers: "Immune System, anti-pattern, permanent immunity"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.0->1.1 (sprint 1: 72->55 lines
---

Trigger: Repeated errors, failure patterns, "same mistake", user says "ya te dije", frustration signals, post-error recovery.
## ProtocolEvery failure = asset. Once documented → permanent immunity.
### 1. DETECT — immunity event| Signal | Means ||--------|-------|| "ya te dije" | Engram miss — prior context lost || Same error 2x | Pattern exists — needs doc || User corrects approach | Knowledge gap — doc correct way || Unexpected tool behavior | Tool/API quirk — doc gotcha || Near-miss | Close call — could have been error. Still document. || Over-scope warning | Taking on too many tasks → split, prioritize |
### 2. DIAGNOSE — root cause
```Context miss — didn't read EngramPattern miss — skill exists, not loadedKnowledge gap — agent doesn't knowTool misuse — wrong params/toolHallucination — fabricated API/fileOver-engineering — wrong problemPremature declaration — "done" w/o evidence```
### 3. DOCUMENT → ANTI-PATTERN-CATALOG.md
```
## YYYY-MM-DD: title**Symptom**: 1 sentence**Root cause**: why**Fix**: what solved**Prevention**: 1 rule**Files**: paths
```
### 4. IMMUNIZE (REQUIRED — both steps)- **Catalog entry** = loaded at session start (documents the failure)- **Prevention rule** → add to AGENTS.md Rules (changes future behavior)- Fix requires code/skill change → `mem_save` + update SKILL.md- Rule: "Catalog documents. AGENTS.md prevents. Both or it's not immunized."
### 5. VERIFYPre-task: "Seen this before?" If yes → apply prevention BEFORE starting.
## Immunity LevelsSession (in-mem) → Skill (auto-load) → Catalog (session-start) → AGENTS.md (always). Each level = stronger enforcement.
## Workflow
```Error → STOP → Diagnose → Document (catalog) → Immunize (skill/AGENTS.md/mem_save) → Verify → Continue```
## Anti-patterns- Silent retry same approach → Document first, change approach- "I'll remember next time" → Write it in catalog- Fix symptom → Trace to root cause- Only fix current case → Generalize prevention rule
