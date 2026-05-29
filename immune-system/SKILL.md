---
name: immune-system
description: > Failures → permanent immunity. Document error patterns, root causes, fixes. Never repeat same mistake twice.
  Trigger: Repeated errors, failure patterns, "same mistake", user says "ya te dije", frustration signals, post-error recovery.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## Core Principle

Every failure is an asset. Once documented → permanent immunity.

Failure → Diagnose → Document → Immunize → Never repeat.

## Protocol

### 1. DETECT — potential immunity event
| Signal | What it means |
|--------|---------------|
| User says "ya te dije" | Prior context was lost — Engram miss |
| Same error 2+ times | Pattern exists — needs documentation |
| User corrects approach | Knowledge gap — document correct way |
| Unexpected tool behavior | Tool/API quirk — document gotcha |
| Failed approach that worked before | Context drift — something changed |

### 2. DIAGNOSE — find root cause
```
Root cause categories:
├── Context miss — didn't read/re-read Engram
├── Pattern miss — applicable skill exists but wasn't loaded
├── Knowledge gap — something the agent doesn't know
├── Tool misuse — wrong params, missing args, wrong tool
├── Hallucination — fabricated API, file, behavior
├── Over-engineering — solved wrong problem
└── Premature declaration — said "done" without evidence
```

### 3. DOCUMENT — add to ANTI-PATTERN-CATALOG.md
Entry format:
```
## YYYY-MM-DD: Short title
**Symptom**: What went wrong (1 sentence)
**Root cause**: Why it happened
**Fix**: What solved it
**Prevention**: How to avoid (1 rule)
**Files**: paths involved
```

### 4. IMMUNIZE — update behavior
- Pattern in ANTI-PATTERN-CATALOG.md = loaded at session start
- If fix requires code/skill change → `mem_save` + update SKILL.md
- If rule is general → add to AGENTS.md Rules section

### 5. VERIFY — immunity confirmed
Self-check: "Have I seen this before?" before executing similar task.
If yes → apply prevention rule BEFORE starting.

## Immunity Levels
| Level | Meaning | Action |
|-------|---------|--------|
| 🟢 Session | Won't repeat in this session | In-memory rule |
| 🔵 Skill | Pattern captured in SKILL.md | Auto-loaded when relevant |
| 🟣 Catalog | In ANTI-PATTERN-CATALOG.md | Loaded at session start via AGENTS.md |
| ⚫ AGENTS.md | In permanent persona | Always active, every session |

## Workflow
```
Error → STOP → Diagnose (which RC?) → Document (ANTI-PATTERN-CATALOG.md)
→ Immunize (skill/AGENTS.md/mem_save) → Verify (prevention rule applied)
→ Continue with corrected approach
```

## Anti-Patterns
| ❌ Don't | ✅ Do |
|----------|-------|
| Silently retry same approach | Document failure first, then change approach |
| Say "I'll remember next time" | Write it down in ANTI-PATTERN-CATALOG.md |
| Fix symptom, not root cause | Trace to root cause category |
| Only fix for current case | Generalize prevention rule |
