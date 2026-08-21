---
name: judgment-day
description: "Dual adversarial review orchestrator — 2 profile-scoped code-review-agent instances, verdict synthesis"
triggers: "Judgment day, JD, dual review, juzgar, adversarial review"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1942
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
