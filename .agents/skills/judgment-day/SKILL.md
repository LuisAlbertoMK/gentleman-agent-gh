---
name: judgment-day
description: "Dual adversarial review orchestrator — 2 profile-scoped code-review-agent instances, verdict synthesis"
triggers: "Judgment day, JD, dual review, juzgar, adversarial review"
license: Apache-2.0
metadata:
  tags: [engineering, review, orchestrator]
  author: gentleman-vMK
  version: "3.1"
  changelog: "3.0->3.1: Added code examples, anti-patterns, cross-refs, clearer protocol steps"
  config_refs: review-rules.jsonc
  dependencies: [code-review-agent]
---
<!-- karpathy-compressed: 2026-07-09 -->

# Judgment Day

Dual adversarial code review — 2 independent `code-review-agent` instances with different profiles, blind separation, verdict synthesis. For ROJA-zone changes (security, auth, data-critical) — two reviewers catch what one misses.

## Rules

1. **Zone gate**: Only run JD on ROJA-zone changes — skip AMARILLA/VERDE
2. **Blind separation**: Reviewers MUST NOT share context — no cross-contamination
3. **Two max re-judge**: Hard cap at 2 re-judge cycles, then ASK user
4. **Profile diversity**: If profiles resolve identical, force second to "security"
5. **Calibrate required**: Every FIX/BLOCKER verdict → external-auditor
6. **No push without JD**: ROJA changes blocked until JD clearance

## Protocol

### P0: Zone Pre-Filter

Load `review-rules.jsonc` → strip JSONC comments (3-pass regex: `// line`, `// trailing`, `/* */ block`). Match changed files vs zones:

| Zone | Action |
|------|--------|
| ROJA (red) | Proceed with dual review |
| AMARILLA (yellow) | Skip — single `code-review-agent` sufficient |
| VERDE (green) | Skip — no review needed |

### P1: Resolve Profiles → Launch 2× code-review-agent

Parse `jd_profile_selector` (ordered array, first-match):
- `match=path`: glob against relative file path
- `match=basename`: glob against filename only
- `match=fallback`: use as default, first match wins

Validate profiles in `jd_profiles`. Missing → use "architect". Both identical → `[profile, "security"]`.

Launch 2 parallel `code-review-agent` instances, each injected with `"## Profile Focus\n{profile.instructions}"`. Blind — NO cross-contamination. 120s timeout per delegate, retry once on failure.

### P2: Synthesize Verdicts

| Scenario | Verdict |
|----------|---------|
| Both CLEAN | **APPROVED** |
| Same root-cause LOCATION (file + line ±5) | **Confirmed** |
| Different findings | **Triage** — synthesize, fix, re-judge |
| Re-judge | Pass diff delta only, max 2 rounds |

### P3: Calibration

If verdict is FIX/BLOCKER → route to `external-auditor` on final diff for blind second-opinion. Gap between reviewers > 1.5 on severity scale → route to `immune-system` for permanent fix.

## Pipeline Integration

- `review-pipeline` invokes JD for ROJA zone in Phase 2b
- Pre-commit check #9 warns if ROJA staged without JD clearance

## Output Format

```
JD-{target} | Profiles: {A}/{B} | 4R-delegated | Confirmed:N | JDGMNT: APPROVED/ESCALATED | CALIB: OK/GAP
```

## Example

```bash
# Launch judgment day on a changed file
jd_profile_selector='[
  {"match": "path", "value": "auth/*", "profile": "security"},
  {"match": "basename", "value": "*_test.go", "profile": "tester"},
  {"match": "fallback", "value": "architect"}
]'

# Output
JD-auth/login.ts | Profiles: security/architect | 4R-delegated | Confirmed:3 | JDGMNT: APPROVED | CALIB: OK
```

## Anti-Patterns

| Anti-Pattern | Why | Do Instead |
|---|---|---|
| Running JD on VERDE changes | Waste of tokens and time | Zone pre-filter → skip GREEN |
| Same profile for both reviewers | Blind spot duplication | If identical → force second to "security" |
| Cross-contaminating reviewers | Confirmation bias | Keep blind, no shared context |
| 3+ re-judge cycles | Diminishing returns, user frustration | Hard cap at 2, then ASK user |
| Skipping calibration on FIX | Fix may be incomplete | Always route FIX to external-auditor |
| Pushing ROJA without JD | Risking production issues | Block until JD clearance |

## Blocking Rules

- Max 2 re-judge cycles → then ASK user
- No push without JD on ROJA-zone changes

## Refs

- [code-review-agent](../code-review-agent/SKILL.md) — 4R review engine
- [external-auditor](../external-auditor/SKILL.md) — blind second-opinion calibration
- [immune-system](../immune-system/SKILL.md) — permanent fix for repeated issues
- [quality-gate](../quality-gate/SKILL.md) — pre-commit gate
- `review-rules.jsonc` — zone definitions and profile config
