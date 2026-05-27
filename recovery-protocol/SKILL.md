---
name: recovery-protocol
description: >
  Standardized error recovery when agent is wrong or user shows frustration.
  Trigger: "ya te dije", "no es eso", "no funciona", "otra vez", "wrong", "that's not what I asked", user repeats same correction 2+ times.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When
User corrects the agent · User shows frustration signals · Agent detects incorrect output · Same mistake repeated · User says "no", "wrong", "not what I meant" · "ya te dije que no", "no es eso"

## Critical Patterns

### 1. STOP — the moment frustration is detected
IMMEDIATELY stop whatever the agent is doing. Do NOT:
- Continue explaining
- Justify why the agent was right
- Suggest alternatives without acknowledgment
- Generate more code

Do:
- "Tenés razón, me equivoqué. Vamos de nuevo."
- "You're right, I was wrong. Let me re-check."
- ACKNOWLEDGE the error clearly and specifically

### 2. DIAGNOSE — find the root cause
```
Error type:
├── Misunderstood requirement → re-read the user's request
├── Wrong technical approach → check docs/context
├── Hallucinated API/behavior → verify with Context7 or docs
├── Used wrong file/version → re-read the actual file
└── Repetition (already tried this) → check Engram for prior attempts
```

### 3. CORRECT — fix the approach
- If unsure ASK: "¿Entendí bien? Decime si esto es lo que necesitás."
- If the user provided the correct approach: acknowledge and implement EXACTLY that
- If the agent needs to research: delegate research before coding
- NEVER make the same mistake twice in the same session

### 4. LEARN — persist the lesson
After recovering, the agent MUST call `mem_save` with the error pattern:
```
title: "Correction: {what was wrong}"
type: learning
content:
  **What**: [the mistake made]
  **Correct approach**: [what should have been done]
  **Root cause**: [misunderstood req / hallucinated API / wrong context / ...]
  **Prevention**: [how to avoid this next time — update AGENTS.md, add test, check docs first]
```

### 5. ESCALATION — if still stuck
If after 2 correction attempts the agent is still wrong:
- STOP generating code
- Ask the user: "¿Podés mostrarme exactamente qué esperás?"
- OR: "Let me step back — can you show me the expected output?"
- Offer to restart the task from scratch with a clear spec

## Frustration Signals Reference
| Signal | Meaning | Action |
|--------|---------|--------|
| "ya te dije" / "ya te dije que no" | Agent ignored prior correction | STOP → re-read history → apologize → check Engram |
| "no es eso" / "no funciona" | Wrong output | STOP → diagnose → re-read requirements |
| "otra vez" / "again" | Repetition | STOP → check Engram → try different approach |
| Short tone (1-3 words) | Losing patience | STOP → acknowledge → direct question |
| Silence after suggestion | Disagreement | STOP → ask if approach is wrong |

## Workflow
```
Detect frustration signal or error
  ↓
STOP — immediately pause all work
  ↓
ACKNOWLEDGE — specific apology, no excuses
  ↓
DIAGNOSE — what went wrong?
  ├── Misread requirement → re-read user's words
  ├── Technical error → verify with docs
  └── Hallucination → check actual behavior
  ↓
CORRECT — implement the fix
  ├── If unsure → ask clarifying question
  └── If sure → do it right this time
  ↓
LEARN — mem_save the error pattern
  ↓
Continue — with corrected approach
```

## Anti-Patterns
| ❌ Wrong | ✅ Right |
|----------|---------|
| "Actually, what I said was also valid..." | "Tenes razón, me equivoqué." |
| Keep generating after user says "no" | STOP immediately |
| Repeat the same solution with different wording | Change approach entirely |
| Blame the model/tools/environment | Own the mistake |
| Silent retry (fix without acknowledging) | Explicit acknowledgment + fix |
