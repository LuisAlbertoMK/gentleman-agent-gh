---
name: chained-pr
description: > Split oversized changes into chained PRs.
  Trigger: PR >400 lines, stacked PRs, review slices, SDD workload forecast.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## RULES
- Split >400 lines unless `size:exception` accepted
- ≤60min review budget · one work unit per PR
- Tests/docs with unit · state start/end/deps/follow-up/OoS
- Every child PR: dependency diagram marking current 📍
- Never mix strategies

## GATES
| PR condition | Strategy |
|---|---|
| ≤400 lines | Single PR |
| >400, slices independent | Stacked (PR#i→main) |
| >400, needs integration | Feature Branch Chain (tracker→PR#1→PR#2…) |
| Can't split | Ask `size:exception` |

## OUTPUT
Strategy, PR order, boundary, dep diagram, review budget (`adds+dels`), verification.
