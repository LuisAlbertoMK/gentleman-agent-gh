---
name: sdd-init
description: >
  Initialize SDD context. Triggers: "sdd init", "iniciar sdd", "openspec init".
---

## Detect

### 1. Stack
- package.json, go.mod, pyproject.toml
- linters, test frameworks, CI

### 2. Testing
- Unit test framework
- Mock patterns
- Coverage tool

### 3. Persistence
- engram: mem_save → no openspec/
- openspec: follow _shared/*.md
- hybrid: both
- none: return without write

## mem_save Format
```
mem_save(
  title: "sdd-init/{project}",
  topic_key: "sdd-init/{project}",
  type: "architecture",
  project: "{project}",
  content: "{detected context}"
)
```

* sdd-init v2.0 — Karpathy Optimized *