---
name: judgment-day
description: "Dual adversarial review orchestrator — 2 profile-scoped code-review-agent instances, verdict synthesis"
triggers: "Judgment day, JD, dual review, juzgar, adversarial review, LLM-as-judge, judge patterns, online verifier"
changelog: "2026-09-01 R2-4 — add Zylos 6-pattern taxonomy + small/large judge guidance (KB r2-zylos-llm-judge); 2026-09-01 wiring jd-verifier.ps1 (p2/p4/p5 enforcement)"
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

## Judge Patterns (Zylos → reference.md)
Offline = this skill (ROJA dual blind). Online = hotfix fast-path (small judge). Self-consistency = majority-of-2. Reflexion = re-judge delta on diff. Constitutional = gap >1.5 → immune-system. Reward = future ranker.
> **3-boundary rule**: gate before (a) user output, (b) irreversible exec; (c) memory = future. Large for ROJA, small inline.

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "One reviewer suffices for ROJA" | Single view on ROJA | Must run 2× blind (rule 2) |
| "3rd re-judge will pass" | Count >2 | Max 2 → ASK user (rule 3) |
| "No external auditor" | FIX/BLOCKER w/o `external-auditor` | Audit diff before APPROVED (rule 5) |

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
→ docs/skills/judgment-day/reference.md · `references/jd-patterns-wiring.md`
## Refs: code-review-agent | testing-strategy
