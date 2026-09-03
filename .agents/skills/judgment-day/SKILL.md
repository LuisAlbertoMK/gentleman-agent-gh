---
name: judgment-day
description: "Dual adversarial review orchestrator — 2 profile-scoped code-review-agent instances, verdict synthesis"
triggers: "Judgment day, JD, dual review, juzgar, adversarial review, LLM-as-judge, judge patterns, online verifier"
changelog: "2026-09-01 R2-4 — add Zylos 6-pattern taxonomy + small/large judge guidance (KB r2-zylos-llm-judge); 2026-09-01 wiring jd-verifier.ps1 (p2/p4/p5 enforcement); 2026-09-02 cycle32-p2 — taxonomy->reference extended, gated-optional 2/5/6 + adversarial-breaker xref"
token_budget: 4200
---

## When to Use
Dual review 2x code-review-agent blind ROJA only.

## Rules
1. ROJA only — skip AMARILLA/VERDE
2. Blind — no cross-contamination
3. Max 2 re-judge -> ASK
4. Identical -> force second security
5. FIX/BLOCKER -> external-auditor
6. Block push ROJA until JD clearance

## Protocol
### P0 Zone Filter
review-rules.jsonc strip JSONC (//,/* */). ROJA=dual, AMARILLA=single, VERDE=skip.
### P1 Profiles 2x code-review-agent
jd_profile_selector first-match path|basename|fallback. Missing=architect. Identical->[p,security]. Blind parallel, 120s retry once.
### P2 Synthesize
| Scenario | Verdict |
|----------|---------|
| Both CLEAN | APPROVED |
| Same root-cause +/-5 lines | Confirmed |
| Different | Triage->fix->re-judge |
| Re-judge | Max 2 rounds delta only |
### P3 Calibration
FIX/BLOCKER->external-auditor diff. Gap>1.5->immune-system.

## Judge Patterns (Zylos 6 — full in docs/skills/judgment-day/reference.md)
| # | Pattern | When |
|---|---------|------|
|1|Offline eval|ROJA dual blind large judge|
|3|Self-consistency|2-profile blind majority-of-2|
|4|Reflexion|Re-judge delta max2 grounded|
|2*|Online verifier|76-162ms Luna-2/Prometheus/Lynx small judge gated-optional pre-output -> reference.md|
|5*|Constitutional/RLAIF|gap>1.5 immune-system gated-optional -> reference.md|
|6*|Reward model|ranker N future pre-push gated-optional -> reference.md|
* gated-optional detail in docs/skills/judgment-day/reference.md. Small vs large + 3-boundary (a)output (b)push/Write (c)Engram covers (a)+(b) there.

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "One reviewer is enough for ROJA" | Single perspective on ROJA diff | Must run 2x blind code-review-agent — any less is AMARILLA pattern |
| "Re-judge 3rd time will pass" | Re-judge count >2 | Max 2 -> ASK user (rule 3); >2 means synthesis failed, not review |
| "External auditor not needed" | FIX/BLOCKER without external-auditor | external-auditor on diff before APPROVED (rule 5) |

## Red Flags
- Not blind -> contamination invalid
- No review-rules.jsonc zone filter -> misclassification

## Verification
- Both CLEAN or Same root-cause +/-5 -> Confirmed else Triage->fix->re-judge
- BLOCKER without .breaker-cleared -> blocks push

## Pipeline
review-pipeline Phase 2b ROJA. Pre-commit #9 warn ROJA without JD.
## Output
JD-{target} | Profiles:{A}/{B} | 4R | Confirmed:N | JDGMNT:APPROVED/ESCALATED | CALIB:OK/GAP
---

## Reference Materials
Externalized to keep <=3KB (ADR-048). Detail -> docs/skills/judgment-day/reference.md
- Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Judge Taxonomy Extended

---
## Refs
Cross-Refs: code-review-agent | adversarial-breaker | testing-strategy
