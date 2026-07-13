# ReAct Pattern — Reason + Act

## Concepto

ReAct = Reasoning + Acting en loops iterativos.
El agente razona sobre qué hacer, actúa, observa resultado, repite.

## Estructura

```
Thought → Action → Observation → Thought → ... → Final Answer
```

## Cuándo Usar

- Tareas multi-step complejas
- Búsqueda de información
- Coding con herramientas
- Debugging
- Investigación con múltiples fuentes

## Template Base

```markdown
# Tarea
[tarea clara]

## Pasos
[El agente ejecutará:]

---
Thought: [Razonamiento: qué sé, qué necesito, qué haré]
Action: [herramienta o acción]
Observation: [resultado]
---

[Repetir hasta resolver]

---
Final Answer: [Resultado final conciso]
```

## Ejemplo: Bug Fix

```markdown
# Tarea
Encontrar y arreglar el bug en la función validateEmail.

## Pasos
---
Thought: Debo primero ver el código actual de validateEmail.
Action: read_file("src/utils/validation.ts")
Observation: [código]
---

Thought: Ahora analizo el código. Veo que no handlea emails con tildes.
Action: grep("-", código) para ver patrón
Observation: [resultado]

Thought: El bug está en la regex. No permite Unicode. Fix: cambiar /[a-z]/i a /\p{L}/u
Action: edit_file con el fix
Observation: [confirmación]

Final Answer: Fixed. Cambié regex de /^[a-z]/i a /^\p{L}/u para Unicode.
```

## Ejemplo: Investigación

```markdown
# Tarea
Encontrar el mejor framework para TUI en Go.

## Pasos
---
Thought: Debo buscar opciones actuales de TUI en Go.
Action: web_search("Go TUI framework 2026")
Observation: [resultados: Bubbletea, fyne, lipgloss]
---

Thought: Bubbletea parece más activo. Busco benchmarks.
Action: web_search("Bubbletea Go TUI benchmark")
Observation: [datos]

Thought: Lipgloss es más ligero para casos simples. Bubbletea para complejos.
Final Answer: Bubbletea para TUI completas, Lipgloss para layouts simples.
```

## Thought Prompts

| Tipo | Prompt |
|------|--------|
| Exploración | `Thought: ¿Qué información necesito?` |
| Análisis | `Thought: ¿Qué indica este resultado?` |
| Planificación | `Thought: ¿Cuál es el siguiente paso?` |
| Verificación | `Thought: ¿Funcionó correctamente?` |
| Error | `Thought: ¿Por qué falló? ¿Alternativa?` |

## Límites

```
Max iterations: 10
Si no hay resolución en 10 pasos:
- Resumir progreso
- Pedir intervención humana
- Documentar qué se intentó
```

## Anti-Patrones

| NO | SÍ |
|----|-----|
| Saltar directamente a Action | Razonar primero |
| Ignorar Observation | Incorporar resultados |
| Infinite loops | Max iterations + fallback |
| Resumen sin Observation | Cada paso documentado |