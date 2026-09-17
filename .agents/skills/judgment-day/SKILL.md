---
name: judgment-day
description: "Dual adversarial review orchestrator — 2 profile-scoped code-review-agent instances, verdict synthesis"
triggers: "Judgment day, JD, dual review, juzgar, adversarial review, LLM-as-judge, judge patterns, online verifier"
changelog: "2026-09-01 R2-4 — Zylos 6-pattern taxonomy; jd-verifier.ps1 wiring; cycle32-p2 taxonomy->reference"
token_budget: 3200
---
## Rules
1. ROJA only — skip AMARILLA/VERDE
2. Blind — no cross-contamination between reviewers
3. Max 2 re-judge → ASK user
4. Identical profiles → second = "security"
5. FIX/BLOCKER → `external-auditor`
6. Block ROJA push until JD clearance

## Protocol
**P0 Zone Filter**: `review-rules.jsonc` → ROJA=dual, AMARILLA=single, VERDE=skip.
**P1 Profiles**: `jd_profile_selector` first-match → 2× `code-review-agent` blind. 120s timeout, retry once. Fast-path: `jd-verifier.ps1 -Zone ROJA -FastPath`.
**P2 Synthesize**: Both CLEAN→APPROVED. Same root-cause (±5 lines)→Confirmed. Different→Triage→fix→re-judge (max 2). Majority-of-2, diverge→higher severity wins.
**P3 Calibration**: FIX/BLOCKER→`external-auditor`. Gap>1.5→`immune-system`.

## Judge Patterns (Zylos 6)
| # | Pattern | When |
|---|---------|------|
|1|Offline eval|ROJA dual blind large judge|
|2*|Online verifier|Small judge gated-optional → reference.md|
|3|Self-consistency|2-profile blind majority-of-2|
|4|Reflexion|Re-judge delta max2 grounded|
|5*|Constitutional/RLAIF|gap>1.5 immune-system → reference.md|
|6*|Reward model|ranker future pre-push → reference.md|
\* gated-optional → docs/skills/judgment-day/reference.md. 3-boundary: (a)output (b)push/Write (c)memory.

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "One reviewer suffices for ROJA" | Single view on ROJA | Must run 2× blind (rule 2) |
| "3rd re-judge will pass" | Count >2 | Max 2 → ASK user (rule 3) |
| "No external auditor" | FIX/BLOCKER w/o auditor | Audit diff before APPROVED (rule 5) |

## Red Flags
- Not blind → verdict invalid
- No `review-rules.jsonc` filter → misclassification

## Output
```
JD-{target} | Profiles: {A}/{B} | 4R | Confirmed:N | JDGMNT: APPROVED/ESCALATED | CALIB: OK/GAP
```
## Verification
- Both CLEAN or same root-cause (±5 lines) → Confirmed; else Triage→fix→re-judge
- `BLOCKER` w/o `.breaker-cleared` → blocks push
- Pipeline: `review-pipeline` Phase 2b; pre-commit #9 warns ROJA w/o JD
- Frontmatter stable; cross-refs exist; no anti-patterns reintroduced

→ docs/skills/judgment-day/reference.md · Cross-Refs: code-review-agent | adversarial-breaker | testing-strategy
