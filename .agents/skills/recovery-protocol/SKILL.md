---
name: recovery-protocol
description: "Stop-diagnose-correct-learn protocol — handle agent errors and frustration systematically"
triggers: "Recovery, 'no es eso', frustration, error correction"
changelog: docs/ciclos/cycle28-20260815.md
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
## Anti-Patterns
| ❌ Wrong | ✅ Right |
|---|---|
| "Actually what I said was also valid..." | "Tenés razón, me equivoqué." |
| Keep generating after "no" | STOP immediately |
| Repeat same solution differently | Change approach entirely |
| Blame model/tools/environment | Own the mistake |

## Refs
immune-system · session-resume · context-watchdog · bitacora · lean-context

## Examples

### Example 1: Wrong File Modified
**User**: "Fix the auth middleware timeout"
**Agent**: Modifies `src/middleware/rate-limit.ts` instead of `src/middleware/auth.ts`
**User**: "No, el archivo es auth.ts, no rate-limit.ts"
**Recovery**:
- STOP: "Tenés razón, me equivoqué de archivo."
- DIAGNOSE: Misread file path — didn't verify before editing
- CORRECT: Read `auth.ts`, apply timeout fix there
- LEARN: `mem_save title:"Correction: Wrong file modified" type:learning content:"**What**: Edited rate-limit.ts instead of auth.ts **Correct**: Read target file path from user request **Root cause**: Assumed file from context without verification **Prevention**: Always confirm file path before Edit"`

### Example 2: Hallucinated API
**User**: "Use the new React 19 useOptimistic hook"
**Agent**: Imports `useOptimistic` from `react` (doesn't exist in React 19)
**User**: "Ese hook no existe, revisá la doc"
**Recovery**:
- STOP: "Tenés razón, aluciné la API."
- DIAGNOSE: Hallucinated hook name — no Context7 verification
- CORRECT: `ctx7_query-docs` for React 19 hooks → use `useActionState` or `useFormStatus`
- LEARN: `mem_save title:"Correction: Hallucinated React hook" type:learning content:"**What**: Assumed useOptimistic exists **Correct**: Verified via Context7 **Root cause**: Didn't check docs for new API **Prevention": Always verify new APIs with Context7 before using"`

### Example 3: Misunderstood Requirement
**User**: "Add validation to the create user endpoint — email must be unique"
**Agent**: Adds email format validation (regex) but no uniqueness check
**User**: "No, único significa unique constraint en BD, no formato"
**Recovery**:
- STOP: "Tenés razón, confundí validación de formato con constraint de unicidad."
- DIAGNOSE: Misunderstood "único" as format validation vs DB constraint
- CORRECT: Add DB unique index + handle duplicate error in endpoint
- LEARN: `mem_save title:"Correction: Misunderstood unique requirement" type:learning content:"**What**: Added format validation instead of DB uniqueness **Correct**: Unique index + error handling **Root cause**: Ambiguous term 'unique' not clarified **Prevention": Ask '¿Constraint en BD o validación de formato?' when ambiguous"`

### Example 4: Repeated Same Mistake
**User**: "No uses console.log, usa el logger estructurado"
**Agent**: Replaces with `logger.info()` but still uses `console.log` in another file
**User**: "Otra vez console.log, ya te dije que no"
**Recovery**:
- STOP: "Tenés razón, repetí el error en otro archivo."
- DIAGNOSE: Repetition — didn't search codebase for other occurrences
- CORRECT: `grep console.log` across project → replace all with logger
- LEARN: `mem_save title:"Correction: Repeated console.log" type:learning content:"**What**: Fixed one file but missed others **Correct**: Global search+replace **Root cause**: Local fix without codebase scan **Prevention": After correction, grep for same pattern project-wide"`

### Example 5: Context Contamination
**User**: "El test debe mockear el servicio, no la BD"
**Agent**: Mocks the database layer instead of the service layer
**User**: "No, el service layer — el test anterior lo hacía bien"
**Recovery**:
- STOP: "Tenés razón, me contamine con el contexto del test anterior."
- DIAGNOSE: Context contamination — previous test pattern bled into current task
- CORRECT: Re-read current test file, mock `UserService` not `UserRepository`
- LEARN: `mem_save title:"Correction: Context contamination in tests" type:learning content:"**What**: Applied wrong mock layer from previous test **Correct**: Mock service layer per current test **Root cause": Didn't isolate context between test tasks **Prevention": Re-read target test file fresh; don't assume patterns transfer"`

## Testing Patterns

### Pattern 1: Frustration Signal Detection Test
```typescript
// Given: User says "ya te dije que no"
// When: Agent processes input through recovery-protocol
// Then: STOP triggers immediately, no code generation occurs
// Verify: Output contains "Tenés razón, me equivoqué" + DIAGNOSE step
```

### Pattern 2: Correction Persistence Test
```typescript
// Given: Agent makes error, user corrects, agent applies fix
// When: Agent calls mem_save with learning type
// Then: Observation stored with What/Correct/Root cause/Prevention
// Verify: mem_search("Correction:") returns the saved observation
```

### Pattern 3: Escalation Threshold Test
```typescript
// Given: Same error repeated 2x in one session
// When: Agent detects second failure
// Then: ESCALATION triggers — stops code, asks for exact expectation
// Verify: Output contains "¿Podés mostrarme exactamente qué esperás?"
```

## Edge Cases

### Edge Case 1: User Correction Is Also Wrong
**Scenario**: User says "No, usa X" but X is also incorrect
**Handling**: Don't blindly implement — verify with docs/context first. If unsure: "¿Seguro que es X? La doc dice Y. ¿Probamos Y?"

### Edge Case 2: Multiple Errors in One Response
**Scenario**: User points out 3 different mistakes at once
**Handling**: Acknowledge all: "Tenés razón en los 3 puntos." Fix highest-impact first. Learn each separately.

### Edge Case 3: Frustration Without Explicit Signal
**Scenario**: User gives short answers ("ok", "sí", "dale") but tone shifted
**Handling**: Detect tone shift → proactive check: "¿Va bien o me perdí en algo?"

### Edge Case 4: Recovery Protocol Triggered on Valid Disagreement
**Scenario**: User challenges a correct implementation ("eso no sirve")
**Handling**: Don't auto-accept blame. Verify: "La implementación hace X según req Y. ¿Qué esperás distinto?" — only STOP if genuinely wrong.

## Anti-Patterns

| ❌ Wrong | ✅ Right |
|---|---|
| "Actually what I said was also valid..." | "Tenés razón, me equivoqué." |
| Keep generating after "no" | STOP immediately |
| Repeat same solution differently | Change approach entirely |
| Blame model/tools/environment | Own the mistake |
| **Apologize without fixing** ("Sorry!" → continues same way) | **Acknowledge + DIAGNOSE + CORRECT + LEARN** |
| **Save learning without root cause** ("Fixed it") | **Full What/Correct/Root cause/Prevention** |
