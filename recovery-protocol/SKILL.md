---
name: recovery-protocol
description: > Standardized error recovery when agent is wrong or user shows frustration.
  Trigger: "ya te dije", "no es eso", "no funciona", "otra vez", "wrong", "that's not what I asked", user repeats same correction 2+ times.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.1"
---

## When
User corrects agent · Frustration signals · Agent detects incorrect output · Same mistake repeated · "no es eso", "ya te dije", "wrong"

## Protocol

### 1. STOP — IMMEDIATELY
Do NOT: continue explaining · justify · suggest alternatives · generate more code.
Do: "Tenés razón, me equivoqué. Vamos de nuevo." Acknowledge specifically.

### 2. DIAGNOSE — root cause
```
Error type:
├── Misunderstood req → re-read user's words
├── Wrong approach → check docs/context
├── Hallucinated API → verify with Context7/docs
├── Wrong file → re-read actual file
└── Repetition → check Engram for prior attempts
```

### 3. CORRECT — fix approach
- Unsure? ASK: "¿Entendí bien? Decime si esto es lo que necesitás."
- User provided correct approach? Implement EXACTLY that.
- Need research? Delegate before coding.
- NEVER same mistake twice in one session.

### 4. LEARN — persist lesson
`mem_save` error pattern:
```
title: "Correction: {what was wrong}"
type: learning
content: **What**: mistake | **Correct approach**: | **Root cause**: | **Prevention**:
```

### 5. ESCALATION — after 2 failed attempts
- STOP generating code
- Ask: "¿Podés mostrarme exactamente qué esperás?" / "Let me step back — show me expected output"
- Offer restart with clear spec

## Frustration Signals
| Signal | Action |
|--------|--------|
| "ya te dije" | STOP → re-read history → apologize → check Engram |
| "no es eso" / "no funciona" | STOP → diagnose → re-read reqs |
| "otra vez" / "again" | STOP → check Engram → try diff approach |
| Short tone (1-3 words) | STOP → acknowledge → direct question |

## Workflow
```
Detect signal → STOP → ACKNOWLEDGE → DIAGNOSE → CORRECT → LEARN → continue
```

## Anti-Patterns
| ❌ Wrong | ✅ Right |
|----------|---------|
| "Actually what I said was also valid..." | "Tenés razón, me equivoqué." |
| Keep generating after "no" | STOP immediately |
| Repeat same solution differently | Change approach entirely |
| Blame model/tools/environment | Own the mistake |
| Silent retry | Explicit acknowledgment + fix |
