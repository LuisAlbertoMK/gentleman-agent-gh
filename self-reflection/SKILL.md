---
name: self-reflection
description: >
  Auto-mejora continua del agente mediante reflexión post-sesión.
  Trigger: Cuando sesión termina, cuando hay patrones repetitivos,
  cuando agent detecta propios errores.
license: Apache-2.0
metadata:
  author: mk
  version: "1.0"
---

## Cuando Usar

- Fin de sesión (auto-trigger)
- Patrones de errores detectados
- Frustración del usuario ("otra vez lo mismo")
- Necesidad de mejorar skills existente

## El Ciclo de Reflexión

```
Sesión → Reflexión → Mejora → Sesión siguiente
   ↑                                  |
   └──────────────────────────────────┘
```

## Fase 1: Captura Post-Sesión

###收集 Datos
```
## Reflexión Post-Sesión

### ¿Qué funcionó bien?
- [punto 1]
- [punto 2]

### ¿Qué podría mejorar?
- [punto 1]
- [punto 2]

### ¿Qué errores cometí?
- [error 1]
- [error 2]

### ¿Qué aprendí?
- [aprendizaje 1]
- [aprendizaje 2]

### ¿Qué skill debería actualizar?
- [skill] + [razón]
```

## Fase 2: Análisis de Patrones

```markdown
## Análisis de Patrones

### Errores Repetitivos
| Error | Frecuencia | Causa Raíz | Solución |
|-------|------------|-----------|----------|
| [error] | X veces | [causa] | [fix] |

### Skills Subutilizadas
- [skill] → no la cargué cuando debía

### Gaps Identificados
- [gap 1] → crear skill o mejorar existente
```

## Fase 3: Mejora de Skills

### Proceso
```
1. Identificar skill a mejorar
2. Analizar gap específico
3. Draft de mejora
4. Verificar con casos de prueba
5. Aplicar cambio
6. Documentar en CHANGELOG
```

### Template de Mejora
```markdown
## Skill: [nombre]

### Gap detectado
[descripción del problema]

### Cambio propuesto
[qué cambiar]

### Justificación
[por qué esto mejora]

### Implementación
```markdown
[nuevo contenido]
```

### Casos de prueba
- [ ] [caso 1]
- [ ] [caso 2]
```

## Fase 4: Auto-Correction

### Durante Sesión
```markdown
# Self-Check (ejecutar cada 10 mins)

## Check
- ¿Estoy siguiendo el método Karpathy? (respuesta corta)
- ¿Mi respuesta es necesaria o puedo ser más conciso?
- ¿Detecté alguna frustración del usuario?

## Si hay problema
- Ajustar inmediatamente
- Notificar al usuario: "Voy a ser más directo"
```

### Frustración Detection
```
Señales de frustración:
- "ya te dije que..."
- "no es eso"
- "otra vez lo mismo"
- Tono cortante

Acción:
1. Detener y reconocer: "Disculpame, no entendí bien"
2. Pedir clarificación explícita
3. Actualizar contexto con lo aprendido
```

## Reflexión por Tipo de Tarea

### Coding
```
## Reflexión: Coding

### ¿Usé el patrón correcto?
### ¿Mantuve estructura del proyecto?
### ¿Escribí tests?
### ¿El código es mantenible?
```

### Troubleshooting
```
## Reflexión: Troubleshooting

### ¿Pedí información suficiente antes de diagnosticar?
### ¿Mi diagnóstico fue correcto?
### ¿La solución funcionó?
### ¿Documenté la causa raíz?
```

### Design
```
## Reflexión: Design

### ¿Entendí los requisitos?
### ¿Consideré trade-offs?
### ¿Mi diseño es escalable?
### ¿Documenté decisiones?
```

## Auto-Update de Persona

```markdown
## Ajustes de Personality (dinámicos)

### Para este usuario específicamente:
- [preferencias descubiertas]
- [nivel técnico]
- [estilo de comunicación]

### Actualizar en:
~/.config/opencode/AGENTS.md
```

## Recursos

- Templates: [assets/reflection-template.md](assets/reflection-template.md)
- Patterns: [assets/error-patterns.md](assets/error-patterns.md)
- Changelog: [assets/skill-changelog.md](assets/skill-changelog.md)