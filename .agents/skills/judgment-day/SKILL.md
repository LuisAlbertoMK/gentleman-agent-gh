---
name: judgment-day
description: "Dual adversarial review orchestrator — 2 profile-scoped code-review-agent instances, verdict synthesis"
triggers: "Judgment day, JD, dual review, juzgar, adversarial review"
license: Apache-2.0
metadata:
  tags: [engineering, review, orchestrator]
  author: gentleman-vMK
  version: "3.2"
  changelog: "3.1->3.2: Karpathy compression — merged redundancies, trimmed prose"
  config_refs: review-rules.jsonc
  dependencies: [code-review-agent]
---
<!-- karpathy-compressed: 2026-07-10 -->

# Judgment Day

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

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| JD on VERDE | Zone filter |
| Same profile both | Force second "security" |
| Cross-contamination | Blind, no shared context |
| 3+ re-judge | Cap 2 → ASK |
| Skip FIX calibration | → external-auditor |
| Push ROJA no JD | Block |

## Refs
- [code-review-agent](../code-review-agent/SKILL.md) · [external-auditor](../external-auditor/SKILL.md) · [immune-system](../immune-system/SKILL.md) · [quality-gate](../quality-gate/SKILL.md) · `review-rules.jsonc`
