---
name: judgment-day
description: "Dual adversarial 4R review - 2 blind judges (Risk/Readability/Reliability/Resilience), verdict synthesis, fix/re-judge loops"
triggers: "Judgment day, dual review, juzgar"
license: Apache-2.0
metadata:
  tags: [engineering, review, gentle-ai]
  author: gentleman-vMK
  version: "2.3"
  changelog: "2.2->2.3: Audit gaps: JSONC parse, profile validation, fallback, distinct check"
  config_refs: review-rules.jsonc
---
## Protocol
### P0: Resolve Skills + Profile
Load review-rules.jsonc; parse JSONC (strip // /* */ -> JSON.parse). Match file basename vs jd_profile_selector keys (glob, first match). Fallback: ["architect","security"]. Validate profile exists in jd_profiles -> if not, use "architect". If both profiles identical -> [profile,"security"]. Inject: "## Profile Focus\n{profile.instructions}".
### P1: Parallel Blind 4R Review (Profile-Scoped)
2 delegates (async, parallel) -- same target, DIFFERENT profiles, NO cross-contamination.
### P2-P5: Verdict -> Fix -> Re-judge -> Converge
Both clean -> APPROVED. Both flag same -> Confirmed. One flags -> Triage. Fix -> Re-launch (max2).
### P6: Calibration: If FIX/BLOCKER, external-auditor on final diff. Gap >1.5 -> immune-system.
## Sub-Agent Prompts
### Judge (4R + Profile): 4R + profile lens. LEAD: "## Profile Focus\n{profile.instructions}". Severity: CRITICAL|WARNING(real)|WARNING(theoretical)|SUGGESTION. Clean -> "VERDICT:CLEAN"
### Fix Agent: [4R-{R}] prefix. Apply ONLY confirmed. Same pattern -> ALL.
## Output: JD-{target} | R{N} | 4R: Risk:X Readability:X Reliability:X Resilience:X | Confirmed:N | Fixes: [file:line] | A:B: status | JDGMNT: APPROVED/ESCALATED | CALIB: OK/GAP-{dim}:{delta}
## Blocking: No push until clean(all 4R>=6) OR R2(0 CRIT+0 real WARN) | Judges async+parallel | Unclear -> ask. After 2 -> ASK.
