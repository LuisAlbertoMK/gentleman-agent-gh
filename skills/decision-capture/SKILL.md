---
name: decision-capture
description: >  decision-capture skill
triggers: "Decision capture, trade-off log"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

Trigger: "voy a usar", "decido", "la mejor opciÃ³n", trade-off analysis, architecture choice, pattern selection.
## WhenChoosing library/framework Â· Architecture decision Â· Trade-off evaluation Â· Pattern selection Â· Structure change Â· Any decision with alternatives
## Rules
### 1. Automatic Capture â€” EVERY technical decision loggedMUST call `mem_save` BEFORE continuing for:- Library/tool selection- Architecture pattern (hexagonal/clean/microservices)- DB schema/storage choice- API design (REST vs GraphQL)- Testing approach- Config/env setup- Project structure/naming
### 2. Format â€” mandatory structure
```title: "{Verb} {what} â€” {context}"type: decisioncontent:  **What**: [one sentence â€” decided]  **Why**: [problem solved, trade-offs]  **Options considered**: [alternatives, max 3]  **Chosen**: [selected + why it won]  **Where affected**: [files/dirs impacted]  **Learned**: [gotchas, caveats]```
### 3. Retroactive CapturePast decision not logged? Capture before making NEW dependent decisions. Mark `type: decision` with "retroactive" note.
### 4. Session-end CheckBefore ending session: were decisions made? ALL captured? If missing â†’ capture now.
## Decision Tree
```Making technical choice:â”œâ”€â”€ Decision with alternatives? â†’ YES: mem_save | NO: skip (trivial)â”œâ”€â”€ Similar decision logged this session? â†’ YES: update existing | NO: newâ””â”€â”€ Session end â†’ check journal â†’ missing? â†’ capture retroactively```
## Examples
```âœ… title: "Chose SQLite over PostgreSQL for local agent memory"   Why: zero infra, single-file, no pool. Options: PG(overkill), SQLite(fits), BoltDB(less ecosystem)   Chosen: SQLite â€” best ecosystem, FTS5, Go driversâŒ title: "Used SQLite" | Why: "it's fine" â€” NO trade-offs, NO context```
## Commands
```bashmem_save(title="Chose {X} over {Y}", type="decision",  content="**What**: ...\n**Why**: ...\n**Options**: ...\n**Chosen**: ...\n**Where**: ...\n**Learned**: ...")# Session-end: mem_search(type="decision") â†’ verify all captured```
