# Multi-Agent Pattern — Orchestration

## Concepto

Dividir tareas complejas en agentes especializados que cooperan bajo un orquestador.

## Arquitectura

```
┌─────────────┐
│   Router    │ ← Evalúa input, distribuye
└──────┬──────┘
       ↓
┌─────────────┐
│  Planner    │ ← Crea plan stepwise
└──────┬──────┘
       ↓
┌─────────────┐
│  Executor   │ ← Ejecuta con herramientas
└──────┬──────┘
       ↓
┌─────────────┐
│   Critic    │ ← Valida, mejora, reporta
└─────────────┘
```

## Template: Definición de Agente

```markdown
## Agente: [Nombre]
- Rol: [especialización]
- Scope: [qué maneja]
- Tools: [herramientas disponibles]
- Límites: [constraints]
- Output: [formato de respuesta]
```

## Template: Sistema Completo

```markdown
# Sistema Multi-Agente

## Orchestrator
Rol: Coordina flujo entre agentes
Decision: [cómo rutear inputs]
Fallback: [si todos fallan]

## Agentes

### Router
- Input: [raw input]
- Logic: [ruting rules]
- Output: {agent, priority, context}

### Planner
- Input: {task, context}
- Logic: [planning strategy]
- Output: {steps: [{action, agent, tool}]}

### Executor
- Input: {steps}
- Logic: [ejecución secuencial/paralela]
- Output: {results}

### Critic
- Input: {results, task}
- Logic: [validación + mejora]
- Output: {answer, confidence, improvements}
```

## Ejemplo: Code Review System

```markdown
# Sistema: Automated Code Review

## Agente: SyntaxReviewer
- Rol: Analizar sintaxis y errores obvios
- Scope: Código fuente
- Tools: lint, parse, type-check
- Output: {errors: [], warnings: []}

## Agente: SecurityReviewer
- Rol: Detectar vulnerabilidades
- Scope: Credenciales, inputs, SQL, XSS
- Tools: scan, grep, sandbox
- Output: {vulns: [], severity: []}

## Agente: PerformanceReviewer
- Rol: Detectar bottlenecks
- Scope: Complexity, queries, loops
- Tools: profile, analyze
- Output: {issues: [], suggestions: []}

## Agente: DocReviewer
- Rol: Verificar documentación
- Scope: Comments, README, API docs
- Tools: read, parse
- Output: {missing: [], quality: []}

## Orchestrator
1. Input: código a revisar
2. Fork a Syntax + Security en paralelo
3. Si Security pasa → fork Performance + Doc
4. Collect todos los outputs
5. Synthesize en reporte final
```

## Communication Protocol

```markdown
## Mensaje entre Agentes
{
  "from": "[agente origen]",
  "to": "[agente destino]",
  "type": "request|response|error",
  "payload": {...},
  "context": {
    "task": "[id]",
    "priority": "[high|medium|low]"
  }
}
```

## Error Handling

| Situación | Acción |
|-----------|--------|
| Agente timeout | Retry 1x, luego skip + log |
| Agente error | Log + notify Critic |
| Todos fallan | Fallback: respuesta manual |
| Loop infinito | Max 10 iteraciones globales |
| Conflictos | Critic decide |

## Anti-Patrones

| NO | SÍ |
|----|-----|
| Agentes sin scope claro | Definir límites estrictos |
| Comunicación punto-a-punto compleja | Bus pattern |
| Sin timeout | Timeout por agente |
| Agentes monolíticos | Un rol por agente |
| Sin fallback | Siempre fallback |
