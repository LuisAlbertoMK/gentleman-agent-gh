---
name: judgment-day
description: >
  Dual adversarial review: 2 blind judges, verdict synthesis, fix/re-judge loops.
  Trigger: "judgment day", "juzgar", "dual review", "que lo juzguen".
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.8", changelog: "1.7->1.8 (sprint 5: 80->65 lines, -18.8%, compacted protocol)"
---

## Triggers
"judgment day"/"juzgar"/"dual review"/"que lo juzguen" · post-impl pre-merge · high-risk

## Protocol

### P0: Resolve Skills
`mem_search("skill-registry")` → fallback `.atl/skill-registry.md` → skip if none. Match by code/task context → inject `## Project Standards` into BOTH judges.

### P1: Parallel Blind Review
Launch 2 delegates (async, parallel) — same target, NO cross-contamination. NEVER self-review.

### P2: Verdict Synthesis
| Status | Action |
|--------|--------|
| Confirmed (both) | Fix IMMEDIATE |
| Suspect (one) | Triage |
| Contradiction | Manual |

### P3: Warning Class
**Real**: bug/data-loss/sec in NORMAL use → FIX. **Theoretical**: contrived → INFO. Test: "Can normal user trigger?" YES=real / NO=theoretical.

### P4: Fix + Re-Judge
Confirmed → delegate Fix Agent → re-launch BOTH. After 2 iter → ASK user. Both clean → APPROVED ✅.

### P5: Convergence
R1: present → user confirms → re-judge full. R2+: re-judge CONFIRMED CRITICALs only. Real WARN fix inline. Theoretical → INFO. **APPROVED** = 0 CRIT + 0 real WARN.

## Flow
```
Trigger → P0 skills → Launch A+B (parallel) → Wait → Synthesize
├─ Clean → APPROVED ✅
└─ Issues → present → ask fix → Fix Agent → re-judge (max 2)
```

## Sub-Agent Prompts

### Judge (A=B)
```
Adversarial review. Find problems ONLY.
Target: {files} | {Project Standards}
Criteria: correctness, edge cases, error handling, perf, security, naming.
Severity: CRITICAL | WARNING(real) | WARNING(theoretical) | SUGGESTION
File:{path}(line N) · Description: what+why · Fix: one-line intent
No issues → "VERDICT: CLEAN"
```

### Fix Agent
```
Surgical. Apply ONLY confirmed: {findings} | {Project Standards}
Rules: fix ONLY confirmed · same pattern → ALL affected files
FIXES: [file:line] — {what fixed}
```

## Output
```
## JD — {target}
### R{N} Verdict | Confirmed: {N} CRIT | Suspect: {N}
### Fixes: [file:line] — {fix}
### Re-judge: A:CLEAN ✅ | B:CLEAN ✅
### JDGMNT: APPROVED ✅
```
ESCALATED: `JDGMNT: ESCALATED ⚠️ — Manual review after {N} iter.`

## Blocking
1. NEVER APPROVED until: R1 clean OR R2: 0 CRIT + 0 real WARN
2. NEVER push/commit until re-judge after fixes
3. Orchestrator NEVER reviews — coordinates only
4. Judges: delegate (async, parallel) · Fix Agent: separate delegation
5. Unclear scope → ask before launch · After 2 iter → ASK user
