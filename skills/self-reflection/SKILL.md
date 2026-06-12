---
name: self-reflection
description: Hermes closed learning loop. Reflect→learn→improve after tasks.
license: Apache-2.0
metadata: version: "2.3"
triggers: task completion, session end, error patterns, "reflexioná", "aprendé de esto"
---

## CLOSED LOOP
**Observe → Reflect → Optimize → Apply** — after EVERY task + session end.

### Auto-Load Triggers
Hermes se carga automáticamente cuando:
- **Session end** → siempre (step 0 de Session Close Protocol)
- **Post-task** → después de tasks con ≥3 tool calls o arch decisions
- **Error recovery** → después de bugfix + immune-system
- **Same error 2x** → before cataloging (capturar root cause primero)
- **User dice "reflexioná" o "aprendé de esto"** → manual

### Per-Task
1. **CAPTURE**: worked? failed? → `mem_save` 
2. **EXTRACT**: reusable? → decision tree abajo
3. **EVALUATE**: root cause → `immune-system` + prevention
4. **APPLY**: update behavior (Engram + skill + AGENTS.md)
5. **SCORE**: `auto-metrics` 6 dims
6. **IMMUNIZE**: error or <7 → anti-pattern + AGENTS.md Rules

### EXTRACT Decision Tree
¿Esto merece un skill nuevo? Respondé estas 3 preguntas:

| Pregunta | Sí → | No → |
|----------|------|------|
| ¿Es un patrón que repetiste ≥2 veces? | skill-creator | update Engram |
| ¿Es una workflow con ≥3 pasos? | skill-creator | update Engram |
| ¿Otros agentes se beneficiarían? | skill-creator | update Engram |

Si **≥2 respuestas Sí** → `skill-creator`. Si no → `mem_save(type="learning")`.

### Reflection Template
Al final de cada sesión o task grande:

```
## Reflection
**Type**: [bugfix/design/audit/learning]
**Outcome**: [worked/partial/failed]
**Root cause** (if failed): [qué salió mal]
**Extracted**: [new skill? update? nothing]
**Score**: auto-metrics [X/100]
**Would change**: [qué harías diferente]
```

Memorizalo como `type="learning"` con `topic_key="reflection/{date}"`.

### Periodic (~5 tools)
Self-check: consistent? repeating? underused? → auto-improve (delegate `skill-creator`) → verify (less errors, faster?)

## Skill Triggers
Same fix 2x→skill · gotcha→doc skill · user corrected 2x→protocol · complex workflow→skill · pattern 3+ files→extract

## Checkpoint
Quality? Efficiency? Learning? Reusability→skill? Different next time?

## Type Reflection
- Code: pattern? maintainable? tested?
- Troubleshoot: enough info? correct diagnosis?
- Design: reqs? tradeoffs? scalable?
- Skill: own skill? update existing?

## Frustration Signals
See `recovery-protocol` frustration signals table.

## Commands
`mem_save(type="learning", content="**What**:...\n**Learned**:...")` — if pattern: `skill-creator` or edit SKILL.md

## Connection to Post-Task Flow
AGENTS.md Post-Task section ejecuta steps 1-3 (git status, suggest, immune).
Hermes se ejecuta DESPUÉS como step 4 (reflection) si el task fue ≥3 tool calls.
