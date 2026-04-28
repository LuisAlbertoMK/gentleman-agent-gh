---
name: sdd-apply
description: >
  Implement tasks from specs. Triggers: "sdd apply", "implement task".
---

## Input
- task-list.md
- spec.md
- design.md

## Workflow
1. Load skill (sdd-spec, sdd-design)
2. Execute each task
3. Auto-validate
4. Mark complete

## Validation
```
□ Code compiles?
□ Tests pass?
□ Matches spec?
□ No new lint errors?
```

* sdd-apply v2.0 — Karpathy Optimized *