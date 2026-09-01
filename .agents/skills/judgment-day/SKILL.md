---
name: judgment-day
description: "Dual adversarial review orchestrator — 2 profile-scoped code-review-agent instances, verdict synthesis"
triggers: "Judgment day, JD, dual review, juzgar, adversarial review, LLM-as-judge, judge patterns, online verifier"
changelog: "2026-09-01 R2-4 — add Zylos 6-pattern taxonomy + small/large judge guidance (KB r2-zylos-llm-judge)"
token_budget: 4200
---

## When to Use
Dual adversarial code review — 2× `code-review-agent`, blind, verdict synthesis. ROJA-zone only.

## Rules

1. ROJA only — skip AMARILLA/VERDE
2. Blind separation — no cross-contamination
3. Max 2 re-judge → ASK user
4. Identical profiles → force second "security"
5. FIX/BLOCKER → `external-auditor`
6. Block push ROJA until JD clearance

## Protocol

### P0: Zone Filter
`review-rules.jsonc` → strip JSONC (3-pass: `//`, `/* */`). ROJA→dual, AMARILLA→single, VERDE→skip.

### P1: Profiles → 2× code-review-agent
Parse `jd_profile_selector` (ordered, first-match): `match=path|basename|fallback`. Missing→"architect". Identical→`[profile, "security"]`. 2 parallel, each `"## Profile Focus\n{instructions}"`. Blind. 120s timeout, retry once.

### P2: Synthesize

| Scenario | Verdict |
|----------|---------|
| Both CLEAN | APPROVED |
| Same root-cause (file ±5 lines) | Confirmed |
| Different findings | Triage → fix → re-judge |
| Re-judge | Max 2 rounds (diff delta only) |

### P3: Calibration
FIX/BLOCKER → `external-auditor` on diff. Gap >1.5 severity → `immune-system` permanent fix.

## Judge Patterns Taxonomy (R2-4 — Zylos 2026-04-10, 6 patterns)

| # | Pattern | Latency/Cost | When (JD mapping) |
|---|---------|--------------|-------------------|
| 1 | Offline eval | async, large judge OK | This skill (ROJA dual blind) |
| 2 | Online runtime verifier | 76–162ms budget, small judge (Luna-2 3–8B, Prometheus 7B, Lynx 8B ≈97% cheaper at 0.88–0.95 acc) | ROJA hotfix fast-path (optional, not default) |
| 3 | Self-consistency / self-critique | Best-of-N + majority vote, cheapest, strongest in code/math | Our 2-profile blind → implicit majority-of-2 |
| 4 | Reflexion | Only with external grounding (tests, git diff, retrieval) — intrinsic "check your work" degrades reasoning | Re-judge delta (max 2 rounds) already grounded on diff |
| 5 | Constitutional / RLAIF | training-time; runtime = generate→critique against constitution→revise | Gap >1.5 → immune-system (constitution for ROJA repeats) |
| 6 | Inference-time reward model | ranker over N samples, gated before output | Future: pre-push reward ranker (not yet wired) |

> **3-boundary rule** (Zylos): instrument judges before (a) user-facing output, (b) irreversible tool exec (`git push`, file Write), (c) persistent memory writes (Engram). Skip per-step judging to manage cost. Our gate covers (a)+(b); (c) is future.

**Small vs Large judges:** large proprietary (GPT-4o, Claude 3.7) for high-stakes ROJA; small distilled for throughput inline. JD's two profiles should diverge on that axis when one is "reasoning" tier.

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "One reviewer is enough for ROJA" | Single perspective on ROJA diff | Must run 2× blind code-review-agent — any less is AMARILLA pattern |
| "Re-judge 3rd time will pass" | Re-judge count >2 | Max 2 → ASK user (rule 3); >2 means synthesis failed, not review |
| "External auditor not needed" | FIX/BLOCKER without `external-auditor` | `external-auditor` on diff before APPROVED (rule 5) |

## Red Flags
- Profiles not blind (second sees first's output) → cross-contamination, verdict invalid
- Verdict without `review-rules.jsonc` zone filter → zone misclassification

## Verification
- Synthesize table: Both CLEAN or Same root-cause (±5 lines) → Confirmed; else Triage→fix→re-judge
- `BLOCKER` without `.breaker-cleared` → gate blocks push until clearance

## Pipeline
`review-pipeline` Phase 2b for ROJA. Pre-commit #9: warn ROJA without JD.

## Output
```
JD-{target} | Profiles: {A}/{B} | 4R | Confirmed:N | JDGMNT: APPROVED/ESCALATED | CALIB: OK/GAP
```
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/judgment-day/reference.md

---
## Refs
Cross-Refs: code-review-agent | testing-strategy
