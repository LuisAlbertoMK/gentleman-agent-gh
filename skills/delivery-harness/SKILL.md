---
name: delivery-harness
description: >
  delivery-harness skill
triggers: "Delivery harness, review workload"
  Trigger: Before PR, planning delivery, "cómo entrego esto", PR size.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

## REVIEW WORKLOAD
Optimize for human reviewer. PR size determines strategy:

| Size | Files | Strategy |
|------|-------|----------|
| SMALL | 1-3 | Direct PR |
| MEDIUM | 4-8 | Chunk into logical commits |
| LARGE | 9-15 | Stacked PRs |
| XL | 16+ | MUST split |

### Chunking
`Large change → split by: feature? → stacked PRs | layer? → separate PRs | risk? → safe first`

### PR description
**What** + **Why** + **How** + **Risk**(L/M/H) + **Test plan** + **Review notes**(focus areas)

## DELIVERY STRATEGY
| Strategy | When | How |
|----------|------|-----|
| DIRECT | Small, safe | One PR |
| PHASED | Multiple concerns | Stacked PRs, merge in order |
| FEATURE FLAG | High risk, gradual rollout | Code behind flag |
| EXPERIMENTAL | Exploratory | Draft PR for feedback |
| BATCH | Many independent | Group by area |

### Decision tree
```
Change → <4 files+safe?→DIRECT | Multiple concerns?→PHASED
         High risk?→FEATURE FLAG | Exploratory?→EXPERIMENTAL
         Many small?→BATCH
```

## CHAIN STRATEGY (stacked branches)
When stacking PRs, each PR must:
1. Target the PREVIOUS PR's branch (not main)
2. Have clear dependency in description: `Depends on #N`
3. Be independently reviewable
4. Merge bottom-up (first PR first)

```
main ← PR#1 (feat/auth) ← PR#2 (feat/dashboard) ← PR#3 (feat/settings)
          merge 1st         merge 2nd              merge 3rd
```

## COMMANDS
```bash
# git diff --stat main..HEAD → count files to estimate size
# gh pr create --title "feat(x): part 1/N" --body "Depends on #N"
```

