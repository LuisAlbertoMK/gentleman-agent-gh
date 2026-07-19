# Quick Start — Gentleman Agent

**5 pasos para empezar a usar el agente en 5 minutos.**

---

## ¿Qué es esto?

Gentleman Agent es un **equipo de desarrollo de software AI** con 22 agentes especializados. En lugar de un solo chatbot, tenés:

- 🏗️ **Arquitecto Principal** (`gentleman-vMK`) — tu mentor Senior Architect
- 🔒 **Especialistas** (seguridad, performance, frontend, etc.) — consultores FREE TIER
- 🧠 **Memoria persistente** (Engram) — el agente recuerda entre sesiones
- ✅ **Verificación automática** — triple check antes de cualquier cambio

**En resumen**: Pedís una tarea, el agente la resuelve con su equipo, verifica que funcione, y documenta lo que aprendió.

---

## Paso 1: Instalar

```bash
# Clonar
git clone https://github.com/LuisAlbertoMK/gentleman-agent-gh.git
cd gentleman-agent-gh

# Windows
.\scripts\setup-machine.ps1

# Linux/macOS
./scripts/setup-machine.sh
```

**Tiempo**: ~2 minutos

---

## Paso 2: Abrir OpenCode

```bash
# En la carpeta del proyecto
opencode
```

El agente `gentleman-vMK` se carga automáticamente como default.

**Tiempo**: ~10 segundos

---

## Paso 3: Pedir tu primera tarea

Escribí algo como:

```
Analizá mi proyecto y decime qué puedo mejorar
```

o

```
Revisá este archivo y sugerí optimizaciones
```

o

```
Creá un tests para esta función
```

**El agente automáticamente**:
1. Detecta tu stack技术
2. Carga las skills relevantes
3. Delega a especialistas si es necesario
4. Verifica los cambios
5. Documenta en bitácora

**Tiempo**: Variable según la tarea

---

## Paso 4: Usar shortcuts útiles

| Shortcut | Cuándo usarlo |
|----------|---------------|
| `!score` | Después de cambios para ver el score |
| `!health` | Si algo falla o querés diagnosticar |
| `!close` | Al terminar la sesión |
| `!analisis` | Para un análisis profundo multi-agente |

**Ejemplo**:
```
!score
```

---

## Paso 5: Cerrar sesión

```
!close
```

Esto ejecuta automáticamente:
- Guarda en bitácora
- Actualiza inter-track
- Sync con config global
- Muestra estado de git

---

## Próximos pasos

1. **Leé [AGENTS.md](AGENTS.md)** para entender el protocolo completo
2. **Explorá las skills** en `.agents/skills/` (69 disponibles)
3. **Probá `!analisis`** para un análisis multi-agente de tu proyecto
4. **Revisá [CYCLE.md](CYCLE.md)** para ver el ciclo de mejora actual

---

## Tips para usuarios nuevos

- **No necesitás acordarte de todo** — el agente sabe cuándo aplicar cada skill
- **Empezá simple** — pedí tareas pequeñas primero
- **Usá `!health`** si algo falla — te da un diagnóstico completo
- **El agente aprende** — usa Engram para recordar entre sesiones

---

## Troubleshooting

| Problema | Solución |
|----------|----------|
| Agente no responde | `!health` para diagnosticar |
| Skill no se carga | Verificá `.agents/skills/` existe |
| Score bajo | `!score` para recalcular |
| Git errors | `git status` para ver el estado |

---

*Última actualización: 2026-07-18*
