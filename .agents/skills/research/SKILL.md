---
name: research
description: "Structured research workflow for technical investigations — define scope, gather evidence, synthesize findings, document decisions"
triggers: "Research task, technical investigation, 'investigar', 'research', learn new tech, compare solutions, evaluate options"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

Trigger: "investigar", "research", "averiguar", "compare", "evaluate", "find the best", "learn about", "qué es mejor", "cómo funciona".

## When
Technology evaluation · Library comparison · Architecture research · Security audit research · Performance investigation · New domain exploration · Pre-PoC research · "Best practice" for unknown domain

## Research Workflow

### Phase 1: Scope (1-2 min)
Define BEFORE searching:
```
Goal: [one sentence — what must be decided or learned]
Constraints: [time, budget, existing stack, team expertise]
Output: [comparison table | recommendation | poc plan | summary]
Deadline: [when is this needed?]
```

### Phase 2: Gather (multiple sources)
Always consult at least 3 sources before concluding:
1. **Official docs** — what does the library/standard say about itself?
2. **Community** — GitHub issues, Stack Overflow, blog posts (filter by recent)
3. **Benchmarks** — performance, bundle size, API surface comparisons
4. **Migration cost** — what changes if we pick the wrong option?

### Phase 3: Synthesize
Format findings as structured decision input:
```
## Options
| Option | Pros (2 max) | Cons (2 max) | Cost |
|--------|-------------|-------------|------|
| A | ... | ... | ... |
| B | ... | ... | ... |

## Recommendation
[clear winner with rationale, confidence score 1-5]
```

### Phase 4: Decision
- If research → clear winner → capture via `decision-capture` skill
- If research → unclear → define what additional evidence is needed
- If research → dead end → document why and what NOT to pursue

## Research Depth Levels
| Level | When | Sources | Time |
|-------|------|---------|------|
| **Quick Scan** | Known domain, confirming choice | 2-3 sources | 5-10 min |
| **Moderate** | New domain, well-documented tech | 5-8 sources | 20-40 min |
| **Deep** | Critical architecture choice | 10+ sources + PoC | 1-4 hours |

## Anti-Patterns
- ❌ **Confirmation bias**: searching only for evidence that supports preconception
- ❌ **Documentation-only**: not checking real-world usage or issues
- ❌ **No deadline**: research expands to fill available time (Parkinson's Law)
- ❌ **Single source**: one blog post = not research
- ❌ **Old information**: tech moves fast — check dates on everything

## Commands
```bash
# Quick scan
websearch("$TOPIC 2026 comparison OR benchmark OR review" numResults=8)

# Deep research flow
webfetch("$OFFICIAL_DOCS_URL")
webfetch("$ALTERNATIVE_DOCS_URL")  
websearch("$TOPIC vs $ALTERNATIVE pros cons 2026" numResults=10)

# Evidence capture
mem_save(title="Research: $TOPIC findings" type="discovery"
  content="**What**: research findings on $TOPIC\n**Why**: $GOAL\n**Sources**: $URLS\n**Recommendation**: $WINNER\n**Confidence**: $SCORE")
