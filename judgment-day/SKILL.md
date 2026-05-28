---
name: judgment-day
description: > Dual adversarial review: 2 blind judges, verdict synthesis, fix/re-judge loops.
  Trigger: "judgment day", "juzgar", "dual review".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.5"
---

## TRIGGERS
- "judgment day"/"juzgar"/"dual review"/"que lo juzguen" · Post-implementation pre-merge · High-risk review

## PROTOCOL

### P0: RESOLVE SKILLS
`mem_search("skill-registry")` → fallback `.atl/skill-registry.md` → skip if none.
Match by code/task context → inject `## Project Standards` into BOTH judges.

### P1: PARALLEL BLIND REVIEW
Launch 2 delegates (async, parallel) — same target, NO cross-contamination. NEVER self-review.

### P2: VERDICT SYNTHESIS
| Status | Action |
|--------|--------|
| Confirmed (both) | Fix IMMEDIATE |
| Suspect (one) | Triage |
| Contradiction | Manual |

### P3: WARNING CLASS
**Real**: bug/data loss/sec in NORMAL use → FIX.
**Theoretical**: contrived scenario → INFO.
Test: "Can normal user trigger?" → YES=real, NO=theoretical.

### P4: FIX + RE-JUDGE
1. Confirmed → delegate Fix Agent
2. Fix → re-launch BOTH judges
3. After 2 iterations → ASK user continue? YES/NO→ESCALATED
4. Both clean → APPROVED ✅

### P5: CONVERGENCE
R1: present → user confirms → re-judge full scope.
R2+: re-judge CONFIRMED CRITICALs only. Real WARNINGs fix inline. Theoretical → INFO.

**APPROVED**: 0 CRITICALs + 0 real WARNINGs.

## DECISION TREE
```
User triggers JD
├─ Scope clear?→NO:ask | YES:continue
├─ P0: resolve skills
├─ launch Judge A+B (parallel delegate)
├─ wait → synthesize
├─ Clean?→APPROVED ✅
└─ Issues?→present → ask fix → YES:Fix Agent → re-judge
    ├─ clean→APPROVED ✅
    └─ still→repeat max 2→ASK user
```

## SUB-AGENT PROMPTS

### JUDGE (A=B)
```
Adversarial review. Find problems ONLY.
Target: {files}
{Project Standards}

CRITERIA: correctness, edge cases, error handling, performance, security, naming.

RETURN structured list (NO praise):
Severity: CRITICAL | WARNING(real) | WARNING(theoretical) | SUGGESTION
File:{path}(line N) · Description: what+why
Fix: one-line intent

No issues → "VERDICT: CLEAN"
```

### FIX AGENT
```
Surgical. Apply ONLY confirmed issues.
CONFIRMED: {findings}
{Project Standards}

RULES: fix ONLY confirmed · same pattern→ALL affected files
FIXES APPLIED: [file:line] — {what fixed}
```

## OUTPUT
```markdown
## JD — {target}
### R{N} Verdict | Confirmed: {N} CRIT | Suspect: {N}
### Fixes: [file:line] — {fix}
### Re-judge: A:CLEAN ✅ | B:CLEAN ✅
### JDGMNT: APPROVED ✅
```
ESCALATED: `JDGMNT: ESCALATED ⚠️ — User stopped after {N} iter. Manual review required.`

## BLOCKING
1. NEVER APPROVED until: R1 clean OR R2: 0 CRIT + 0 real WARN
2. NEVER push/commit until re-judge after fixes
3. NEVER session-end until terminal (APPROVED/ESCALATED)
4. All active JD targets terminal? List and verify.

## RULES
- Orchestrator NEVER reviews — coordinates only
- Judges: delegate (async, parallel) · Fix Agent: separate delegation
- Unclear scope → ask before launch
- After 2 iterations → ASK user
- Wait BOTH before synthesizing
