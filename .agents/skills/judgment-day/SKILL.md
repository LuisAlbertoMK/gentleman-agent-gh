---
name: judgment-day
description: "Dual adversarial review orchestrator — 2 profile-scoped code-review-agent instances, verdict synthesis"
triggers: "Judgment day, JD, dual review, juzgar, adversarial review, LLM-as-judge, judge patterns, online verifier"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 4200
---

## When to Use
ROJA dual review — 2× `code-review-agent` blind + synthesis. ROJA only.
## Rules
1. ROJA only — skip AMARILLA/VERDE
2. Blind — no cross-contamination
3. Max 2 re-judge → ASK user
4. Identical profiles → second = "security"
5. FIX/BLOCKER → `external-auditor`
6. Block ROJA push until JD clearance

## Protocol

### P0: Zone Filter
Strip JSONC comments in `review-rules.jsonc`. ROJA→dual, AMARILLA→single, VERDE→skip.

### P1: Profiles → 2× code-review-agent
`jd_profile_selector` first-match (`path|basename|fallback`). Missing→"architect". Identical→`[profile,"security"]`. 2 parallel blind `"## Profile Focus\n{instructions}"`. 120s timeout, retry once.
Fast-path: `jd-verifier.ps1 -Zone <AMARILLA|ROJA> -FastPath` → VERIFY-OK or ESCALATE.

### P2: Synthesize

| Scenario | Verdict |
|----------|---------|
| Both CLEAN | APPROVED |
| Same root-cause (file ±5 lines) | Confirmed |
| Different | Triage → fix → re-judge |
| Re-judge | Max 2 (diff delta only) |
P2: majority-of-2 (diverge → higher severity wins).

### P3: Calibration
FIX/BLOCKER → `external-auditor` on diff. Gap >1.5 → `immune-system`.

## Judge Patterns (Zylos 6 — full in docs/skills/judgment-day/reference.md)
| # | Pattern | When |
|---|---------|------|
|1|Offline eval|ROJA dual blind large judge|
|2|Online verifier|Small judge gated-optional pre-output|
|3|Self-consistency|2-profile blind majority-of-2|
|4|Reflexion|Re-judge delta max2 grounded|
|5|Constitutional/RLAIF|gap>1.5 → immune-system gated-optional|
|6|Reward model|Ranker N future pre-push gated-optional|

## Anti-Rationalization → docs/skills/judgment-day/reference.md (one-reviewer-suffices · 3rd-re-judge · no-external-auditor)
> **3-boundary rule**: gate before (a) user output, (b) irreversible exec; (c) memory = future. Large for ROJA, small inline.

## Red Flags
- Not blind → verdict invalid
- No `review-rules.jsonc` filter → misclassification

## Verification
- Both CLEAN or same root-cause (±5 lines) → Confirmed; else Triage→fix→re-judge
- `BLOCKER` w/o `.breaker-cleared` → blocks push
- Pipeline: `review-pipeline` Phase 2b; pre-commit #9 warns ROJA w/o JD

## Output
```
JD-{target} | Profiles: {A}/{B} | 4R | Confirmed:N | JDGMNT: APPROVED/ESCALATED | CALIB: OK/GAP
```
---

## Reference Materials
Externalized to keep <=3KB (ADR-048). Detail -> docs/skills/judgment-day/reference.md
- Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Judge Taxonomy Extended
→ docs/skills/judgment-day/reference.md · `references/jd-patterns-wiring.md`
---
## Refs
Cross-Refs: code-review-agent | adversarial-breaker | testing-strategy
