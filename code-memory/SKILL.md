---
name: code-memory
description: >
  Persistencia de estado de código entre sesiones.
  Trigger: Cuando usuario dice "continuá", "donde quedamos",
  "recordá lo que hicimos", o necesita que recuerde código exacto.
license: Apache-2.0
metadata:
  author: mk
  version: "1.0"
---

## Cuando Usar

- Usuario pide continuar trabajo anterior
- Necesidad de recuperar código exacto
- Proyecto multi-sesión con estado persistente
- "Dónde quedamos" o "qué hicimos"

## El Problema

LLMs no tienen memoria de código entre sesiones.
Solo guardan contexto corto de conversación actual.

## La Solución: Code State File

Crear archivo `.agent-state.json` en el proyecto:

```json
{
  "session_id": "uuid",
  "last_update": "ISO timestamp",
  "project": {
    "name": "nombre",
    "path": "/path/to/project",
    "language": "go|typescript|python",
    "framework": "nombre"
  },
  "files": [
    {
      "path": "src/main.go",
      "status": "in_progress|completed|blocked",
      "last_edit": "ISO",
      "content_hash": "sha256",
      "summary": "qué hace este archivo",
      "key_sections": {
        "function_x": "líneas 10-25, hace Y",
        "struct_z": "línea 30, definición"
      }
    }
  ],
  "todos": [
    {
      "id": 1,
      "description": "implementar auth",
      "status": "completed|pending|blocked",
      "file": "src/auth.go",
      "blocker": "necesito respuesta del usuario"
    }
  ],
  "context": {
    "current_task": "implementar login endpoint",
    "next_step": "agregar validación de password",
    "recent_changes": ["implementé handler", "agregué struct User"]
  },
  "artifacts": {
    "descriptions": ["snippet para X", "template para Y"],
    "content_hashes": ["hash1", "hash2"]
  }
}
```

## Estructura de Archivos

```
project/
├── .agent-state.json          # Estado principal
├── .agent-todos.md            # Lista de tareas en markdown
├── .agent-context/            # Contexto compilado
│   ├── index.md              # Mapa del proyecto
│   ├── pending-changes.md    # Cambios sin aplicar
│   └── questions.md          # Preguntas pendientes
└── .agent-artifacts/         # Snippets guardados
    ├── auth-template.go
    └── api-handler.ts
```

## Comandos

### Guardar estado
```bash
# Después de cada cambio significativo
agent-state save --file src/main.go --status in_progress

# Al terminar sesión
agent-state save --session-end
```

### Recuperar estado
```bash
# Al iniciar sesión nueva
agent-state load

# Solo recuperar un archivo
agent-state load --file src/main.go
```

### Ver todo
```bash
# Estado completo
agent-state status

# Solo pendientes
agent-state pending
```

## Workflow

### Al Iniciar Sesión
1. Buscar `.agent-state.json` en proyecto
2. Si existe: cargar y mostrar resumen
3. Si no existe: crear nuevo

### Durante la Sesión
1. Detectar cambios significativos en código
2. Actualizar estado en `.agent-state.json`
3. Detectar tareas completadas → actualizar todos

### Al Cerrar Sesión
1. Guardar estado completo
2. Listar preguntas pendientes
3. Resumir próximo paso

## Auto-Save Triggers

Guardar automáticamente cuando:
- Se crea/elimina archivo
- Se modifica >20 líneas
- Se completa una función/tarea
- Se descubre algo no obvio (bug, edge case)
- Usuario hace pregunta importante

## Template de Prompt para Cargar

```
## Estado del Proyecto

### Último trabajo
[resumen del estado actual]

### Archivos activos
- [archivo 1]: [estado] - [resumen]
- [archivo 2]: [estado] - [resumen]

### Pendientes
- [ ] [tarea 1]
- [ ] [tarea 2]

### Próximo paso
[qué hacer ahora]

### Preguntas pendientes
- [ ] [pregunta para usuario]
```

## Recursos

- Estados: [assets/state-examples.md](assets/state-examples.md)
- Templates: [assets/load-template.md](assets/load-template.md)