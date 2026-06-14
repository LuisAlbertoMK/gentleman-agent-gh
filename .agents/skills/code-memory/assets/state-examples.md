# State Examples — code-memory

## Example 1: Go Project

```json
{
  "session_id": "abc-123",
  "last_update": "2026-04-27T23:30:00Z",
  "project": {
    "name": "gentleman-api",
    "path": "/home/mk/projects/gentleman-api",
    "language": "go",
    "framework": "gin"
  },
  "files": [
    {
      "path": "cmd/server/main.go",
      "status": "completed",
      "summary": "Entry point, server setup",
      "key_sections": {
        "main": "line 1-50, initializes app",
        "router": "lines 20-35, routes config"
      }
    },
    {
      "path": "internal/handlers/auth.go",
      "status": "in_progress",
      "summary": "Login/logout handlers",
      "key_sections": {
        "Login": "lines 15-45, JWT generation",
        "Logout": "lines 50-60, token invalidation"
      }
    }
  ],
  "todos": [
    {
      "id": 1,
      "description": "Implementar refresh token",
      "status": "pending",
      "file": "internal/handlers/auth.go",
      "depends_on": 2
    },
    {
      "id": 2,
      "description": "Agregar logout endpoint",
      "status": "completed"
    }
  ],
  "context": {
    "current_task": "Implementar JWT refresh token flow",
    "next_step": "Crear endpoint /auth/refresh",
    "recent_changes": [
      "Login returns JWT + expires_at",
      "Logout invalidates token en memoria"
    ]
  },
  "questions": [
    {
      "id": 1,
      "question": "¿Usar Redis para blacklist de tokens o solo en memoria?",
      "status": "pending",
      "priority": "high"
    }
  ]
}
```

## Example 2: React Project

```json
{
  "session_id": "def-456",
  "last_update": "2026-04-27T22:15:00Z",
  "project": {
    "name": "dashboard-ui",
    "path": "/home/mk/projects/dashboard-ui",
    "language": "typescript",
    "framework": "react"
  },
  "files": [
    {
      "path": "src/components/Dashboard.tsx",
      "status": "in_progress",
      "summary": "Main dashboard component",
      "key_sections": {
        "state": "lines 10-25, useState hooks",
        "useEffect": "lines 30-50, data fetching"
      }
    }
  ],
  "todos": [
    {
      "id": 1,
      "description": "Agregar gráficos con recharts",
      "status": "pending"
    }
  ]
}
```

## Load Template

```markdown
# Proyecto Cargado

## Estado Anterior
- Sesión: [session_id]
- Última actualización: [timestamp]

## Archivos Activos
| Archivo | Estado | Resumen |
|---------|--------|---------|
| [path] | [status] | [summary] |

## Tareas Pendientes
- [ ] [tarea 1]
- [ ] [tarea 2]

## Próximo Paso
[qué hacer ahora]

## Preguntas para Usuario
- [ ] [pregunta 1]
- [ ] [pregunta 2]

## Resumen de Contexto
[compilación de recent_changes]
```