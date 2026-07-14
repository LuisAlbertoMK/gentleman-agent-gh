---
name: judgment-day
description: "Dual adversarial review orchestrator — 2 profile-scoped code-review-agent instances, verdict synthesis"
triggers: "Judgment day, JD, dual review, juzgar, adversarial review"
license: Apache-2.0
metadata:
  tags: [engineering, review, orchestrator]
  author: gentleman-vMK
  version: "3.0"
  changelog: "2.3->3.0: Hybrid orchestrator — delegates 4R to code-review-agent, zone pre-filter, array selector"
  config_refs: review-rules.jsonc
  dependencies: [code-review-agent]
---
## Protocol
### P0: Zone Pre-Filter
Load review-rules.jsonc → strip JSONC comments (3-pass regex: // line, // trailing, /* */ block). Match changed files vs zones. ROJA → proceed dual. AMARILLA → skip (single code-review-agent sufficient). VERDE → skip.
### P1: Resolve Profiles → Launch 2× code-review-agent
Parse jd_profile_selector (ordered array, first-match). For match=path: glob against relative file path. For match=basename: glob against filename only. For match=fallback: use as default. First match wins. Validate profiles in jd_profiles → missing → use "architect". If both identical → [profile,"security"]. Launch 2 parallel code-review-agent instances, each injected with "## Profile Focus\n{profile.instructions}". Blind — NO cross-contamination. 120s timeout per delegate, retry once on failure.
### P2: Synthesize Verdicts
Both CLEAN → APPROVED. Same root-cause LOCATION (file + line ±5) → Confirmed. Discrepancy → Triage. Fix → re-launch max 2 rounds. On re-judge: pass diff delta only.
### P3: Calibration
If FIX/BLOCKER → external-auditor on final diff. Gap >1.5 → immune-system.
## Pipeline Integration
- review-pipeline invokes JD for ROJA zone in Phase 2b
- pre-commit check #9 warns if ROJA staged without JD clearance
## Output: JD-{target} | Profiles: {A}/{B} | 4R-delegated | Confirmed:N | JDGMNT: APPROVED/ESCALATED | CALIB: OK/GAP
## Blocking: max 2 re-judge cycles → ASK user | No push without JD on ROJA
