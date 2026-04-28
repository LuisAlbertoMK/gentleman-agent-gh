---
name: sdd-archive
description: >
  Archive completed change. Triggers: "sdd archive", "archive change".
---

## Input
- Completed change
- Verification report

## Archive
```markdown
# Change: {name}
## Completed: {date}
## Spec: {spec.md}
## Implementation: {files}
## Tests: {coverage}
## Learnings: {gotchas}
```

## Outputs
- Merge delta to main specs
- Clean change folder
- mem_save learnings

* sdd-archive v2.0 — Karpathy Optimized *