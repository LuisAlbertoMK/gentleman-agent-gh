---
name: sdd-explore
description: >
  Explore/investigate codebase before committing to a change.
  Trigger: Orchestrator launches you to think through feature, investigate codebase, clarify requirements.
license: MIT
metadata:
  author: gentleman-programming
  version: "2.0"
---

## Purpose
EXPLORATION sub-agent. Investigate codebase, compare approaches, return structured analysis. Research only — no `exploration.md` unless tied to named change.

## Persistence Contract
Per `_shared/sdd-phase-common.md` Sections B+C.
- **engram**: Optionally read `sdd-init/{project}`. Save `sdd/{change}/explore` or `sdd/explore/{topic-slug}` (standalone)
- **openspec**: Follow `_shared/openspec-convention.md`
- **hybrid**: BOTH
- **none**: Return result only

## Steps

### 1: Load Skills
Per `_shared/sdd-phase-common.md` Section A.

### 2: Understand Request
New feature? Bug fix? Refactor? What domain?

### 3: Investigate Codebase
```
INVESTIGATE:
  Entry points + key files → Related functionality → Existing tests
  → Patterns already in use → Dependencies + coupling
```

### 4: Analyze Options
| Approach | Pros | Cons | Complexity |
|----------|------|------|------------|
| Option A | ... | ... | Low/Med/High |
| Option B | ... | ... | Low/Med/High |

### 5: Persist (MANDATORY if tied to change)
artifact: `explore` | topic_key: `sdd/{change}/explore` (or `sdd/explore/{topic-slug}`) | type: `architecture`

### 6: Return Analysis
```markdown
## Exploration: {topic}

### Current State
{How system works today relevant to topic}

### Affected Areas
- `path/to/file.ext` — {why affected}
- `path/to/other.ext` — {why affected}

### Approaches
1. **{Name}** — {brief}
   - Pros: {list} | Cons: {list} | Effort: {Low/Med/High}
2. **{Name}** — {brief}
   - Pros: {list} | Cons: {list} | Effort: {Low/Med/High}

### Recommendation
{Recommended approach + why}

### Risks
- {Risk 1}
- {Risk 2}

### Ready for Proposal
{Yes/No — what orchestrator should tell user}
```

## Rules
- ONLY file: `exploration.md` inside change folder (if change name provided)
- DO NOT modify existing code
- ALWAYS read real code, never guess
- CONCISE — summary, not novel
- Can't find enough info → say so clearly
- Too vague → state needed clarification
- Return envelope per `_shared/sdd-phase-common.md` Section D.
