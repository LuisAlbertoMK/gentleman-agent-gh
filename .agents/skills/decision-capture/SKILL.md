---
name: decision-capture
description: "Capture every technical decision with structured format — alternatives, trade-offs, rationale, retroactive logging, and trend analysis"
triggers: "Decision capture, trade-off log, 'voy a usar', 'decido', architecture choice"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "2.0", changelog: "1.1->2.0: added scoring framework, trend analysis, retroactive prompts, conflict detection"
---

Trigger: "voy a usar", "decido", "la mejor opción", trade-off analysis, architecture choice, pattern selection, "por qué X y no Y", technology comparison.

## When
Choosing library/framework · Architecture decision · Trade-off evaluation · Pattern selection · Structure change · Any decision with alternatives · Rejecting established patterns · Dependency upgrades with risk

## Rules

### 1. Automatic Capture — EVERY technical decision MUST be logged
Call `mem_save` BEFORE continuing for:
- Library/tool selection (including abandonments)
- Architecture pattern (hexagonal/clean/microservices/monolith)
- DB schema/storage engine choice
- API design (REST vs GraphQL vs gRPC)
- Testing approach (strategy, framework, mocks vs real)
- Config/env setup
- Project structure/naming conventions
- Dependency version pinning with security implications

### 2. Format — mandatory structure
```
title: "{Verb} {what} — {context}"
type: decision
content:
  **What**: [one sentence — decided]
  **Why**: [problem solved, constraints, trade-offs weighed]
  **Options considered**: [alternatives, max 3 with 1-line each]
  **Chosen**: [selected + why it won + any downsides accepted]
  **Where affected**: [files/dirs/system boundaries impacted]
  **Learned**: [gotchas, caveats, things to revisit]
```

### 3. Scoring Framework — rate each decision 1-5
Append to every decision capture:
```
  **Confidence**: [1-5: 1=guess, 3=reasonable, 5=certain]
  **Reversibility cost**: [low|medium|high — can we undo this?]
  **Review date**: [YYYY-MM-DD — 3mo for high reversibility, 1mo for low]
```

### 4. Trend Detection
Every 5th decision in a session:
- Call `mem_search(type="decision")` 
- Look for repeated patterns (always picking same option? always avoiding same category?)
- If 3+ decisions trend same direction → `mem_save` a trend observation
- If reversing a prior decision → link via `topic_key` to original

### 5. Conflict Detection
Before saving a new decision:
- Check if same `topic_key` has a prior decision
- If reversing or conflicting with a past choice:
  - Keep both entries (don't overwrite — history matters)
  - Add `**Supersedes**: [ID or topic_key of prior decision]`
  - Add `**Reason for reversal**: [what changed since then]`

### 6. Retroactive Capture
Past decision not logged? Capture before making NEW dependent decisions.
Mark `type: decision` with `**Retroactive**: true` note.
Scan git log for unlogged decisions: `git log --oneline -20 | grep -iE 'feat|change|upgrade|migrate'`

### 7. Session-end Check
Before `mem_session_summary`: are decisions made? ALL captured?
If missing → capture now. Run: `mem_search(type="decision")` to verify.

## Decision Tree
```
Making technical choice:
├── Decision with alternatives? → YES: mem_save | NO: skip (trivial)
├── Similar decision logged this session? → YES: update existing | NO: new
├── Conflict with past decision? → YES: note supersedes + reversal reason
├── Session end → check journal → missing? → capture retroactively
└── Every 5th decision → trend check
```

## Scoring Reference
| Score | Meaning | Example |
|-------|---------|---------|
| 5 | Certain, known pattern | "Chose SQLite for single-user agent store" |
| 4 | Strong, minor unknowns | "Chose TanStack Query over SWR for cache layer" |
| 3 | Reasonable, needs review | "Chose PostgreSQL over SQLite for multi-user" |
| 2 | Educated guess | "Chose Redis for queue (never used in prod)" |
| 1 | Pure guess | "First time with this stack entirely" |

## Examples
```
✅ title: "Chose SQLite over PostgreSQL for local agent memory"
   Why: zero infra, single-file, no pool. Options: PG(overkill), SQLite(fits), BoltDB(less ecosystem)
   Chosen: SQLite — best ecosystem, FTS5, Go drivers
   Confidence: 5 | Reversibility: low

❌ title: "Used SQLite" | Why: "it's fine" — NO trade-offs, NO context
```

## Commands
```bash
# Standard capture
mem_save(title="Chose {X} over {Y}" type="decision"
  content="**What**: ...\n**Why**: ...\n**Options**: ...\n**Chosen**: ...\n**Where**: ...\n**Learned**: ...\n**Confidence**: 4\n**Reversibility cost**: low\n**Review date**: 2026-09-16")

# Trend check (every 5th)
mem_search(type="decision" limit=10)

# Retroactive from git
git log --oneline -20 | grep -iE 'feat|change|upgrade'
