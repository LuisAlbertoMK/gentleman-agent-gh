---
name: prompt-engineering
description: >
  Ingeniería de prompts profesional siguiendo ciclo de vida de software.
  Trigger: Cuando usuario pide mejorar un prompt, crear prompt robusto,
  cubrir gaps, seguridad, escalabilidad. También: "ReAct", "Reflexion",
  "DSPy", "multi-agent", "agentic workflow".
license: Apache-2.0
metadata:
  author: mk
  version: "1.1"
---

## Cuando Usar

- Mejorar prompt existente
- Prompt para desarrollo de software complejo
- Necesita: seguridad, escalabilidad, edge cases, producción
- Tareas agentic con herramientas

## El Framework SPEAR

### S — Scope
```
Este prompt se usa para [contexto].
Input: [tipos]
Output: [formato]
```

### P — Principles
Máximo 4 reglas no negociables:
```
Principios:
1. [seguridad]
2. [calidad]
3. [rendimiento]
4. [mantenibilidad]
```

### E — Examples
1 válido + 1 edge case + 1 contraejemplo

### A — Assertions
```
ASSERT:
- [constraint verificable]
NUNCA:
- [prohibido]
```

### R — Refinements
Iteraciones post-implementación

## Advanced Patterns (v1.1)

### ReAct Pattern
Reasoning + Acting en loops:

```
# ReAct Template
Thought: [razonamiento sobre qué hacer]
Action: [herramienta a usar]
Observation: [resultado de la acción]
...repetir hasta resolver...
Final Answer: [conclusión]
```

### Reflexion Pattern
Auto-mejora con feedback:

```
# Reflexion Template
Task: [tarea]
Attempt: [respuesta]
Reflection: [evaluación crítica]
Revision: [mejorada]
...repetir si necesario...
```

### DSPy Integration
Para optimización automatizada:

```
# Con DSPy
- Declarar firma: dspy.Predict(Signature)
- Compilar: dspy.teleprompt.Compiled
- Optimizar: dspy.teleprompt.BootstrapFewShot
```

### Multi-Agent Orchestration (v1.1)

```
# Agentes especializados
Router → Planner → Executor → Critic

## Router
[Evalúa input y distribuye a especializado]

## Planner
[Crea plan de acción stepwise]

## Executor
[Ejecuta con herramientas]

## Critic
[Valida output, detecta errores]
```

#### Multi-Agent Template
```markdown
# Sistema Multi-Agente

## Agente: [Nombre]
Rol: [especialización]
Scope: [qué maneja]
Herramientas: [tools disponibles]
Límites: [constraints]

## Comunicación
- Request: [formato de mensaje]
- Response: [formato de respuesta]
- Errors: [cómo reportar]

## Orchestrator
- Routing rules: [cómo decidir]
- Fallback: [qué hacer si falla]
- Timeout: [límite por paso]
```

## Security Checklist v1.1

```
INPUT:
□ Tipos de datos especificados
□ Rangos válidos definidos
□ Longitudes máximas
□ Formatos validados
□ Sanitización para inyección

OUTPUT:
□ No ejecución automática
□ Sanitización de output
□ Rate limiting
□ Timeout en respuestas

DATA:
□ No hardcoded credentials
□ No PII en logs
□ Tokens no en output

AGENT:
□ Least privilege en herramientas
□ Tool schema validation
□ Human-in-the-loop para sensibles
□ Sandbox para código generado
□ Audit log sin secretos
```

## Tool Definition Template

```markdown
## [tool_name]
Descripción: [qué hace, cuándo usar]
Input: [schema tipo]
Output: [tipo de retorno]
Constraints:
- [límite 1]
- [límite 2]
Errors:
- [código]: [acción]
```

## Lifecycle Coverage

### Requirements
□ Input/output tipos claros
□ Constraints de entrada

### Design
□ Output format
□ Errores definidos
□ Logging specs

### Implementation
□ Edge cases explícitos
□ Error behavior
□ Logging necesario

### Testing
□ Casos de prueba
□ Validación output
□ Failure criteria

### Production
□ Rate limits
□ Timeouts
□ Retry policies
□ Metrics

## Template Profesional v1.1

```markdown
# ROL
Eres [rol] especializado en [dominio].

# CONTEXTO
- Sistema: [nombre]
- Stack: [tecnologías]
- Ubicación: [dónde opera]

# TIPO DE PATTERN
[ReAct / Reflexion / Standard / Multi-Agent]

# TAREA
[Descripción clara]

# INPUT
- Tipo: [datos]
- Constraints: [límites]

# OUTPUT
[Formato + ejemplo]

# PRINCIPIOS (max 4)
1. [seguridad]
2. [calidad]
3. [rendimiento]

# HERRAMIENTAS (si agentic)
[tool definitions]

# EDGE CASES
| Caso | Manejo |
|------|--------|

# ERRORS
| Error | Acción |
|-------|--------|

# ASSERT
- [constraint verificable]
NUNCA:
- [prohibido]
```

## Comandos

```bash
# Verificar cobertura
grep -E "□|✓|✗" prompt.md

# Test ReAct
# Usar: assets/react-template.md

# Test Multi-Agent
# Usar: assets/multi-agent-template.md
```

## Recursos

- Templates: [assets/software-lifecycle-template.md](assets/software-lifecycle-template.md)
- Security: [assets/security-checklist.md](assets/security-checklist.md)
- ReAct: [assets/react-template.md](assets/react-template.md)
- Multi-Agent: [assets/multi-agent-template.md](assets/multi-agent-template.md)