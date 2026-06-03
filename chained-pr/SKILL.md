---
name: chained-pr
description: > Split oversized changes into chained PRs.
  Trigger: PR >400 lines, stacked PRs, review slices, SDD workload forecast.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## HARD RULES
- Split PRs >400 lines unless maintainer accepts `size:exception`
- Each PR ≤60min review budget · one deliverable work unit per PR
- Tests/docs stay with the unit they verify
- State: start, end, prior deps, follow-up, out-of-scope in every chained PR
- Every child PR includes dependency diagram marking current PR with 📍
- Never mix chain strategies after user chooses

## DECISION GATES
| Condition | Action |
|---|---|
| PR ≤400 lines, focused | Single PR |
| PR >400, each slice independent | Stacked PRs to main |
| PR >400, feature must integrate before main | Feature Branch Chain with tracker PR |
| Vendor/migration diff can't split | Ask maintainer for `size:exception` |

## STRATEGIES
**Stacked PRs (to main)**: PR#1→main, PR#2→main, PR#3→main. Each independent.
**Feature Branch Chain**: draft tracker PR (no-merge). PR#1→tracker, PR#2→PR#1, PR#3→PR#2. Tracker merges to main last.

## OUTPUT
Strategy, PR order, current PR boundary, dependency diagram, review budget (`adds+dels`), verification plan.
