---
name: judgment-day
description: > Dual adversarial review: 2 blind judges, verdict synthesis, fix/re-judge loops.
  Trigger: "judgment day", "juzgar", "dual review".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.4"
---

## TRIGGERS
- "judgment day"/"judgment-day"/"review adversarial"/"dual review"/"juzgar"/"que lo juzguen"
- Post-implementation pre-merge · High-cost review · Single reviewer blindspots risk

## PROTOCOL

### P0: SKILL RESOLUTION
`mem_search("skill-registry")` → fallback `.atl/skill-registry.md` → skip if none
Match by code context (exts/paths) + task context → inject `## Project Standards (auto-resolved)` block into BOTH judge prompts.

### P1: PARALLEL BLIND REVIEW
- Launch 2 sub-agents via `delegate` (async, parallel) — same target, NO cross-contamination
- NEVER self-review — only coordinate

### P2: VERDICT SYNTHESIS
| Status | Meaning | Action |
| Confirmed | Both found | Fix IMMEDIATE |
| Suspect A/B | One only | Triage |
| Contradiction | Disagree → manual |

### P3: WARNING CLASS
```
WARNING (real) → bug/data loss/sec hole in NORMAL use → FIX
WARNING (theoretical) → contrived scenario → REPORT as INFO only
"Can normal user trigger?" → YES→real, NO→theoretical

### P4: FIX + RE-JUDGE
1. CONFIRMED → delegate Fix Agent
2. Fix complete → re-launch BOTH judges (parallel)
3. After 2 iterations → ASK user: continue? → YES/NO→ESCALATED
4. Both clean → APPROVED ✅

### P5: CONVERGENCE
Round 1: present verdict → user confirms fixes → re-judge with full scope.
Round 2+: re-judge only CONFIRMED CRITICALs.
- Confirmed real WARNINGs → fix inline, NO re-judge
- Theoretical WARNINGs → INFO, no fix
- Suggestions → fix if trivial

APPROVED: 0 CRITICALs + 0 real WARNINGs.

## DECISION TREE
```
User: "judgment day"
├─ Scope clear? → NO: ask | YES: continue
├─ P0: resolve skills → build Project Standards
├─ launch Judge A + B (parallel delegate)
├─ wait both → synthesize verdict
├─ No issues? → APPROVED ✅
└─ Issues? → present table → ask fix → YES: Fix Agent → re-judge
    ├─ clean → APPROVED ✅
    └─ still → repeat fix+judge (max 2) → ASK user
```

## SUB-AGENT PROMPTS

### JUDGE (A=B)
```
You are adversarial. Find problems ONLY.
Target: {files/features}
{Project Standards block from P0}

CRITERIA
- correctness: bugs? · edge cases: unhandled inputs?
- error handling: caught/propagated/logged?
- performance: N+1/inefficient loops?
- security: injection/secrets/auth?
- naming: matches patterns?

RETURN (structured list, NO praise)
Severity: CRITICAL | WARNING (real) | WARNING (theoretical) | SUGGESTION
File: {path} (line N) · Description: what+why
Fix: one-line intent

WARNING rule → "Can normal user trigger?" → YES→real, NO→theoretical.
Skill Resolution: {injected|fallback|path|none}
No issues → "VERDICT: CLEAN"
```

### FIX AGENT
```
Surgical. Apply ONLY confirmed issues.

CONFIRMED ISSUES: {findings table}
{Project Standards block from P0}

RULES
- Fix ONLY confirmed — no refactor beyond scope
- Same pattern → ALL affected files
- After each: file:line: brief

FIXES APPLIED:
- [file:line] — {what fixed}

Skill Resolution: {injected|fallback|path|none}
```

## OUTPUT (VERDICT)
```markdown
## JD — {target}
### R{N} — Verdict
| Finding | JA | JB | Sev | Status |
| {ISSUE} | ✅ | ✅ | CRIT | Confirmed |
**Confirmed**: {N} CRIT | **Suspect**: {N}
### Fixes: [file:line] — {fix}
### Re-judge: JA:CLEAN ✅ | JB:CLEAN ✅
### JDGMNT: APPROVED ✅
```
### ESCALATION
```markdown
## JD — {target}
### JDGMNT: ESCALATED ⚠️
User stopped after {N} iter. Manual review required.
**Remaining**: {issues}
```

## BLOCKING (MANDATORY)
1. NEVER APPROVED until: R1 CLEAN OR R2: 0 CRIT + 0 real WARN
2. NEVER push/commit after fixes until re-judge
3. NEVER session summary/"done" until all JD terminal (APPROVED/ESCALATED)
4. After Fix → IMMEDIATELY re-launch judges
5. Multiple JDs → independent

## SELF-CHECK (pre-terminal)
1. List ALL active JD targets
2. Each APPROVED/ESCALATED?
3. Any with fixes → did R2 run?
4. R2 issues → asked user? Respected?

Any NO → go back, complete step.

## RULES
- Orchestrator NEVER reviews —ONLY coordinates
- Judges: delegate (async, parallel)
- Fix Agent: separate delegation
- Unclear scope → ask before launch
- After 2 → ASK user, never auto-escalate
- Wait BOTH before synthesizing