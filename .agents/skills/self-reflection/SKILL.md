---
name: self-reflection
description: Hermes closed learning loop. Reflect→learn→improve after tasks.
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.4"
triggers: task completion, session end, error patterns, "reflexioná", "aprendé de esto"
---

## CLOSED LOOP
**Observe → Reflect → Optimize → Apply** — after EVERY task + session end.

### Auto-Load Triggers
- **Session end** → siempre (step 0 de Session Close Protocol)
- **Post-task** → tasks con ≥3 tool calls o arch decisions
- **Error recovery** → después de bugfix + immune-system
- **Same error 2x** → before cataloging (capturar root cause primero)
- **User: "reflexioná" o "aprendé de esto"** → manual

### Per-Task
1. **CAPTURE**: worked? failed? → `mem_save`
2. **EXTRACT**: reusable? → decision tree
3. **EVALUATE**: root cause → `immune-system` + prevention
4. **APPLY**: update behavior (Engram + skill + AGENTS.md)
5. **SCORE**: `auto-metrics` 6 dims
6. **IMMUNIZE**: error or <7 → anti-pattern + AGENTS.md Rules

### EXTRACT Decision Tree
| Pregunta | Sí | No |
|----------|----|----|
| ¿Patrón repetido ≥2 veces? | skill-creator | update Engram |
| ¿Workflow ≥2 pasos? | skill-creator | update Engram |
| ¿Otros agentes beneficiados? | skill-creator | update Engram |
≥1 Sí → `skill-creator`. Si no → `mem_save(type="learning")`.

### Template (session/task end)
```
## Reflection
**Type**: [bugfix/design/audit/learning] · **Outcome**: [worked/partial/failed]
**Root cause**: [qué salió mal] · **Extracted**: [new skill? update? nothing]
**Score**: auto-metrics [X/100]
**Would change**: [qué harías diferente]
```
Save: `mem_save(type="learning", topic_key="reflection/{date}")`

### Periodic (~5 tools)
Self-check: consistent? repeating? underused? → auto-improve (delegate `skill-creator`)

## Triggers
Same fix 2x→skill · gotcha→doc skill · user corrected 2x→protocol · complex workflow→skill · pattern 3+ files→extract

## Type Reflection
Code: pattern? maintainable? tested? · Troubleshoot: enough info? correct diagnosis? · Design: reqs? tradeoffs? scalable? · Skill: own? update existing?

## Frustration Signals
See `recovery-protocol` frustration signals table.

## Post-Task Flow
AGENTS.md Post-Task: steps 1-3 (git status, suggest, immune). Hermes = step 4 (reflection) si task ≥3 tool calls.
