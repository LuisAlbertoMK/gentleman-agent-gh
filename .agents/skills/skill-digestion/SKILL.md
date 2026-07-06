---
name: skill-digestion
description: "Digest skills on load — load only critical sections based on context budget, log resolution feedback, trigger auto-improvement"
triggers: "Skill digestion, compact on load"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.0"
---

Trigger: Loading skills, after task completion, skill audit.

## DIGEST ON LOAD — ENFORCED

Extract only what's needed. Skip background/examples when context is tight.

| Context | Load strategy | Token target |
|---------|--------------|--------------|
| <60% | Full skill | No limit |
| 60-80% (YELLOW) | Rules + decision tree only | ~300 tokens |
| >80% (RED) | 1-line summary + critical rules | ~100 tokens |

**How**: match skill→context → load Critical Patterns + Decision Tree + Commands.
**Enforcement**: When loading a skill, ALWAYS check context percentage first. If YELLOW/RED, truncate output accordingly.
## RESOLUTION FEEDBACK (post-task)Log to Engram after task if skill was loaded:
```title: "Skill resolution: {name}"type: learningcontent: Skill | Trigger | Applied(Y/N) | Effective(Y/P/N) | Notes```
## AUTO-IMPROVEMENT TRIGGERS| Signal | Action ||--------|--------|| Loaded but NOT applied | Trigger too broad? narrow it || Applied but NOT effective | Update skill patterns || Improvised missing guidance | Create new skill || Same skill loaded 3+ times | Flag heavy — digest more |
## EXAMPLE
```markdown
## Resolution: subagent-isolation
Applied: Yes | Effective: Yes | Notes: Used for parallel explore
```
## EDGE CASES
- Context <40% → load full skill (no digest needed)
- New skill first load → always load full (no usage data yet)
