---
name: decision-capture
description: >
  Proactive architecture/design decision logging to Engram. Auto-triggers when agent makes a technical choice.
  Trigger: "voy a usar", "decido", "la mejor opción", trade-off analysis, architecture choice, pattern selection.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When
Choosing a library/framework · Making an architecture decision · Evaluating trade-offs · Selecting a pattern · Changing project structure · Any decision with alternatives considered

## Critical Patterns

### 1. Automatic Capture — every technical decision MUST be logged
When the agent makes ANY of these decisions, it MUST call `mem_save` BEFORE continuing:
- Library or tool selection ("usemos X", "voy con Y")
- Architecture pattern ("hexagonal", "clean", "microservices")
- Database schema or storage choice
- API design decision (REST vs GraphQL, endpoint structure)
- Testing approach or tool
- Configuration or environment setup
- Project structure or naming conventions

### 2. Capture Format — mandatory structure
Every decision logged in Engram MUST use this exact format:
```
title: "{Verb} {what} — {context}"
type: decision
content:
  **What**: [One sentence — what was decided]
  **Why**: [The problem it solves, trade-offs considered]
  **Options considered**: [Alternative approaches, max 3]
  **Chosen**: [The selected option and why it won]
  **Where affected**: [Files, directories, or systems impacted by this decision]
  **Learned**: [Gotchas, caveats, or things to watch out for]
```

### 3. Retroactive Capture — decisions already made
If the agent realizes a previous decision was NOT logged:
- Capture it retroactively before making NEW decisions that depend on it
- Mark as `type: decision` with note "retroactive" in content

### 4. Decision Journal
Before ending a session, the agent MUST check:
- Were any technical decisions made this session?
- Were ALL of them captured via `mem_save`?
- If not → capture before session end

## Decision Tree
```
Agent about to make a technical choice:
├── Is this a decision with alternatives?
│   ├── YES → MUST log via mem_save
│   └── NO → trivial (e.g., variable name) → skip
│
├── Have I already logged a similar decision this session?
│   ├── YES → check if context changed → update existing
│   └── NO → new decision → log fresh
│
└── Before session end:
    └── Check decision journal → any missing? → capture now
```

## Examples
```
# Good capture — trade-offs explicit
title: "Chose SQLite over PostgreSQL for local agent memory"
type: decision
content:
  **What**: Switched from PostgreSQL to SQLite for Engram persistence
  **Why**: Zero infra, single-file backup, no connection pool for local use
  **Options considered**: PostgreSQL (overkill for single-user), SQLite (fits), BoltDB (less ecosystem)
  **Chosen**: SQLite — best ecosystem support, FTS5 built-in, Go has superb drivers
  **Where affected**: internal/store/store.go, go.mod, schema definitions
  **Learned**: SQLite write concurrency is fine for single-user; WAL mode is essential

# Bad capture — no trade-offs, no why
title: "Used SQLite"
type: decision
content:
  **What**: Used SQLite
  **Why**: It's fine
  **Where affected**: store.go
```

## Commands
```bash
# Capture a decision immediately:
mem_save(
  title="Chose {X} over {Y}",
  type="decision"
  content="**What**: ...\n**Why**: ...\n**Options considered**: ...\n**Chosen**: ...\n**Where affected**: ...\n**Learned**: ..."
)

# Session-end check:
# mem_search(type="decision") → verify all captured
# If missing → capture retroactively
```
