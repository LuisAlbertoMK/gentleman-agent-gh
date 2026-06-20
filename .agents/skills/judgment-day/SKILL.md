---
name: judgment-day
description: "Dual adversarial 4R review — 2 blind judges (Risk/Readability/Reliability/Resilience), verdict synthesis, fix/re-judge loops"
triggers: "Judgment day, dual review, juzgar"
license: Apache-2.0
metadata:
  tags:
    - engineering
    - review
    - gentle-ai
  author: gentleman-vMK
  version: "2.2"
  changelog: "2.1->2.2: P6 calibration via external-auditor on FIX/BLOCKER outcomes, CALIB field in output"
  config_refs: review-rules.jsonc
---
Dual adversarial 4R review: 2 blind judges (profile-scoped), 4R verdict synthesis, fix/re-judge loops.
## Triggers: "judgment day"/"juzgar"/"dual review" | post-impl pre-merge | high-risk
## Protocol
### P0: Resolve Skills + Profile
Load `code-review-agent` (4R). Load `review-rules.jsonc` and select JD profile matching target file patterns:
  - Match target files against `jd_profile_selector` keys (first match wins, glob-style).
  - Default: `["architect", "security"]`.
  - Judge A gets the first profile, Judge B the second.
  - Inject profile instructions into each judge prompt alongside Project Standards.
### P1: Parallel Blind 4R Review (Profile-Scoped)
2 delegates (async, parallel) — same target, DIFFERENT profiles, NO cross-contamination. Each judge scores 4R independently through its profile lens.
### P2: Verdict Synthesis: Both clean->APPROVED. Both flag same R->Confirmed. One flags->Suspect->Triage. Contradictory->Manual.
### P3: Warnings: Real(bug/data/sec)->FIX | Theoretical(contrived)->INFO | 4R <5 in any R->BLOCKER
### P4: Fix+Re-Judge: Confirmed->Fix Agent (4R-Reliability: add retry). Re-launch both. After 2->ASK. Both clean->APPROVED.
### P5: Convergence: R1 full re-judge (all 4R). R2+ only Rs flagged <6. APPROVED=all 4R >=6 + 0 real WARN.
### P6: Calibration (optional): If JD resulted in FIX or BLOCKER, run external-auditor on final diff for blind calibration check. Gap >1.5 → immune-system. Report in output.
## Flow: Trigger->P0->Launch A+B(inject 4R+profiles)->Wait->Synthesize 4R->Clean?APPROVED|Issues?Fix Agent->re-judge(max2)->Calibrate(P6 if FIX/BLOCKER)
## Sub-Agent Prompts
### Judge (4R + Profile): Adversarial using 4R framework + profile lens. INJECT at top: "## Profile Focus\n{profile.instructions}". Per-R severity: Risk(CRIT/BLOCK), Readability(WARN), Reliability(CRIT), Resilience(CRIT). Check per-R checklist from code-review-agent. Severity: CRITICAL|WARNING(real)|WARNING(theoretical)|SUGGESTION. No issues->"VERDICT:CLEAN"
### Fix Agent: Surgical with 4R label. Apply ONLY confirmed. Prefix each fix with [4R-{R}]. Same pattern->ALL affected. FIXES: [4R-Risk] [file:line]-{fix}
## Output: JD-{target} | R{N} | 4R: Risk:X Readability:X Reliability:X Resilience:X | Confirmed:N CRIT | Fixes: [file:line] | A:CLEAN B:CLEAN | JDGMNT: APPROVED/ESCALATED | CALIB: OK/GAP-{dim}:{delta}
## Blocking: No approval until R1 clean(all 4R>=6) OR R2(0 CRIT+0 real WARN) | No push until re-judge | Orchestrator coordinates only | Judges async+parallel | Unclear->ask. After 2->ASK user