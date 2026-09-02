---
name: state-reconcile
description: "Reconcile plan/backlog docs vs git reality before ANY status claim — kills stale 'pending' claims"
triggers: "state reconcile, plan sync, plan stale, backlog verify, que falta, pendiente, status claim, what's missing, plan drift"
changelog: "2026-09-02 — created: incident-driven (stale plan v3 doc -> false pending claims; git log --grep cross-check would have prevented)"
token_budget: 2800
---

## When to Use

- Before answering any question about what is pending/missing/done
  from a plan or gap doc

- Before declaring any backlog item implemented or not

- After implementing a plan item (update plan doc status
  in the SAME commit)

- When a plan doc's last commit predates recent commits
  touching its items


## Rules

1. EXTRACT item IDs from the plan doc (P0-2, R2-4, GAP-N,
   phase names) into a checklist

2. CROSS-CHECK each ID against reality:
   `git log --all --oneline --grep "<id>"` +
   `Test-Path` for claimed artifacts +
   grep for feature marker.
   One batched command per check, not per item.

3. VERDICT MATRIX:
   - pending + no evidence = truly pending
   - pending + evidence = DOC STALE -> fix row
   - done + no evidence = `confidence: unvalidated`

4. Every claim cites file:line OR commit hash OR
   command output. No exceptions. Use
   high/medium/low/unvalidated per claim.

5. POST-IMPLEMENTATION: update plan doc status/checkbox
   in same commit as implementation.
   One commit stale = defect, not nuance.


## Verification

- Format:
  `RECONCILED: {n} items | confirmed-pending: {k} | doc-stale: {s} | unvalidated: {u}`

- Every row has evidence ref (file:line, commit, or cmd output)

- No claim without confidence marker

- `doc-stale` > 0 -> fix doc in same turn

- One batched `git log` + one `Test-Path`/grep per check


## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|---|---|---|
| "The plan doc is the source of truth" | Doc-only claims | git log + Test-Path = truth, doc = cache |
| "I read this doc recently" | No re-check after new commits | Re-run if any commit landed since |
| "Cross-checking all items is slow" | Skip 'obviously done' | One git log batch - seconds |
| "Doc update can wait for a docs commit" | Impl lands, doc stale | Same-commit rule 5 - 2026-09-02 incident |
| "BITACORA says it, so it is done" | BITACORA vs plan mismatch | BITACORA = intent, git log = proof |

## Red Flags

- Plan doc `last_updated`/queue predates commits in same area

- Queue items listed without commit refs

- Two sources disagree silently (doc vs git vs BITACORA)

- BITACORA and plan doc tell different stories

- Status answer without `git log --grep` or `Test-Path`

- Doc says pending but artifact file exists on disk


## Refs

Cross-Refs: analysis-mode | evidence workflow in
  docs/mejoras/README.md:92-97 | ANTI-PATTERN-CATALOG.md #57
  (stale state sources) | incident Engram id 532

> docs/skills/state-reconcile/reference.md

---
