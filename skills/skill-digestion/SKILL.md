---
name: skill-digestion
description: > Compact skills on load + audit skill resolution effectiveness.
  Trigger: Loading skills, after task completion, skill audit.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

## DIGEST ON LOAD
Extract only what's needed. Skip background/examples when context is tight.

| Context | Load strategy |
|---------|--------------|
| <60% | Full skill |
| 60-80% (YELLOW) | Rules + decision tree only |
| >80% (RED) | 1-line summary + critical rules |

**How**: match skill→context → load Critical Patterns + Decision Tree + Commands.

## RESOLUTION FEEDBACK (post-task)
Log to Engram after task if skill was loaded:
```
title: "Skill resolution: {name}"
type: learning
content: Skill | Trigger | Applied(Y/N) | Effective(Y/P/N) | Notes
```

## AUTO-IMPROVEMENT TRIGGERS
| Signal | Action |
|--------|--------|
| Loaded but NOT applied | Trigger too broad? narrow it |
| Applied but NOT effective | Update skill patterns |
| Improvised missing guidance | Create new skill |
| Same skill loaded 3+ times | Flag heavy — digest more |
