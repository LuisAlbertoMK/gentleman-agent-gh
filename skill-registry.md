# Skill Registry

## User Skills

| Trigger | Skill | Path |
|---------|-------|------|
| método Karpathy, menos tokens, LLM Wiki, context compilation | karpathy-prompt | ~/.config/opencode/skills/karpathy-prompt/SKILL.md |
| mejorar prompt, gaps, seguridad, escalabilidad, ReAct, multi-agent | prompt-engineering | ~/.config/opencode/skills/prompt-engineering/SKILL.md |
| continuá, donde quedamos, recordá código | code-memory | ~/.config/opencode/skills/code-memory/SKILL.md |
| reflexión, mejora continua, auto-corrección | self-reflection | ~/.config/opencode/skills/self-reflection/SKILL.md |
| karpathy loop, optimizar prompt, medir tokens | karpathy-loop | ~/.config/opencode/skills/karpathy-loop/SKILL.md |
| test skill, verificar skill, coverage | skill-testing | ~/.config/opencode/skills/skill-testing/SKILL.md |
| senior engineer, architect, trade-offs, system design, delegation | senior-engineer | ~/.config/opencode/skills/senior-engineer/SKILL.md |

## Compact Rules

### karpathy-prompt
- Prompts cortos: 20-50 tokens óptimo
- Estructura: "Eres [rol]. [tarea]."
- LLM Wiki: pre-compilar contexto (90% reducción)

### prompt-engineering
- SPEAR: Scope → Principles → Examples → Assertions → Refinements
- ReAct: Thought → Action → Observation → loop
- Security: sanitización, rate limits, HITL

### code-memory
- .agent-state.json para persistencia cross-session
- Auto-save en cambios significativos

### self-reflection
- Post-sesión: análisis de qué funcionó/falló
- Mejora de skills basada en gaps

### karpathy-loop
- Write → Measure → Cut → Repeat
- Tácticas de recorte en 3 niveles

### skill-testing
- Syntax, Coverage, Integration, Token tests
- Scoring: 9-10 ✅, 7-8 ⚠️, <7 ❌

### senior-engineer
- 15 competencias no-reemplazables: system design, trade-offs, security, mentoring, delegation
- Agent lanes: GREEN (free), YELLOW (propose), RED (approval)
- Decision framework: Build Now / Later / Don't Build
- RFC template
- Senior persona: ask clarifications antes, validate AI output, own decisions

## Proyecto Conventions

N/A — usuario local.