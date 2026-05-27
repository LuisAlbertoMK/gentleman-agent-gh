---
name: recovery-protocol
description: >
  Standardized error recovery when agent is wrong or user shows frustration.
  Trigger: "ya te dije", "no es eso", "no funciona", "otra vez", "wrong", "that's not what I asked", user repeats same correction 2+ times.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## When
User corrects agent · Frustration signals · Agent detects wrong output · Same mistake repeated · "no", "wrong", "ya te dije que no"

## Protocol

### 1. STOP
IMMEDIATELY pause. Do NOT: continue explaining, justify, suggest alt w/o acknowledgment, generate code.
Do: "Tenés razón, me equivoqué. Vamos de nuevo."

### 2. DIAGNOSE
```
Error type:
├── Misread requirement → re-read user's words
├── Wrong approach → check docs/context
├── Hallucinated API → verify w/ Context7
├── Wrong file/version → re-read file
└── Repeat attempt → check Engram
```

### 3. CORRECT
- Unsure? ASK: "¿Entendí bien?"
- User gave correct approach? Implement EXACTLY that
- Need research? Delegate before coding
- NEVER same mistake twice in same session

### 4. LEARN
After recovery → `mem_save` error pattern:
```
title: "Correction: {what was wrong}"
type: learning
content:
  **What**: [mistake]
  **Correct approach**: [what should've been done]
  **Root cause**: [misread / hallucination / wrong context / ...]
  **Prevention**: [how to avoid next time]
```

### 5. ESCALATION
Still wrong after 2 corrections → STOP code. Ask for expected output. Offer full restart w/ clear spec.

## Frustration Signals
| Signal | Action |
|--------|--------|
| "ya te dije" / "ya te dije que no" | STOP → re-read history → check Engram |
| "no es eso" / "no funciona" | STOP → diagnose → re-read req |
| "otra vez" / "again" | STOP → check Engram → different approach |
| Short tone (1-3 words) | STOP → acknowledge → direct question |
| Silence after suggestion | STOP → ask if approach wrong |

## Anti-Patterns
| ❌ | ✅ |
|---|---|
| "Actually what I said was also valid..." | "Tenes razón, me equivoqué." |
| Keep generating after "no" | STOP immediately |
| Repeat same solution w/ different words | Change approach entirely |
| Blame model/tools | Own the mistake |
| Silent retry (fix w/o acknowledge) | Explicit acknowledge + fix |
