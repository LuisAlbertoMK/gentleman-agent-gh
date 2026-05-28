---
name: skill-digestion
description: > Compact skills on load + audit which skills resolve and their effectiveness.
  Trigger: Loading skills, after task completion, "qué skills usaste", skill audit.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## SKILL DIGESTION (compact on load)

When loading a skill, extract ONLY what's needed — don't load the full skill into context.

### How to digest
1. Match skill description to current task context
2. Load only: **Critical Patterns** + **Decision Tree** + **Commands** (skip background, examples, philosophy)
3. If skill has no explicit decision tree → extract the core rules only
4. If token budget is tight → load only the Rules/Patterns section

### Token preservation rules
| If context is... | Load strategy |
|-----------------|---------------|
| <60% window | Load full skill |
| 60-80% (YELLOW) | Load only: rules + decision tree (skip examples/background) |
| >80% (RED) | Load only: 1-line summary + critical rules |

## SKILL RESOLUTION FEEDBACK (audit)

After completing a task, track which skills were loaded and their effectiveness.

### Log format (Engram)
```
title: "Skill resolution: {skill-name}"
type: learning
content:
  **Skill**: {name}
  **Trigger**: {context that loaded it}
  **Applied**: YES/NO
  **Effective**: YES/PARTIAL/NO
  **Notes**: what worked, what didn't, what was missing
```

### When to log
- After task completion if a skill was loaded
- When a skill was NOT helpful (indicates gap)
- When you had to work around missing instructions (indicates need for new skill)

### Auto-improvement triggers
| Signal | Action |
|--------|--------|
| Skill loaded but NOT applied | Review trigger — too broad? |
| Skill applied but NOT effective | Update skill with better patterns |
| Had to improvise missing guidance | Create new skill |
| Same skill loaded 3+ times in session | Flag as heavy — consider digesting more aggressively |
