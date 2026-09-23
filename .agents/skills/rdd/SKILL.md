---
name: rdd
description: "Receipt-Driven Development — freeze candidate → risk-tiered review → receipt. Delivery stays human-owned."
triggers: "rdd, receipt-driven, freeze, receipt-driven development, review after change"
changelog: docs/ciclos/cycle30-20260917.md
token_budget: 3900
---
## RDD Contract

**Opt-in. Off by default.** Enable via `!rdd on` or skill config.

RDD = freeze → risk-tiered review → receipt. Delivery human-owned.

## Freeze

Freeze = reproducible snapshot (NOT a branch/stash).

| Component | Source | Length |
|-----------|--------|--------|
| `HEAD_ref` | `git rev-parse --short HEAD` | ≤12 chars (--short default, ~7-8) |
| `diff_hash` | `git diff HEAD \| git hash-object --stdin` | 8 chars |

Output: `HEAD-{7-8}-{8}` (e.g. `HEAD-a1b2c3d-9f8e7d6c`)

**No `-w` flag.** No side effects (no stash, no commit).

## Risk Tiers

| Tier | Trigger | Review | Fix Budget |
|------|---------|--------|------------|
| 0 | ≤50L code; ≤150L docs-only 1-file, no schema/auth/API | Direct (no review) | None |
| 1 | (a) 1-5 files ≤100L non-sensitive; OR (b) 50-200L shared module, no auth/schema | 4R (code-review-agent) | max 1 fix opt-in |
| 2 | >5 files OR >200L OR schema/auth/API/deps | 4R BLOCKER-capable | FAIL→judgment-day |

## Review Flow

```
start → capture → finalize → validate
```

| Gate | When | Validates |
|------|------|-----------|
| post-apply | After code change | diff matches freeze, 4R pass |
| pre-commit | `git commit` | freeze snapshot still valid |
| pre-push | `git push` | all prior gates pass |
| pre-pr | PR creation | full 4R + tier 2 escalation |
| release | Deploy/release | human approval if tier 2 |

## 4R Wrapper

Wraps `code-review-agent` 4R. Same scoring: Risk/Readability/Reliability/Resilience.

PASS = all R≥7. WARN = any 4-6. FAIL = any <4. BLOCKER = any R<4.

FAIL + tier 2 → escalate to `judgment-day`. Never auto-fix on FAIL.

## Rules

1. Freeze BEFORE any code change — no exceptions
2. Tier 0 skips review but still freezes (audit trail)
3. Tier 1: 1 opt-in fix max — don't scope-creep
4. Tier 2: BLOCKER = stop. Escalate. Never auto-fix.
5. Stale freeze → re-freeze + re-review (scope-changed recovery)
6. Receipt required: `rdd-receipt-{id}.json` with freeze, tier, verdict, files
7. Human parity: negotiated envelope for tier 2 decisions

## Recovery

| Situation | Action |
|-----------|--------|
| scope-changed | Re-freeze at current HEAD, re-run tier assessment |
| stale snapshot | Warn + re-freeze. Previous review voided. |
| review.status = FAIL | STOP. Escalate per tier. No fallback. |

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skip freeze, change is trivial" | No HEAD ref in receipt | `git rev-parse --short HEAD` captured before edit; no freeze → BLOCK |
| "Auto-fix tier 2 to save time" | Fix applied without judgment-day | Tier 2 FAIL → STOP, escalate to judgment-day, never auto-fix |

## Red Flags
- Tier 2 FAIL auto-fixed without judgment-day → STOP, revert + escalate (rule: never auto-fix)
- Stale freeze reused after scope change → STOP, re-freeze + re-review

## Verification
- Receipt `rdd-receipt-{id}.json` carries freeze `HEAD-{7-8}-{8}` + tier + 4R verdict + files
- `git diff HEAD | git hash-object --stdin` matches frozen diff_hash at each gate

## Anti-patterns

| Pattern | Detection | Fix |
|---------|-----------|-----|
| Skipping freeze | No HEAD ref in receipt | Block; require freeze first |
| Auto-fix tier 2 | Fix applied without judgment-day | Revert; escalate |
| Stale review | freeze hash mismatch | Re-freeze + re-review |

## Refs
code-review-agent | judgment-day | quality-gate | triple-verify

## Reference
Examples + receipt schema + recovery → {file:rdd/reference.md}
