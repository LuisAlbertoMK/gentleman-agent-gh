---
name: judgment-day
description: "Dual adversarial review orchestrator — 2 profile-scoped code-review-agent instances, verdict synthesis"
triggers: "Judgment day, JD, dual review, juzgar, adversarial review, LLM-as-judge, judge patterns, online verifier"
changelog: "2026-09-01 R2-4 — Zylos 6-pattern taxonomy; jd-verifier.ps1 wiring; cycle32-p2 taxonomy->reference; 2026-09-23 Ronda2-S3 patterns 1-3 operational (offline eval + online verifier budget measured + self-consistency); 2026-09-23 Ronda3-S2 patterns 4-6 operational (Reflexion grounding gate + constitutional loop + ranker), R2-4 6/6 closed"
token_budget: 7000
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
**P1 Profiles**: `jd_profile_selector` first-match → 2× `code-review-agent` blind. 120s timeout, retry once. Fast-path: `jd-verifier.ps1 -Zone ROJA -FastPath` (budget ≤162ms measured median ~136ms n=12; over-budget → ESCALATE — detail → reference.md Pattern 2).
**P2 Synthesize**: Both CLEAN→APPROVED. Same root-cause (±5 lines)→Confirmed. Different→Triage→fix→re-judge (max 2). Majority-of-2, diverge→higher severity wins.
**P3 Calibration**: FIX/BLOCKER→`external-auditor`. Gap>1.5→`immune-system`.

## Judge Patterns (Zylos 6)
| # | Pattern | When |
|---|---------|------|
|1|Offline eval|ROJA dual blind large judge|
|2*|Online verifier|Small judge gated-optional → reference.md|
|3|Self-consistency|2-profile blind majority-of-2|
|4|Reflexion|Re-judge grounded: citations mandatory|
|5|Constitutional/RLAIF|gap>1.5 loop generate→critique→revise|
|6|Reward model|Ranker over N samples, manual pre-push|
\* gated-optional → docs/skills/judgment-day/reference.md. 3-boundary: (a)output (b)push/Write (c)memory.

## Patterns 1–3 — Operation (Ronda2-S3; patterns 4–6 → Ronda3-S2 below)
**P1 Offline eval**: ROJA dual blind, LARGE judge only (small judge never decides ROJA). Freeze diff cited
in verdict (`git diff HEAD | git hash-object --stdin`); log target/profiles/verdicts→synthesis;
FIX/BLOCKER → calibrate vs `external-auditor` (rule 5). Format → reference.md Pattern 1.
**P2 Online verifier** (gated-optional, ROJA hotfix only, default OFF):
`scripts/jd-verifier.ps1 -Zone ROJA -FastPath` → `VERIFY-OK` iff internal `elapsedMs ≤162`;
over-budget → `ESCALATE` exit 1 (fail-closed, never a pass). Measured 2026-09-23 n=12:
100–178ms, median ~136ms, 10/12 ≤162ms (83%). NEVER replaces dual blind (rule 2). → reference.md Pattern 2.
**P3 Self-consistency**: majority-of-2 blind; same root-cause (±5 lines)→Confirmed; diverge→fix both→re-judge
on diff delta (max 2 → ASK user, rule 3); tie-break = higher severity wins (`CALIB: GAP`).
Blind isolation is prerequisite — shared-context verdicts are not votes. → reference.md Pattern 3.

