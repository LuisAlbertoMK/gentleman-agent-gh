---
name: judgment-day
description: "Dual adversarial code review — 2 blind judges in parallel, verdict synthesis, fix/re-judge loops until approval"
triggers: "Judgment day, dual review, juzgar"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.8", changelog: "1.7->1.8 (sprint 5: 80->65 lines, -18.8%, compacted protocol)"
---

Dual adversarial review: 2 blind judges, verdict synthesis, fix/re-judge loops.Trigger: "judgment day", "juzgar", "dual review", "que lo juzguen".
## Triggers"judgment day"/"juzgar"/"dual review"/"que lo juzguen" Â· post-impl pre-merge Â· high-risk
## Protocol
### P0: Resolve Skills`mem_search("skill-registry")` â†’ fallback `.atl/skill-registry.md` â†’ skip if none. Match by code/task context â†’ inject `
## Project Standards` into BOTH judges.
### P1: Parallel Blind ReviewLaunch 2 delegates (async, parallel) â€” same target, NO cross-contamination. NEVER self-review.
### P2: Verdict Synthesis| Status | Action ||--------|--------|| Confirmed (both) | Fix IMMEDIATE || Suspect (one) | Triage || Contradiction | Manual |
### P3: Warning Class**Real**: bug/data-loss/sec in NORMAL use â†’ FIX. **Theoretical**: contrived â†’ INFO. Test: "Can normal user trigger?" YES=real / NO=theoretical.
### P4: Fix + Re-JudgeConfirmed â†’ delegate Fix Agent â†’ re-launch BOTH. After 2 iter â†’ ASK user. Both clean â†’ APPROVED âœ….
### P5: ConvergenceR1: present â†’ user confirms â†’ re-judge full. R2+: re-judge CONFIRMED CRITICALs only. Real WARN fix inline. Theoretical â†’ INFO. **APPROVED** = 0 CRIT + 0 real WARN.
## Flow
```Trigger â†’ P0 skills â†’ Launch A+B (parallel) â†’ Wait â†’ Synthesizeâ”œâ”€ Clean â†’ APPROVED âœ…â””â”€ Issues â†’ present â†’ ask fix â†’ Fix Agent â†’ re-judge (max 2)```
## Sub-Agent Prompts
### Judge (A=B)
```Adversarial review. Find problems ONLY.Target: {files} | {Project Standards}Criteria: correctness, edge cases, error handling, perf, security, naming.Severity: CRITICAL | WARNING(real) | WARNING(theoretical) | SUGGESTIONFile:{path}(line N) Â· Description: what+why Â· Fix: one-line intentNo issues â†’ "VERDICT: CLEAN"```
### Fix Agent
```Surgical. Apply ONLY confirmed: {findings} | {Project Standards}Rules: fix ONLY confirmed Â· same pattern â†’ ALL affected filesFIXES: [file:line] â€” {what fixed}```
## Output
```
## JD â€” {target}
### R{N} Verdict | Confirmed: {N} CRIT | Suspect: {N}
### Fixes: [file:line] â€” {fix}
### Re-judge: A:CLEAN âœ… | B:CLEAN âœ…
### JDGMNT: APPROVED âœ…
```ESCALATED: `JDGMNT: ESCALATED âš ï¸ â€” Manual review after {N} iter.`
## Blocking1. NEVER APPROVED until: R1 clean OR R2: 0 CRIT + 0 real WARN2. NEVER push/commit until re-judge after fixes3. Orchestrator NEVER reviews â€” coordinates only4. Judges: delegate (async, parallel) Â· Fix Agent: separate delegation5. Unclear scope â†’ ask before launch Â· After 2 iter â†’ ASK user
