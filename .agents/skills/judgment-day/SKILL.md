---
name: judgment-day
description: "Dual adversarial code review — 2 blind judges in parallel, verdict synthesis, fix/re-judge loops until approval"
triggers: "Judgment day, dual review, juzgar"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.8"
  changelog: "1.7->1.8: 80->65 lines"
---
Dual adversarial review: 2 blind judges, verdict synthesis, fix/re-judge loops.
## Triggers: "judgment day"/"juzgar"/"dual review" | post-impl pre-merge | high-risk
## Protocol
### P0: Resolve Skills
mem_search("skill-registry") -> fallback. Inject Project Standards into BOTH judges.
### P1: Parallel Blind Review
2 delegates (async, parallel) — same target, NO cross-contamination. NEVER self-review.
### P2: Verdict: Confirmed(both)->Fix | Suspect(one)->Triage | Contradiction->Manual
### P3: Warnings: Real(bug/data/sec)->FIX | Theoretical(contrived)->INFO
### P4: Fix+Re-Judge: Confirmed->Fix Agent->re-launch both. After 2->ASK. Both clean->APPROVED.
### P5: Convergence: R1 full re-judge. R2+ only CRITICALs. APPROVED=0 CRIT+0 real WARN.
## Flow: Trigger->P0->Launch A+B->Wait->Synthesize->Clean?APPROVED|Issues?Fix Agent->re-judge(max2)
## Sub-Agent Prompts
### Judge: Adversarial. Find problems ONLY. Criteria: correctness, edge cases, error handling, perf, security, naming. Severity: CRITICAL|WARNING(real)|WARNING(theoretical)|SUGGESTION. No issues->"VERDICT:CLEAN"
### Fix Agent: Surgical. Apply ONLY confirmed. Same pattern->ALL affected. FIXES: [file:line]-{fix}
## Output: JD-{target} | R{N} Confirmed:N CRIT | Fixes: [file:line] | A:CLEAN B:CLEAN | JDGMNT: APPROVED/ESCALATED
## Blocking: No approval until R1 clean OR R2(0 CRIT+0 real WARN) | No push until re-judge | Orchestrator coordinates only | Judges async+parallel | Unclear->ask. After 2->ASK user