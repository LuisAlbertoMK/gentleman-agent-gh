---
name: recovery-protocol
description: "Stop-diagnose-correct-learn protocol — handle agent errors and frustration systematically"
triggers: "Recovery, 'no es eso', frustration, error correction"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1766
---

## When to Use
Stop-diagnose-correct-learn protocol — handle agent errors a

Trigger: "ya te dije", "no es eso", "no funciona", "otra vez", "wrong", "not what I asked", repeated correction 2x.
## Protocol
### 1. STOP — immediately
Do NOT: explain · justify · suggest alt · generate more code
Do: "Tenés razón, me equivoqué. Vamos de nuevo." Acknowledge specifically. Stop all generation.
### 2. DIAGNOSE — root cause
- Misunderstood req → re-read user's words
- Wrong approach → check docs/context
- Hallucinated API → verify with Context7/docs
- Wrong file → re-read actual file
- Repetition → check Engram for prior attempts
### 3. CORRECT — fix approach
Unsure? ASK: "¿Entendí bien? Decime si esto es lo que necesitás."
User provided correct approach? Implement EXACTLY that.
NEVER same mistake twice in one session.
### 4. LEARN — persist
```
mem_save title: "Correction: {what}"
type: learning
content: **What**: mistake | **Correct**: | **Root cause**: | **Prevention**:
```
### 5. ESCALATION — after 2 failed attempts
STOP code → Ask "¿Podés mostrarme exactamente qué esperás?" → Offer restart w/ clear spec
## Frustration Signals
"ya te dije" → STOP+re-read+Engram · "no es eso/no funciona" → STOP+diagnose+re-read reqs · "otra vez/again" → STOP+Engram+diff approach · Short tone (1-3 words) → STOP+acknowledge+direct question
## Workflow: Detect→STOP→ACKNOWLEDGE→DIAGNOSE→CORRECT→LEARN→continue
---

docs/skills/recovery-protocol/reference.md
---
## Refs
Cross-Refs: deep-debugging | engram-protocol