## Patterns 4–6 — Operation (Ronda3-S2; closes R2-4 6/6)
**P4 Reflexion (grounded re-judge)**: re-judge rounds REQUIRE external grounding citations
(tests file:line, diff hash, retrieval KB id) — intrinsic "check your work" without citations
degrades reasoning and does NOT count as evidence. Enforced:
`scripts/jd-verifier.ps1 -Rounds <1|2> -GroundingEvidence '<citations>'` → `GROUNDED` exit 0;
without citations → `UNGROUNDED` exit 1 (fail-closed). Initial review (`-Rounds 0`) needs no
grounding. Format → reference.md Pattern 4.
**P5 Constitutional loop** (runtime, gap>1.5): generate→critique (against ROJA constitution:
rules 1-6 + reference.md anti-patterns)→revise→re-judge grounded (P4). Trigger emits:
`scripts/jd-verifier.ps1 -RepeatFinding` → `CONSTITUTIONAL` + `CONSTITUTIONAL-LOOP` lines;
repeat offense (same root-cause twice) → `immune-system` permanent rule (Rule: {anti-pattern-id}).
Training-time RLAIF stays out of scope — runtime loop only. → reference.md Pattern 5.
**P6 Reward ranker** (manual pre-push): `scripts/jd-verifier.ps1 -Rank 'label:score,...'` →
deterministic argmax `RANKER: winner=<label> (<score>) over N samples` (ties → first max wins;
malformed/empty → `RANKER-ERROR` exit 1). Run over N candidate verdicts before push; winner
still needs dual-blind confirmation (rule 2) — ranker orders, never approves. Auto pre-push
hook wiring is future (touches hook files, out of scope) — boundary, not phantom. → reference.md Pattern 6.

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "One reviewer suffices for ROJA" | Single view on ROJA | Must run 2× blind (rule 2) |
| "3rd re-judge will pass" | Count >2 | Max 2 → ASK user (rule 3) |
| "No external auditor" | FIX/BLOCKER w/o auditor | Audit diff before APPROVED (rule 5) |
| "Small judge suffices for ROJA" | Small-only verdict on ROJA | P1 mandates LARGE-judge dual blind; small judge = P2 pre-check only |
| "Fast-path VERIFY-OK = APPROVED" | VERIFY-OK cited as final verdict | Mechanical pre-check only; dual blind still mandatory (rule 2) |
| "Over-budget verifier still passes" | elapsedMs>162 treated as OK | Over budget → ESCALATE exit 1, never VERIFY-OK (fail-closed) |
| "Agreed-with-myself counts as consistent" | Two verdicts, one shared context | Majority-of-2 valid only blind (rule 2); shared context → re-run blind |
| "Re-check passed, trust me" | Re-judge verdict with no citations | P4: re-judge without tests/diff/retrieval citations → UNGROUNDED exit 1; cite or it didn't happen |
| "One critique pass fixes the constitution" | Single revise with no re-judge | P5: loop is generate→critique→revise→re-judge grounded; revise without grounded re-judge → re-run |
| "Ranker winner = APPROVED" | RANKER line cited as final verdict | P6 orders candidates only; winner still needs dual blind (rule 2); ranker never approves |

## Red Flags
- Not blind → verdict invalid
- No `review-rules.jsonc` filter → misclassification
- `VERIFY-OK` with elapsedMs >162ms cited as pass
- Single-context verdict presented as self-consistent majority
- Offline eval on pre-fix code cited as post-fix evidence
- Re-judge verdict citing no tests/diff/retrieval (ungrounded Reflexion)
- `RANKER: winner=` cited as APPROVED without dual blind
- Constitutional revise without grounded re-judge closing the loop

## Output
```
JD-{target} | Profiles: {A}/{B} | 4R | Confirmed:N | JDGMNT: APPROVED/ESCALATED | CALIB: OK/GAP
```
## Verification
- Both CLEAN or same root-cause (±5 lines) → Confirmed; else Triage→fix→re-judge
- `BLOCKER` w/o `.breaker-cleared` → blocks push
- Pipeline: `review-pipeline` Phase 2b; pre-commit #9 warns ROJA w/o JD
- Frontmatter stable; cross-refs exist; no anti-patterns reintroduced
- `& scripts/jd-verifier.ps1 -Zone ROJA -FastPath` → VERIFY-OK (≤162ms) exit 0 or ESCALATE exit 1; VERIFY-OK never final
- Offline-eval log (target/profiles/verdicts + freeze hash) attached for ROJA FIX/BLOCKER before `external-auditor`
- Re-judge (`-Rounds 1|2`) carries `-GroundingEvidence` (tests file:line + diff/retrieval); ungrounded → exit 1
- `-RepeatFinding` emits `CONSTITUTIONAL-LOOP: generate→critique→revise`; repeat offense → `immune-system` rule
- `-Rank 'a:0.7,b:0.9'` executed pre-push (`RANKER: winner=b`); winner ordered only, dual blind still mandatory

→ docs/skills/judgment-day/reference.md · Cross-Refs: code-review-agent | adversarial-breaker | testing-strategy
