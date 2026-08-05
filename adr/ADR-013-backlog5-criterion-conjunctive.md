# ADR-013: Backlog item 5 done-criterion is conjunctive

- **Status**: Accepted · **Date**: 2026-08-04 · **Type**: process/clarification
- **Context**: R10 agent kept CYCLE.md backlog item 5 "Skill compression" as 🔴 Pending; the docs auditor read the done-criterion as only "0 skills >3KB" (already met).
- **Decision**: The criterion is CONJUNCTIVE — "0 skills >3KB, avg <2.0KB" (CYCLE.md:21). Live avg = 2,516B > 2,000B → item correctly stays Pending. CYCLE.md:43 metrics line already updated to "avg 2.5KB, 0 >3KB ✓" (commit 2888c678).
- **Alternatives**: Mark item done on the "0 >3KB" half alone — rejected: would be a false-done.
- **Consequences**: Item 5 remains pending until avg ≤2,000B; prevents false-done re-litigation; the backlog integrity check must parse BOTH halves of the criterion.
- **Refs**: `CYCLE.md:21`, `CYCLE.md:43`; commit `2888c678`.