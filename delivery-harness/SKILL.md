---
name: delivery-harness
description: > Review workload optimization + delivery strategy selection.
  Trigger: Before PR creation, planning delivery, "cómo entrego esto", PR size, review strategy.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## REVIEW WORKLOAD OPTIMIZATION

Before creating a PR, think about the human reviewer. Optimize for their cognitive load.

### PR size rules
| Size | Files | Review time | Strategy |
|------|-------|-------------|----------|
| SMALL | 1-3 files | <10 min | Direct PR |
| MEDIUM | 4-8 files | 10-30 min | Chunk into logical commits |
| LARGE | 9-15 files | 30-60 min | Split into stacked PRs |
| XL | 16+ files | >60 min | MUST split — do NOT commit as one |

### Chunking strategies
```
Large change:
├── Can be split by feature? → Stacked PRs (each independently reviewable)
├── Can be split by layer? → Backend PR + Frontend PR
├── Can be split by risk? → Safe refactor PR + risky logic PR
└── Cannot split? → Add detailed PR description with per-file rationale
```

### PR description must include
- **What**: 1-line summary of what this PR does
- **Why**: Problem being solved
- **How**: Brief technical approach
- **Risk**: Low/Medium/High + what could break
- **Test plan**: How to verify
- **Review notes**: What to focus on, what to ignore

## DELIVERY STRATEGY

Choose delivery strategy based on change characteristics.

| Strategy | When | How |
|----------|------|-----|
| **DIRECT** | Small, safe, well-understood | One PR, merge directly |
| **PHASED** | Medium complexity, multiple concerns | 2-3 stacked PRs, merge in order |
| **FEATURE FLAG** | High risk, needs gradual rollout | Code behind flag, enable later |
| **EXPERIMENTAL** | Exploratory, unsure of approach | Draft PR, ask for feedback, iterate |
| **BATCH** | Many small independent changes | Group by area, one PR per area |

### Decision tree
```
About to deliver change:
├── <4 files AND safe? → DIRECT
├── Multiple concerns? → PHASED (stacked PRs)
├── High risk / needs gradual rollout? → FEATURE FLAG
├── Exploratory / need feedback? → EXPERIMENTAL (draft PR)
└── Many small fixes in same area? → BATCH by area
```

## COMMANDS
```bash
# Estimate PR size before creating:
# git diff --stat main..HEAD  → count files
# If >8 files → consider splitting

# Create phased delivery:
# gh pr create --title "feat(scope): part 1/N" --body "..."
# gh pr create --title "feat(scope): part 2/N" --body "Depends on #N"
```
