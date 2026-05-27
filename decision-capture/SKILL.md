---
name: decision-capture
description: >
  Proactive architecture/design decision logging to Engram. Auto-triggers when agent makes a technical choice.
  Trigger: "voy a usar", "decido", "la mejor opción", trade-off analysis, architecture choice, pattern selection.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## When
Library/tool choice · Architecture decision · Trade-off eval · Pattern selection · Structure change · Any decision w/ alternatives

## Mandatory Capture
ANY technical decision MUST call `mem_save` BEFORE continuing:
- Lib selection · Architecture pattern · DB/storage choice · API design (REST vs GraphQL) · Test approach · Config/env setup · Project structure · Naming conventions

## Capture Format
```
title: "{Verb} {what} — {context}"
type: decision
content:
  **What**: [one sentence]
  **Why**: [problem + trade-offs]
  **Options considered**: [max 3 alternatives]
  **Chosen**: [selected + why it won]
  **Where affected**: [files/dirs/systems]
  **Learned**: [gotchas, caveats]
```

## Retroactive Capture
Previous decision NOT logged → capture BEFORE making dependent decisions. Mark `type: decision` w/ "retroactive" note.

## Session-end Check
Before ending: `mem_search(type="decision")` → all captured? If missing → retroactive.

## Decision Tree
```
About to decide:
├── Decision w/ alternatives?
│   ├── YES → mem_save BEFORE proceeding
│   └── NO → trivial (var name) → skip
├── Similar decision already logged this session?
│   ├── YES → context changed? → update existing
│   └── NO → fresh capture
└── Session end → verify all captured
```
