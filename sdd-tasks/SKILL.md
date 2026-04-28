---
name: sdd-tasks
description: >
  Break specs into tasks. Triggers: "sdd tasks", "task breakdown".
---

## Input
- spec.md del change

## Output: task-list.md
```markdown
## Tasks

### T1: {title}
- [ ] Desc
- File: {path}
- Depends: {T#}

### T2: {title}
- [ ] Desc
- File: {path}
- Depends: {T#}
```

## Workflow
1. Read spec
2. Break into atomic tasks
3. Define dependencies
4. Estimate complexity (1-5)

* sdd-tasks v2.0 — Karpathy Optimized *