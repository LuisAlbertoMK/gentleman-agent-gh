---
name: self-reflection
description: >
  Agent self-improvement via post-session reflection.
  Trigger: Session end, repetitive error patterns, agent detects own errors.
license: Apache-2.0
metadata:
  author: mk
  version: "1.0"
---

## When
Session end (auto-trigger) · Repetitive errors detected · User frustration ("same thing again") · Need to improve existing skills

## Reflection Cycle
```
Session → Reflection → Improvement → Next Session → (loop)
```

## Phase 1: Post-Session Capture
```markdown
## Post-Session Reflection
### What worked? [points]
### What to improve? [points]
### Errors made? [errors]
### Learned? [insights]
### Skills to update? [skill + reason]
```

## Phase 2: Pattern Analysis
```markdown
## Pattern Analysis
### Repetitive Errors
| Error | Frequency | Root Cause | Fix |
|-------|-----------|-----------|-----|
### Underutilized Skills
- [skill] → didn't load when needed
### Gaps Identified
- [gap] → create or improve skill
```

## Phase 3: Skill Improvement
1. Identify skill to improve
2. Analyze specific gap
3. Draft improvement
4. Verify with test cases
5. Apply change
6. Document in changelog

## Phase 4: Self-Correction
### During Session (every 10 mins)
- Following Karpathy method (short answers)?
- Is response necessary or can I be more concise?
- Detected user frustration?

### Frustration Signals
- "ya te dije que..." · "no es eso" · "otra vez lo mismo" · Short tone

**Action:**
1. Stop, acknowledge: "Disculpame, no entendí bien"
2. Ask explicit clarification
3. Update context with learning

## Reflection by Task Type
### Coding
□ Used correct pattern? □ Maintained project structure? □ Wrote tests? □ Maintainable?
### Troubleshooting
□ Enough info before diagnosing? □ Diagnosis correct? □ Solution worked? □ Root cause documented?
### Design
□ Understood requirements? □ Considered trade-offs? □ Scalable? □ Decisions documented?

## Auto-Update Persona
```markdown
## For this user:
- [discovered preferences]
- [technical level]
- [communication style]

Update in: ~/.config/opencode/AGENTS.md
```
