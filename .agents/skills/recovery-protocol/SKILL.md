---
name: recovery-protocol
description: >  recovery-protocol skill
triggers: "Recovery, 'no es eso', frustration"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

Trigger: "ya te dije", "no es eso", "no funciona", "otra vez", "wrong", "not what I asked", repeated correction 2x.
## WhenUser corrects agent Â· Frustration signals Â· Agent detects incorrect output Â· Same mistake repeated Â· "no es eso", "ya te dije", "wrong"
## Protocol
### 1. STOP â€” IMMEDIATELYDo NOT: explain Â· justify Â· suggest alt Â· generate more code.Do: "TenÃ©s razÃ³n, me equivoquÃ©. Vamos de nuevo." Acknowledge specifically.
### 2. DIAGNOSE â€” root cause
```Error type:â”œâ”€â”€ Misunderstood req â†’ re-read user's wordsâ”œâ”€â”€ Wrong approach â†’ check docs/contextâ”œâ”€â”€ Hallucinated API â†’ verify with Context7/docsâ”œâ”€â”€ Wrong file â†’ re-read actual fileâ””â”€â”€ Repetition â†’ check Engram for prior attempts```
### 3. CORRECT â€” fix approach- Unsure? ASK: "Â¿EntendÃ­ bien? Decime si esto es lo que necesitÃ¡s."- User provided correct approach? Implement EXACTLY that.- Need research? Delegate before coding.- NEVER same mistake twice in one session.
### 4. LEARN â€” persist lesson`mem_save` error pattern:
```title: "Correction: {what was wrong}"type: learningcontent: **What**: mistake | **Correct approach**: | **Root cause**: | **Prevention**:```
### 5. ESCALATION â€” after 2 failed attempts- STOP generating code- Ask: "Â¿PodÃ©s mostrarme exactamente quÃ© esperÃ¡s?" / "show me expected output"- Offer restart with clear spec
## Frustration Signals| Signal | Action ||--------|--------|| "ya te dije" | STOP â†’ re-read history â†’ apologize â†’ check Engram || "no es eso" / "no funciona" | STOP â†’ diagnose â†’ re-read reqs || "otra vez" / "again" | STOP â†’ check Engram â†’ try diff approach || Short tone (1-3 words) | STOP â†’ acknowledge â†’ direct question |
## Workflow
```Detect signal â†’ STOP â†’ ACKNOWLEDGE â†’ DIAGNOSE â†’ CORRECT â†’ LEARN â†’ continue```
## Anti-Patterns| âŒ Wrong | âœ… Right ||----------|---------|| "Actually what I said was also valid..." | "TenÃ©s razÃ³n, me equivoquÃ©." || Keep generating after "no" | STOP immediately || Repeat same solution differently | Change approach entirely || Blame model/tools/environment | Own the mistake || Silent retry | Explicit acknowledgment + fix |
