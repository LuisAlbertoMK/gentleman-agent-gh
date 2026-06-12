---
name: decision-capture
description: > Proactive architecture/design decision logging to Engram. Auto-triggers when agent makes a technical choice.
  Trigger: "voy a usar", "decido", "la mejor opción", trade-off analysis, architecture choice, pattern selection.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

## When
Choosing library/framework · Architecture decision · Trade-off evaluation · Pattern selection · Structure change · Any decision with alternatives

## Rules

### 1. Automatic Capture — EVERY technical decision logged
MUST call `mem_save` BEFORE continuing for:
- Library/tool selection
- Architecture pattern (hexagonal/clean/microservices)
- DB schema/storage choice
- API design (REST vs GraphQL)
- Testing approach
- Config/env setup
- Project structure/naming

### 2. Format — mandatory structure
```
title: "{Verb} {what} — {context}"
type: decision
content:
  **What**: [one sentence — decided]
  **Why**: [problem solved, trade-offs]
  **Options considered**: [alternatives, max 3]
  **Chosen**: [selected + why it won]
  **Where affected**: [files/dirs impacted]
  **Learned**: [gotchas, caveats]
```

### 3. Retroactive Capture
Past decision not logged? Capture before making NEW dependent decisions. Mark `type: decision` with "retroactive" note.

### 4. Session-end Check
Before ending session: were decisions made? ALL captured? If missing → capture now.

## Decision Tree
```
Making technical choice:
├── Decision with alternatives? → YES: mem_save | NO: skip (trivial)
├── Similar decision logged this session? → YES: update existing | NO: new
└── Session end → check journal → missing? → capture retroactively
```

## Examples
```
✅ title: "Chose SQLite over PostgreSQL for local agent memory"
   Why: zero infra, single-file, no pool. Options: PG(overkill), SQLite(fits), BoltDB(less ecosystem)
   Chosen: SQLite — best ecosystem, FTS5, Go drivers

❌ title: "Used SQLite" | Why: "it's fine" — NO trade-offs, NO context
```

## Commands
```bash
mem_save(title="Chose {X} over {Y}", type="decision",
  content="**What**: ...\n**Why**: ...\n**Options**: ...\n**Chosen**: ...\n**Where**: ...\n**Learned**: ...")
# Session-end: mem_search(type="decision") → verify all captured
```
