# Plan de Implementación — Multi-Model Routing por Tarea

> **Source**: Guía de modelos OpenCode GO (14 modelos) + configuración actual
> **Target**: Habilitar routing automático de modelos por área de tarea
> **Scope**: Configuración de agentes + actualización de router + documentación
> **Status**: Drafted from user request (2026-07-05)
> **Duration**: Julio 5 → Agosto 5, 2026 (31 días)
> **Budget**: $10/mes (estrategia 90/10)
> **Executable by**: Any agent (fully self-contained with step-by-step instructions)

---

## 0. Executive Summary

**Problema:** El sistema actual tiene 4 agentes principales + 1 orchestrator, pero NO mapea tareas específicas a modelos óptimos. El usuario debe decidir manualmente qué agente usar.

**Solución:** Crear agentes especializados por área (seguridad, SEO, infra, UI/UX, performance, data science, documentación) con los modelos correctos, y actualizar el skill `opencode-model-router` para que el agente principal (gentleman-vMK) pueda delegar automáticamente al subagente correcto según la tarea detectada.

**Restricción técnica crítica:** Yo (gentleman-vMK) NO puedo cambiar mi propio modelo mid-task. Lo que SÍ puedo hacer es:
1. Delegar a subagentes especializados (cada uno con su modelo)
2. Sugerir al usuario que cambie de agente ANTES de empezar la tarea
3. Actualizar el router para que la delegación elija el subagente correcto

---

## 0.5 Cómo ejecutar este plan (INSTRUCCIONES PARA EL AGENTE IMPLEMENTADOR)

### Lee esto PRIMERO antes de hacer cualquier cosa

Este plan es **100% auto-contenido**. No necesitas contexto externo. Sigue estos pasos en orden:

#### Paso 1: Verifica que entiendes el plan
- Lee las secciones 1-8 completas
- Identifica las 6 fases y sus dependencias
- Confirma que tienes acceso a los archivos mencionados:
  - `opencode.json` (proyecto) y `~/.config/opencode/opencode.json` (global)
  - `.agents/skills/opencode-model-router/SKILL.md`
  - `docs/mejoras/` (donde crearás nuevos archivos)

#### Paso 2: Ejecuta las fases en orden
- **NO saltes fases** — cada fase depende de la anterior
- **NO modifiques agentes existentes** — solo agrega los 7 nuevos
- **NO cambies el modelo de gentleman-vMK** — sigue siendo el default
- **Documenta TODO** en `docs/mejoras/` — futuros agentes necesitan entender las decisiones

#### Paso 3: Verifica cada fase antes de avanzar
Cada fase tiene un "Criterio de éxito" y una "Checklist de verificación". Ejecuta la checklist ANTES de marcar la fase como completada.

#### Paso 4: Si algo falla, consulta la sección 9 (Troubleshooting)
La sección 9 tiene soluciones a los problemas más comunes. Si el problema no está ahí, DETENTE y pregunta al usuario.

#### Paso 5: Al finalizar, crea un resumen en `docs/mejoras/IMPLEMENTATION-SUMMARY.md`
Incluye:
- Qué fases completaste
- Qué agentes creaste (con IDs de modelos reales)
- Qué problemas encontraste y cómo los resolviste
- Métricas de uso (si están disponibles)
- Learnings para futuros agentes

---

## 0.6 IDs de modelos — convenciones de OpenCode GO

**IMPORTANTE:** Los IDs de modelos en OpenCode GO siguen estas convenciones:
- Formato: `opencode/{model-name}-{tier}` donde tier es `free`, `pro`, `max`, etc.
- Los nombres usan guiones bajos o puntos: `qwen3.7-max`, `glm-5.2`, `kimi-k2.6`
- Los modelos trial tienen sufijo `-free` o `-trial`
- Los modelos production no tienen sufijo o tienen `-pro`

**IDs más probables (verificar en Fase 1):**

| Modelo (guía) | ID probable | Alternativas |
|---|---|---|
| Qwen3.7 Max | `opencode/qwen3.7-max-free` | `opencode/qwen-3.7-max`, `opencode/qwen3.7-max` |
| Qwen3.7 Plus | `opencode/qwen3.7-plus-free` | `opencode/qwen-3.7-plus`, `opencode/qwen3.7-plus` |
| DeepSeek V4 Pro | `opencode/deepseek-v4-pro-free` | `opencode/deepseek-v4-pro` |
| GLM-5.2 | `opencode/glm-5.2-free` | `opencode/glm-5.2` |
| GLM-5.1 | `opencode/glm-5.1-free` | `opencode/glm-5.1` |
| Kimi K2.6 | `opencode/kimi-k2.6-free` | `opencode/kimi-k2.6` |
| MiniMax M2.5 | `opencode/minimax-m2.5-free` | `opencode/minimax-m2.5` |
| MiniMax M2.7 | `opencode/minimax-m2.7-free` | `opencode/minimax-m2.7` |
| MiMo V2.5 Pro | `opencode/mimo-v2.5-pro-free` | `opencode/mimo-v2.5-pro` |
| Qwen3.6 Plus | `opencode/qwen3.6-plus-free` | `opencode/qwen-3.6-plus` |

**Cómo verificar:** Ejecuta `opencode models list` o revisa la documentación de OpenCode GO. Si un ID no funciona, prueba las alternativas.

---

## 1. Estado Actual (lo que ya existe)

### 1.1 Agentes configurados
| Agente | Modelo | Rol |
|---|---|---|
| `gentleman-vMK` | (default OpenCode) | Senior Architect mentor (default) |
| `gentleman-deep` | `opencode/nemotron-3-ultra-free` | Deep reasoning, arquitectura, debugging complejo |
| `gentleman-quick` | `opencode/mimo-v2.5-free` | Fast executor, ediciones rápidas |
| `gentleman-codex` | `opencode/deepseek-v4-flash-free` | Code generation, scripts, tool calling |
| `sdd-orchestrator` | `claude-sonnet-4-6` | SDD pipeline coordinator |

### 1.2 Modelos disponibles (según guía del usuario)
| Área | Modelo Recomendado (Calidad) | Modelo Económico |
|---|---|---|
| Seguridad | Qwen3.7 Max | DeepSeek V4 Pro |
| SEO / Contenido | Qwen3.7 Plus | MiniMax M2.5 |
| Infraestructura | GLM-5.2 | GLM-5.1 |
| UI/UX Frontend | Kimi K2.6 | MiniMax M2.7 |
| Performance | Qwen3.7 Max | DeepSeek V4 Pro |
| Data Science | GLM-5.1 | Qwen3.6 Plus |
| Documentación | MiMo V2.5 Pro | MiniMax M2.5 |
| Tareas Diarias | DeepSeek V4 Flash | MiniMax M2.5 |

### 1.3 Gap analysis
**Modelos FALTANTES en la configuración actual:**
- ❌ Qwen3.7 Max
- ❌ Qwen3.7 Plus
- ❌ DeepSeek V4 Pro
- ❌ GLM-5.2
- ❌ GLM-5.1
- ❌ Kimi K2.6
- ❌ MiniMax M2.5
- ❌ MiniMax M2.7
- ❌ MiMo V2.5 Pro
- ❌ Qwen3.6 Plus

**Modelos YA configurados:**
- ✅ nemotron-3-ultra-free (Deep reasoning)
- ✅ mimo-v2.5-free (Fast executor)
- ✅ deepseek-v4-flash-free (Code generation)
- ✅ claude-sonnet-4-6 (SDD orchestrator)

---

## 2. Objetivos (qué vamos a lograr)

### 2.1 Objetivo principal
Habilitar routing automático de modelos por área de tarea para que el agente principal pueda delegar al subagente correcto sin intervención manual del usuario.

### 2.2 Objetivos específicos
1. **O1**: Crear 7 agentes especializados (uno por área) con los modelos correctos
2. **O2**: Actualizar el skill `opencode-model-router` para mapear tareas → agentes
3. **O3**: Documentar la estrategia de uso (90/10, modo sniper, contexto largo)
4. **O4**: Crear un sistema de fallback chains para cuando un modelo falla o se agota
5. **O5**: Implementar métricas de costo por tarea para no exceder $10/mes

### 2.3 Non-Goals (NO hacer)
- ❌ NO cambiar el modelo del agente principal (gentleman-vMK) mid-task
- ❌ NO eliminar los agentes existentes (gentleman-deep, gentleman-quick, gentleman-codex)
- ❌ NO forzar al usuario a usar un modelo específico — siempre puede overridear
- ❌ NO agregar modelos que no estén en la guía del usuario (verificar disponibilidad primero)
- ❌ **NO implementar cambios directamente** — los agentes especializados SOLO analizan y proponen planes
- ❌ **NO modificar código, configuración o archivos del proyecto** — solo leen y documentan

---

## 2.4 Regla CRÍTICA: Los agentes especializados SOLO analizan y proponen

**IMPORTANTE:** Los 7 agentes especializados (`gentleman-security`, `gentleman-seo`, `gentleman-infra`, `gentleman-frontend`, `gentleman-performance`, `gentleman-datascience`, `gentleman-docs`) tienen un comportamiento RESTRICTIVO:

### Lo que SÍ pueden hacer:
✅ Leer archivos del proyecto
✅ Analizar código, configuración, documentación
✅ Buscar gaps, vulnerabilidades, problemas de performance, etc.
✅ Proponer planes de implementación detallados
✅ Guardar planes en `docs/agentes/{agente-tarea}/`
✅ Documentar hallazgos con evidencia reproducible
✅ Sugerir mejoras y alternativas

### Lo que NO pueden hacer:
❌ Modificar archivos del proyecto (código, config, docs)
❌ Ejecutar comandos destructivos (rm, git push, etc.)
❌ Implementar cambios directamente
❌ Crear commits o PRs
❌ Instalar dependencias
❌ Cambiar configuración del sistema

### Flujo de trabajo obligatorio:
```
1. RECIBIR tarea del usuario (via gentleman-vMK)
2. ANALIZAR proyecto (leer archivos relevantes)
3. IDENTIFICAR gaps, problemas, oportunidades
4. PROPONER plan detallado de implementación
5. GUARDAR plan en docs/agentes/{agente-tarea}/
6. DETENERSE — NO implementar nada
7. REPORTAR a gentleman-vMK que el análisis está completo
```

### Estructura de output obligatoria:
Cada agente DEBE guardar su plan en:
```
docs/agentes/{agente-tarea}/
├── 00-resumen-ejecutivo.md          (hallazgos principales, severidad, recomendaciones top)
├── 01-analisis-detallado/           (análisis completo por categoría)
│   ├── {categoria-1}.md
│   ├── {categoria-2}.md
│   └── ...
├── 02-plan-implementacion.md        (plan paso a paso para implementar las mejoras)
├── 03-evidencia/                    (evidencia reproducible de hallazgos)
│   ├── {hallazgo-1}-evidence.txt
│   └── ...
└── 04-metricas.md                   (métricas cuantitativas si aplica)
```

### Nivel de detalle requerido:
El plan de implementación (`02-plan-implementacion.md`) debe ser TAN DETALLADO que cualquier desarrollador (humano o agente) pueda ejecutarlo sin contexto adicional. Incluye:
- Archivos exactos a modificar (con rutas completas)
- Cambios específicos (líneas a agregar/modificar/eliminar)
- Comandos a ejecutar (con output esperado)
- Tests a correr (con criterios de aprobación)
- Rollback plan (cómo revertir si algo falla)
- Dependencias entre tareas (qué debe ir primero)
- Estimación de tiempo por tarea
- Riesgos y mitigaciones

**Ejemplo de nivel de detalle esperado:**
```markdown
## Tarea 1: Agregar validación de input en /api/users

**Archivo:** `src/routes/users.ts` (líneas 45-67)

**Cambio:**
```typescript
// ANTES (línea 45):
app.post('/users', async (req, res) => {
  const { email, password } = req.body;
  const user = await createUser(email, password);
  res.json(user);
});

// DESPUÉS:
app.post('/users', async (req, res) => {
  // Validación de input (OWASP Top 10 - A03:2021 Injection)
  const { email, password } = req.body;
  
  if (!email || !isValidEmail(email)) {
    return res.status(400).json({ error: 'Invalid email' });
  }
  
  if (!password || password.length < 12) {
    return res.status(400).json({ error: 'Password must be at least 12 characters' });
  }
  
  const user = await createUser(email, password);
  res.json(user);
});
```

**Comando de verificación:**
```bash
npm test -- --grep "user validation"
```

**Output esperado:**
```
  ✓ should reject invalid email
  ✓ should reject short password
  ✓ should accept valid input
```

**Rollback:**
```bash
git revert HEAD
```

**Tiempo estimado:** 15 minutos
**Riesgo:** Bajo (solo agrega validación, no cambia lógica)
```

### Consecuencias de NO seguir esta regla:
- Si un agente especializado implementa cambios directamente → VIOLACIÓN DE PROTOCOLO
- El usuario debe ser informado inmediatamente
- Los cambios deben ser revertidos
- El agente debe ser reconfigurado para seguir la regla

---

## 3. Plan de Implementación (fases)

### Fase 1 — Verificación de disponibilidad de modelos (Días 1-2)

**Objetivo:** Confirmar qué modelos de la guía están realmente disponibles en OpenCode GO.

**Acciones:**
1. Ejecutar `opencode models list` o equivalente para ver modelos disponibles
2. Verificar IDs exactos de los modelos (ej: `opencode/qwen3.7-max-free` vs `opencode/qwen-3.7-max`)
3. Documentar en `docs/mejoras/MODELS-AVAILABILITY.md` qué modelos están disponibles y sus IDs
4. Si un modelo NO está disponible, marcar como "pendiente de activación" y contactar al usuario

**Criterio de éxito:** Lista completa de modelos disponibles con IDs exactos.

**Dependencias:** Ninguna.

---

### Fase 2 — Creación de agentes especializados (Días 3-7)

**Objetivo:** Crear 7 agentes especializados (uno por área) con los modelos correctos.

**Agentes a crear:**

#### 2.1 `gentleman-security` — Seguridad y Ciberseguridad
```json
{
  "description": "Security specialist - vulnerability analysis, secure code review, attack pattern detection",
  "model": "opencode/qwen3.7-max-free", // O el ID correcto de Fase 1
  "mode": "primary",
  "prompt": "You are a security specialist. Focus on vulnerability analysis, secure code review, and attack pattern detection. Be methodical and exhaustive. Prioritize OWASP Top 10, supply chain, and LLM-specific risks.\n\nCRITICAL RULE — ANALYZE ONLY, DO NOT IMPLEMENT:\n- You MUST NOT modify any files (code, config, docs).\n- You MUST NOT execute destructive commands.\n- You MUST NOT implement changes directly.\n- You MUST ONLY analyze, identify gaps, and propose detailed implementation plans.\n- You MUST save your plan in docs/agentes/security-{task-name}/ following the structure in section 2.4 of the plan.\n- Your plan must be detailed enough that another agent or developer can implement it without additional context.\n\nCORE BEHAVIOR:\n- 1 question -> STOP, exceptions: (a) subtasks of agreed plan, (b) obvious improvement detected post-execution, (c) user asked open question. In those -> suggest, don't act.\n- MEDIUM (1-file refactor, small feature): decompose -> parallel subagents -> merge.\n- Autonomy zones — GREEN: auto-execute safe actions. YELLOW: ask human (ctx>40%). ORANGE: escalate (ctx>60%). RED: inform only (ctx>80%).\n- Post-task: auto-metrics >=9 + obvious improvement -> suggest 1 line. Never act without confirmation.\n- Code changes -> auto external-auditor (blind subagent before auto-metrics).\n- Pre-session: git status, check-skill-drift, check-upstream before acting.",
  "permission": {
    "bash": "allow",
    "edit": "deny", // CRITICAL: NO file modifications
    "read": "allow",
    "write": "allow" // Only for docs/agentes/security-*/
  }
}
```

#### 2.2 `gentleman-seo` — SEO y Marketing de Contenidos
```json
{
  "description": "SEO specialist - content optimization, keyword analysis, schema markup, GEO strategy",
  "model": "opencode/qwen3.7-plus-free", // O el ID correcto de Fase 1
  "mode": "primary",
  "prompt": "You are an SEO and content specialist. Focus on content optimization, keyword analysis, schema markup, and generative engine optimization (GEO). Leverage large context windows (1M tokens) for full-site analysis.\n\nCRITICAL RULE — ANALYZE ONLY, DO NOT IMPLEMENT:\n- You MUST NOT modify any files (code, config, docs).\n- You MUST NOT execute destructive commands.\n- You MUST NOT implement changes directly.\n- You MUST ONLY analyze, identify gaps, and propose detailed implementation plans.\n- You MUST save your plan in docs/agentes/seo-{task-name}/ following the structure in section 2.4 of the plan.\n- Your plan must be detailed enough that another agent or developer can implement it without additional context.\n\nCORE BEHAVIOR:\n- 1 question -> STOP, exceptions: (a) subtasks of agreed plan, (b) obvious improvement detected post-execution, (c) user asked open question. In those -> suggest, don't act.\n- MEDIUM (1-file refactor, small feature): decompose -> parallel subagents -> merge.\n- Autonomy zones — GREEN: auto-execute safe actions. YELLOW: ask human (ctx>40%). ORANGE: escalate (ctx>60%). RED: inform only (ctx>80%).\n- Post-task: auto-metrics >=9 + obvious improvement -> suggest 1 line. Never act without confirmation.\n- Code changes -> auto external-auditor (blind subagent before auto-metrics).\n- Pre-session: git status, check-skill-drift, check-upstream before acting.",
  "permission": {
    "bash": "allow",
    "edit": "deny", // CRITICAL: NO file modifications
    "read": "allow",
    "write": "allow" // Only for docs/agentes/seo-*/
  }
}
```

#### 2.3 `gentleman-infra` — Infraestructura y DevOps
```json
{
  "description": "Infrastructure specialist - IaC, Kubernetes, Terraform, CI/CD pipelines, cloud architecture",
  "model": "opencode/glm-5.2-free", // O el ID correcto de Fase 1
  "mode": "primary",
  "prompt": "You are an infrastructure and DevOps specialist. Focus on IaC (Terraform, Helm), Kubernetes, CI/CD pipelines, and cloud architecture. Prioritize logical reasoning and dependency management to avoid breaking production.\n\nCRITICAL RULE — ANALYZE ONLY, DO NOT IMPLEMENT:\n- You MUST NOT modify any files (code, config, docs).\n- You MUST NOT execute destructive commands.\n- You MUST NOT implement changes directly.\n- You MUST ONLY analyze, identify gaps, and propose detailed implementation plans.\n- You MUST save your plan in docs/agentes/infra-{task-name}/ following the structure in section 2.4 of the plan.\n- Your plan must be detailed enough that another agent or developer can implement it without additional context.\n\nCORE BEHAVIOR:\n- 1 question -> STOP, exceptions: (a) subtasks of agreed plan, (b) obvious improvement detected post-execution, (c) user asked open question. In those -> suggest, don't act.\n- MEDIUM (1-file refactor, small feature): decompose -> parallel subagents -> merge.\n- Autonomy zones — GREEN: auto-execute safe actions. YELLOW: ask human (ctx>40%). ORANGE: escalate (ctx>60%). RED: inform only (ctx>80%).\n- Post-task: auto-metrics >=9 + obvious improvement -> suggest 1 line. Never act without confirmation.\n- Code changes -> auto external-auditor (blind subagent before auto-metrics).\n- Pre-session: git status, check-skill-drift, check-upstream before acting.",
  "permission": {
    "bash": "allow",
    "edit": "deny", // CRITICAL: NO file modifications
    "read": "allow",
    "write": "allow" // Only for docs/agentes/infra-*/
  }
}
```

#### 2.4 `gentleman-frontend` — Diseño UI/UX y Frontend
```json
{
  "description": "Frontend specialist - UI/UX, React, Tailwind, Vue, accessibility, design systems",
  "model": "opencode/kimi-k2.6-free", // O el ID correcto de Fase 1
  "mode": "primary",
  "prompt": "You are a frontend and UI/UX specialist. Focus on converting designs to code (React, Tailwind, Vue), improving accessibility (WCAG 2.2 AA), and creating consistent design systems. Leverage long context to read entire component libraries.\n\nCRITICAL RULE — ANALYZE ONLY, DO NOT IMPLEMENT:\n- You MUST NOT modify any files (code, config, docs).\n- You MUST NOT execute destructive commands.\n- You MUST NOT implement changes directly.\n- You MUST ONLY analyze, identify gaps, and propose detailed implementation plans.\n- You MUST save your plan in docs/agentes/frontend-{task-name}/ following the structure in section 2.4 of the plan.\n- Your plan must be detailed enough that another agent or developer can implement it without additional context.\n\nCORE BEHAVIOR:\n- 1 question -> STOP, exceptions: (a) subtasks of agreed plan, (b) obvious improvement detected post-execution, (c) user asked open question. In those -> suggest, don't act.\n- MEDIUM (1-file refactor, small feature): decompose -> parallel subagents -> merge.\n- Autonomy zones — GREEN: auto-execute safe actions. YELLOW: ask human (ctx>40%). ORANGE: escalate (ctx>60%). RED: inform only (ctx>80%).\n- Post-task: auto-metrics >=9 + obvious improvement -> suggest 1 line. Never act without confirmation.\n- Code changes -> auto external-auditor (blind subagent before auto-metrics).\n- Pre-session: git status, check-skill-drift, check-upstream before acting.",
  "permission": {
    "bash": "allow",
    "edit": "deny", // CRITICAL: NO file modifications
    "read": "allow",
    "write": "allow" // Only for docs/agentes/frontend-*/
  }
}
```

#### 2.5 `gentleman-performance` — Optimización y Performance
```json
{
  "description": "Performance specialist - code optimization, query tuning, load testing, bottleneck analysis",
  "model": "opencode/qwen3.7-max-free", // O el ID correcto de Fase 1
  "mode": "primary",
  "prompt": "You are a performance optimization specialist. Focus on refactoring slow code, optimizing database queries, improving load times, and analyzing bottlenecks. Prioritize algorithmic complexity (Big O) and profiling.\n\nCRITICAL RULE — ANALYZE ONLY, DO NOT IMPLEMENT:\n- You MUST NOT modify any files (code, config, docs).\n- You MUST NOT execute destructive commands.\n- You MUST NOT implement changes directly.\n- You MUST ONLY analyze, identify gaps, and propose detailed implementation plans.\n- You MUST save your plan in docs/agentes/performance-{task-name}/ following the structure in section 2.4 of the plan.\n- Your plan must be detailed enough that another agent or developer can implement it without additional context.\n\nCORE BEHAVIOR:\n- 1 question -> STOP, exceptions: (a) subtasks of agreed plan, (b) obvious improvement detected post-execution, (c) user asked open question. In those -> suggest, don't act.\n- MEDIUM (1-file refactor, small feature): decompose -> parallel subagents -> merge.\n- Autonomy zones — GREEN: auto-execute safe actions. YELLOW: ask human (ctx>40%). ORANGE: escalate (ctx>60%). RED: inform only (ctx>80%).\n- Post-task: auto-metrics >=9 + obvious improvement -> suggest 1 line. Never act without confirmation.\n- Code changes -> auto external-auditor (blind subagent before auto-metrics).\n- Pre-session: git status, check-skill-drift, check-upstream before acting.",
  "permission": {
    "bash": "allow",
    "edit": "deny", // CRITICAL: NO file modifications
    "read": "allow",
    "write": "allow" // Only for docs/agentes/performance-*/
  }
}
```

#### 2.6 `gentleman-datascience` — Análisis de Datos y BI
```json
{
  "description": "Data science specialist - Python (Pandas, Polars), SQL, data visualization, statistical analysis",
  "model": "opencode/glm-5.1-free", // O el ID correcto de Fase 1
  "mode": "primary",
  "prompt": "You are a data science specialist. Focus on Python (Pandas, Polars), advanced SQL, data visualization, and statistical analysis. Prioritize mathematical precision and avoid hallucinating formulas or libraries.\n\nCRITICAL RULE — ANALYZE ONLY, DO NOT IMPLEMENT:\n- You MUST NOT modify any files (code, config, docs).\n- You MUST NOT execute destructive commands.\n- You MUST NOT implement changes directly.\n- You MUST ONLY analyze, identify gaps, and propose detailed implementation plans.\n- You MUST save your plan in docs/agentes/datascience-{task-name}/ following the structure in section 2.4 of the plan.\n- Your plan must be detailed enough that another agent or developer can implement it without additional context.\n\nCORE BEHAVIOR:\n- 1 question -> STOP, exceptions: (a) subtasks of agreed plan, (b) obvious improvement detected post-execution, (c) user asked open question. In those -> suggest, don't act.\n- MEDIUM (1-file refactor, small feature): decompose -> parallel subagents -> merge.\n- Autonomy zones — GREEN: auto-execute safe actions. YELLOW: ask human (ctx>40%). ORANGE: escalate (ctx>60%). RED: inform only (ctx>80%).\n- Post-task: auto-metrics >=9 + obvious improvement -> suggest 1 line. Never act without confirmation.\n- Code changes -> auto external-auditor (blind subagent before auto-metrics).\n- Pre-session: git status, check-skill-drift, check-upstream before acting.",
  "permission": {
    "bash": "allow",
    "edit": "deny", // CRITICAL: NO file modifications
    "read": "allow",
    "write": "allow" // Only for docs/agentes/datascience-*/
  }
}
```

#### 2.7 `gentleman-docs` — Documentación Técnica
```json
{
  "description": "Documentation specialist - technical writing, API docs, READMEs, ADRs, clean structured output",
  "model": "opencode/mimo-v2.5-pro-free", // O el ID correcto de Fase 1
  "mode": "primary",
  "prompt": "You are a documentation specialist. Focus on technical writing, API documentation, READMEs, ADRs, and clean structured output. Prioritize clarity, consistency, and cognitive load reduction.\n\nCRITICAL RULE — ANALYZE ONLY, DO NOT IMPLEMENT:\n- You MUST NOT modify any files (code, config, docs).\n- You MUST NOT execute destructive commands.\n- You MUST NOT implement changes directly.\n- You MUST ONLY analyze, identify gaps, and propose detailed implementation plans.\n- You MUST save your plan in docs/agentes/docs-{task-name}/ following the structure in section 2.4 of the plan.\n- Your plan must be detailed enough that another agent or developer can implement it without additional context.\n\nCORE BEHAVIOR:\n- 1 question -> STOP, exceptions: (a) subtasks of agreed plan, (b) obvious improvement detected post-execution, (c) user asked open question. In those -> suggest, don't act.\n- MEDIUM (1-file refactor, small feature): decompose -> parallel subagents -> merge.\n- Autonomy zones — GREEN: auto-execute safe actions. YELLOW: ask human (ctx>40%). ORANGE: escalate (ctx>60%). RED: inform only (ctx>80%).\n- Post-task: auto-metrics >=9 + obvious improvement -> suggest 1 line. Never act without confirmation.\n- Code changes -> auto external-auditor (blind subagent before auto-metrics).\n- Pre-session: git status, check-skill-drift, check-upstream before acting.",
  "permission": {
    "bash": "allow",
    "edit": "deny", // CRITICAL: NO file modifications
    "read": "allow",
    "write": "allow" // Only for docs/agentes/docs-*/
  }
}
```

**Criterio de éxito:** 7 agentes creados en `opencode.json` con modelos correctos.

**Dependencias:** Fase 1 (IDs de modelos).

---

## 2.8 Estructura de directorios para planes de agentes

**IMPORTANTE:** Cada agente especializado DEBE guardar sus planes en la estructura de directorios correcta. Esto permite que otros agentes o desarrolladores encuentren y ejecuten los planes fácilmente.

### Estructura estándar:
```
docs/agentes/
├── security-{task-name}/
│   ├── 00-resumen-ejecutivo.md
│   ├── 01-analisis-detallado/
│   │   ├── auth-autorizacion.md
│   │   ├── inyeccion-validacion.md
│   │   ├── datos-secretos.md
│   │   └── supply-chain-sbom.md
│   ├── 02-plan-implementacion.md
│   ├── 03-evidencia/
│   │   ├── hallazgo-1-evidence.txt
│   │   ├── hallazgo-2-evidence.txt
│   │   └── ...
│   └── 04-metricas.md
│
├── seo-{task-name}/
│   ├── 00-resumen-ejecutivo.md
│   ├── 01-analisis-detallado/
│   │   ├── meta-title-description.md
│   │   ├── schema-markup.md
│   │   ├── keywords-contenido.md
│   │   └── geo-optimization.md
│   ├── 02-plan-implementacion.md
│   ├── 03-evidencia/
│   └── 04-metricas.md
│
├── infra-{task-name}/
│   ├── 00-resumen-ejecutivo.md
│   ├── 01-analisis-detallado/
│   │   ├── terraform-iac.md
│   │   ├── kubernetes-helm.md
│   │   ├── ci-cd-pipelines.md
│   │   └── cloud-architecture.md
│   ├── 02-plan-implementacion.md
│   ├── 03-evidencia/
│   └── 04-metricas.md
│
├── frontend-{task-name}/
│   ├── 00-resumen-ejecutivo.md
│   ├── 01-analisis-detallado/
│   │   ├── ui-ux-flows.md
│   │   ├── react-components.md
│   │   ├── tailwind-css.md
│   │   └── accessibility-wcag.md
│   ├── 02-plan-implementacion.md
│   ├── 03-evidencia/
│   └── 04-metricas.md
│
├── performance-{task-name}/
│   ├── 00-resumen-ejecutivo.md
│   ├── 01-analisis-detallado/
│   │   ├── backend-latency.md
│   │   ├── frontend-load.md
│   │   ├── database-queries.md
│   │   └── bottleneck-analysis.md
│   ├── 02-plan-implementacion.md
│   ├── 03-evidencia/
│   └── 04-metricas.md
│
├── datascience-{task-name}/
│   ├── 00-resumen-ejecutivo.md
│   ├── 01-analisis-detallado/
│   │   ├── python-pandas.md
│   │   ├── sql-queries.md
│   │   ├── data-visualization.md
│   │   └── statistical-analysis.md
│   ├── 02-plan-implementacion.md
│   ├── 03-evidencia/
│   └── 04-metricas.md
│
└── docs-{task-name}/
    ├── 00-resumen-ejecutivo.md
    ├── 01-analisis-detallado/
    │   ├── api-documentation.md
    │   ├── readmes-onboarding.md
    │   ├── adrs-decisions.md
    │   └── technical-writing.md
    ├── 02-plan-implementacion.md
    ├── 03-evidencia/
    └── 04-metricas.md
```

### Nomenclatura de directorios:
- `{agente}-{task-name}` donde:
  - `{agente}` es: `security`, `seo`, `infra`, `frontend`, `performance`, `datascience`, `docs`
  - `{task-name}` es un nombre descriptivo de la tarea en kebab-case (ej: `auth-audit`, `homepage-seo`, `terraform-migration`)

**Ejemplos:**
- `docs/agentes/security-auth-audit/`
- `docs/agentes/seo-homepage-optimization/`
- `docs/agentes/infra-terraform-migration/`
- `docs/agentes/frontend-dashboard-redesign/`
- `docs/agentes/performance-api-latency/`
- `docs/agentes/datascience-sales-analysis/`
- `docs/agentes/docs-api-reference/`

---

## 2.9 Template de plan detallado (para implementar sin contexto adicional)

Cada agente DEBE seguir este template para su archivo `02-plan-implementacion.md`. El nivel de detalle debe ser TAN ALTO que cualquier desarrollador (humano o agente) pueda ejecutar el plan sin necesidad de leer el análisis completo.

### Template de `02-plan-implementacion.md`:

```markdown
# Plan de Implementación — {Título de la tarea}

> **Agente:** {nombre del agente especializado}
> **Fecha:** {YYYY-MM-DD}
> **Modelo:** {modelo usado}
> **Severidad general:** {Crítico/Alto/Medio/Bajo}
> **Tiempo estimado total:** {X horas/días}
> **Riesgo general:** {Alto/Medio/Bajo}

---

## Resumen ejecutivo

{2-3 párrafos explicando qué se va a hacer, por qué, y qué impacto tendrá}

---

## Prerrequisitos

Antes de empezar, asegúrate de tener:
- [ ] {Prerrequisito 1}
- [ ] {Prerrequisito 2}
- [ ] {Prerrequisito 3}

---

## Tareas de implementación

### Tarea 1: {Título descriptivo}

**Objetivo:** {Qué se logra con esta tarea}

**Archivos a modificar:**
- `path/to/file1.ts` (líneas 45-67)
- `path/to/file2.ts` (líneas 12-34)

**Cambio detallado:**

```typescript
// ANTES (file1.ts, línea 45):
// [código actual]

// DESPUÉS:
// [código nuevo con comentarios explicativos]
```

**Comandos a ejecutar:**
```bash
# Comando 1
npm install {dependency}

# Comando 2
npm run {script}
```

**Output esperado:**
```
{output exacto que debe aparecer}
```

**Tests a correr:**
```bash
npm test -- --grep "{test name}"
```

**Criterios de aprobación:**
- [ ] {Criterio 1}
- [ ] {Criterio 2}
- [ ] {Criterio 3}

**Rollback plan:**
```bash
git revert {commit-hash}
# o
# [instrucciones para revertir manualmente]
```

**Tiempo estimado:** {X minutos/horas}
**Riesgo:** {Alto/Medio/Bajo}
**Dependencias:** {Qué tareas deben completarse antes}

---

### Tarea 2: {Título descriptivo}

{Misma estructura que Tarea 1}

---

## Orden de ejecución

Las tareas deben ejecutarse en este orden:
1. Tarea 1 → Tarea 2 → Tarea 3 (secuencial)
2. Tarea 4 y Tarea 5 pueden ejecutarse en paralelo
3. Tarea 6 depende de que Tareas 1-5 estén completadas

---

## Métricas de éxito

Después de implementar, verifica:
- [ ] {Métrica 1} (ej: "Tiempo de respuesta < 200ms")
- [ ] {Métrica 2} (ej: "Cobertura de tests > 80%")
- [ ] {Métrica 3} (ej: "0 vulnerabilidades críticas")

---

## Riesgos y mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| {Riesgo 1} | {Alta/Media/Baja} | {Alto/Medio/Bajo} | {Cómo mitigar} |
| {Riesgo 2} | {Alta/Media/Baja} | {Alto/Medio/Bajo} | {Cómo mitigar} |

---

## Rollback global

Si algo falla después de implementar todo el plan:
```bash
# Opción 1: Revertir todos los commits
git revert HEAD~{N}

# Opción 2: Restaurar desde backup
# [instrucciones]
```

---

## Referencias

- Plan de análisis completo: `docs/agentes/{agente}-{task}/01-analisis-detallado/`
- Evidencia de hallazgos: `docs/agentes/{agente}-{task}/03-evidencia/`
- Métricas cuantitativas: `docs/agentes/{agente}-{task}/04-metricas.md`
```

### Nivel de detalle esperado (ejemplo real):

**MAL (muy superficial):**
```markdown
## Tarea 1: Agregar validación de email

Modifica `src/routes/users.ts` para agregar validación de email.
```

**BIEN (detalle correcto):**
```markdown
## Tarea 1: Agregar validación de email en endpoint POST /api/users

**Objetivo:** Prevenir inyección de emails malformados y mejorar seguridad (OWASP A03:2021)

**Archivos a modificar:**
- `src/routes/users.ts` (líneas 45-67)
- `src/utils/validation.ts` (nuevo archivo)

**Cambio detallado:**

1. Crear `src/utils/validation.ts`:
```typescript
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}
```

2. Modificar `src/routes/users.ts` (línea 45):

```typescript
// ANTES:
app.post('/users', async (req, res) => {
  const { email, password } = req.body;
  const user = await createUser(email, password);
  res.json(user);
});

// DESPUÉS:
import { isValidEmail } from '../utils/validation';

app.post('/users', async (req, res) => {
  const { email, password } = req.body;
  
  // Validación de email (OWASP A03:2021)
  if (!email || !isValidEmail(email)) {
    return res.status(400).json({ 
      error: 'Invalid email format',
      code: 'VALIDATION_ERROR'
    });
  }
  
  const user = await createUser(email, password);
  res.json(user);
});
```

**Comandos a ejecutar:**
```bash
# Verificar que no hay errores de TypeScript
npx tsc --noEmit

# Correr tests de validación
npm test -- --grep "email validation"
```

**Output esperado:**
```
  Email validation
    ✓ should reject empty email
    ✓ should reject invalid format
    ✓ should accept valid email
```

**Criterios de aprobación:**
- [ ] TypeScript compila sin errores
- [ ] Tests de validación pasan
- [ ] Endpoint rechaza emails inválidos con status 400
- [ ] Endpoint acepta emails válidos

**Rollback plan:**
```bash
git revert HEAD
```

**Tiempo estimado:** 15 minutos
**Riesgo:** Bajo (solo agrega validación, no cambia lógica existente)
**Dependencias:** Ninguna (puede ejecutarse en cualquier momento)
```

---

### Fase 3 — Actualización del skill `opencode-model-router` (Días 8-10)

**Objetivo:** Actualizar el skill para que mapee tareas → agentes especializados.

**Cambios al skill:**

#### 3.1 Nueva tabla de routing
```markdown
## Routing Table (v2 — Multi-Model)
| Type | Agent | Model | Fallback Agent | Skill |
|------|-------|-------|----------------|-------|
| **Security audit** | `gentleman-security` | Qwen3.7 Max | `gentleman-deep` (Nemotron) | `security-scanner` |
| **Vulnerability analysis** | `gentleman-security` | Qwen3.7 Max | `gentleman-deep` | `security-scanner` |
| **SEO audit** | `gentleman-seo` | Qwen3.7 Plus | `gentleman-vMK` (default) | `seo` |
| **Content generation** | `gentleman-seo` | Qwen3.7 Plus | `gentleman-vMK` | `seo` |
| **Infrastructure / IaC** | `gentleman-infra` | GLM-5.2 | `gentleman-deep` | `ci-cd` |
| **Terraform / Kubernetes** | `gentleman-infra` | GLM-5.2 | `gentleman-deep` | `ci-cd` |
| **UI/UX / Frontend** | `gentleman-frontend` | Kimi K2.6 | `gentleman-quick` (MiMo) | `baseline-ui` |
| **React / Tailwind / Vue** | `gentleman-frontend` | Kimi K2.6 | `gentleman-quick` | `baseline-ui` |
| **Performance optimization** | `gentleman-performance` | Qwen3.7 Max | `gentleman-deep` | `performance` |
| **Query tuning** | `gentleman-performance` | Qwen3.7 Max | `gentleman-deep` | `performance` |
| **Data science / BI** | `gentleman-datascience` | GLM-5.1 | `gentleman-codex` (DeepSeek Flash) | — |
| **Python / Pandas / SQL** | `gentleman-datascience` | GLM-5.1 | `gentleman-codex` | — |
| **Documentation** | `gentleman-docs` | MiMo V2.5 Pro | `gentleman-vMK` | `cognitive-doc-design` |
| **API docs / README** | `gentleman-docs` | MiMo V2.5 Pro | `gentleman-vMK` | `cognitive-doc-design` |
| **Architecture** | `gentleman-vMK` | (default) | — | `senior-engineer` |
| **Codebase Audit >150K** | `gentleman-vMK` | (default) | — | `project-mapper` |
| **Code Review** | `gentleman-vMK` | (default) | — | `code-review-agent` |
| **Full Feature** | `gentleman-vMK` | (default) | — | `sdd-*` |
| **Quick edit** | `gentleman-quick` | MiMo V2.5 | `gentleman-codex` | — |
| **Script generation** | `gentleman-codex` | DeepSeek V4 Flash | `gentleman-quick` | — |
| Default | `gentleman-vMK` | (default) | — | `skill-graph` |
```

#### 3.2 Nueva sección: "Model Risk & Cost"
```markdown
## Model Risk & Cost (v2)
| Model | Risk | Cost | Notes |
|-------|------|------|-------|
| Qwen3.7 Max | Low | High | Security, performance. Use sparingly (sniper mode). |
| Qwen3.7 Plus | Low | Medium | SEO, content. Good for 90% of work. |
| GLM-5.2 | Low | High | Infrastructure. Use for critical IaC only. |
| GLM-5.1 | Low | Medium | Data science. Good balance. |
| Kimi K2.6 | Low | Medium | Frontend. Long context (1M). |
| MiMo V2.5 Pro | Medium | Low | Documentation. Trial model, may disappear. |
| DeepSeek V4 Flash | Medium | Very Low | Scripts, quick tasks. High volume OK. |
| MiniMax M2.5 | High | Very Low | Bulk content. Trial model. |
| Nemotron 3 Ultra | High | High | Deep reasoning. One-off only. |
| MiMo V2.5 | High | Very Low | Quick edits. Trial model. |
```

#### 3.3 Nueva sección: "Delegation Pattern (v2)"
```markdown
## Delegation Pattern (v2 — Multi-Model)
```
DETECT task type (from user request or skill-graph)
  → SECURITY? → DELEGATE to gentleman-security (Qwen3.7 Max)
  → SEO? → DELEGATE to gentleman-seo (Qwen3.7 Plus)
  → INFRA? → DELEGATE to gentleman-infra (GLM-5.2)
  → FRONTEND? → DELEGATE to gentleman-frontend (Kimi K2.6)
  → PERFORMANCE? → DELEGATE to gentleman-performance (Qwen3.7 Max)
  → DATA? → DELEGATE to gentleman-datascience (GLM-5.1)
  → DOCS? → DELEGATE to gentleman-docs (MiMo V2.5 Pro)
  → ARCHITECTURE/CODE REVIEW? → DIRECT (gentleman-vMK)
  → QUICK EDIT? → DELEGATE to gentleman-quick (MiMo V2.5)
  → SCRIPT? → DELEGATE to gentleman-codex (DeepSeek V4 Flash)

DELEGATE(agent, prompt + style hint)
  → OK → integrate result
  → fail (timeout/error) → FALLBACK to next agent in chain
  → partial → complete direct (gentleman-vMK)
```
```

**Criterio de éxito:** Skill actualizado con nueva tabla de routing, sección de costo, y patrón de delegación v2.

**Dependencias:** Fase 2 (agentes creados).

---

### Fase 4 — Documentación de estrategia (Días 11-14)

**Objetivo:** Documentar la estrategia de uso para que el usuario y futuros agentes entiendan cómo usar el sistema.

**Archivos a crear:**

#### 4.1 `docs/mejoras/MODEL-ROUTING-STRATEGY.md`
Contenido:
- Explicación de la estrategia 90/10 (90% tareas diarias con modelos baratos, 10% tareas críticas con modelos caros)
- Modo "Sniper": cuándo cambiar manualmente a modelos caros
- Contexto largo: cuándo usar Kimi K2.6 o Qwen3.7 Plus (1M tokens)
- Fallback chains: qué hacer cuando un modelo falla
- Métricas de costo: cómo trackear gasto por tarea

#### 4.2 `docs/mejoras/MODEL-COST-TRACKING.md`
Contenido:
- Tabla de costo estimado por modelo (si está disponible)
- Ejemplos de costo por tarea (ej: "auditoría de seguridad con Qwen3.7 Max = ~$0.50")
- Cómo calcular el gasto mensual
- Alertas de presupuesto (cuando se acerca a $10/mes)

#### 4.3 `docs/mejoras/MODEL-AVAILABILITY.md`
Contenido:
- Lista de modelos disponibles en OpenCode GO (de Fase 1)
- IDs exactos de cada modelo
- Fecha de última verificación
- Notas sobre modelos trial vs production

**Criterio de éxito:** 3 documentos creados con estrategia clara.

**Dependencias:** Fase 1, Fase 2, Fase 3.

---

### Fase 5 — Testing y validación (Días 15-20)

**Objetivo:** Probar que el routing funciona correctamente y que los agentes especializados producen mejores resultados que el agente genérico.

**Acciones:**
1. Probar cada agente especializado con una tarea de ejemplo de su área
2. Comparar calidad de output vs agente genérico (gentleman-vMK)
3. Medir tiempo de respuesta y costo (si hay métricas disponibles)
4. Documentar resultados en `docs/mejoras/MODEL-ROUTING-TEST-RESULTS.md`

**Criterio de éxito:** Todos los agentes especializados funcionan y producen output de calidad ≥ agente genérico.

**Dependencias:** Fase 2, Fase 3.

---

### Fase 6 — Iteración y mejora (Días 21-31)

**Objetivo:** Ajustar el sistema basado en feedback real de uso durante los primeros 20 días.

**Acciones:**
1. Revisar métricas de uso (qué agentes se usan más, cuáles menos)
2. Ajustar prompts de agentes subóptimos
3. Agregar fallbacks si un modelo falla frecuentemente
4. Documentar learnings en `docs/mejoras/MODEL-ROUTING-LEARNINGS.md`

**Criterio de éxito:** Sistema ajustado y documentado con learnings reales.

**Dependencias:** Fase 5.

---

## 4. Riesgos y mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Modelos de la guía no están disponibles en OpenCode GO | Alta | Alto | Fase 1 verifica disponibilidad; si faltan, contactar al usuario |
| Agentes especializados producen peor output que el genérico | Media | Medio | Fase 5 testing; si falla, ajustar prompt o cambiar modelo |
| Costo excede $10/mes | Media | Alto | Fase 4 documenta estrategia 90/10; trackear gasto |
| Modelos trial desaparecen mid-task | Alta | Medio | Fallback chains (Fase 3) + documentación de modelos production |
| Usuario no entiende cómo usar el routing | Media | Medio | Fase 4 documentación clara + ejemplos de uso |

---

## 5. Criterios de éxito globales

1. ✅ 7 agentes especializados creados y funcionando
2. ✅ Skill `opencode-model-router` actualizado con tabla v2
3. ✅ 3 documentos de estrategia creados
4. ✅ Testing completado con resultados documentados
5. ✅ Learnings documentados después de 20 días de uso
6. ✅ Costo mensual ≤ $10 (o justificado si excede)

---

## 6. Próximos pasos inmediatos (para el agente implementador)

1. **HOY (Día 1):** Ejecutar Fase 1 — verificar disponibilidad de modelos
2. **Días 2-7:** Ejecutar Fase 2 — crear 7 agentes especializados
3. **Días 8-10:** Ejecutar Fase 3 — actualizar skill `opencode-model-router`
4. **Días 11-14:** Ejecutar Fase 4 — crear documentación de estrategia
5. **Días 15-20:** Ejecutar Fase 5 — testing y validación
6. **Días 21-31:** Ejecutar Fase 6 — iteración y mejora

---

## 7. Notas para el agente implementador

- **NO modifiques los agentes existentes** (gentleman-deep, gentleman-quick, gentleman-codex) — solo agrega los 7 nuevos
- **NO cambies el modelo de gentleman-vMK** — sigue siendo el default
- **Verifica IDs de modelos** en Fase 1 antes de crear agentes — los IDs de la guía pueden no ser exactos
- **Documenta TODO** en `docs/mejoras/` — futuros agentes necesitan entender las decisiones
- **Testea cada agente** antes de declararlo listo — no asumas que funciona porque el modelo es "bueno"
- **Trackea el costo** — si no hay métricas automáticas, crea un log manual en `docs/mejoras/cost-log.md`

---

## 8. Referencias

- Guía de modelos OpenCode GO (proporcionada por el usuario, 2026-07-05)
- Configuración actual: `opencode.json` (proyecto) y `~/.config/opencode/opencode.json` (global)
- Skill actual: `.agents/skills/opencode-model-router/SKILL.md`
- Plan de auditoría multiagente v2: `docs/mejoras/PLAN-auditoria-multiagente-v2.md`

---

## 9. Troubleshooting (qué hacer si algo falla)

### 9.1 Un modelo no está disponible

**Síntoma:** Al crear un agente con un ID de modelo, OpenCode reporta "model not found" o similar.

**Solución:**
1. Prueba las alternativas de la tabla en sección 0.6
2. Si ninguna alternativa funciona, ejecuta `opencode models list` para ver modelos disponibles
3. Si el modelo definitivamente no existe, marca ese agente como "pendiente" y usa el fallback:
   - Seguridad → fallback a `gentleman-deep` (Nemotron)
   - SEO → fallback a `gentleman-vMK` (default)
   - Infra → fallback a `gentleman-deep` (Nemotron)
   - Frontend → fallback a `gentleman-quick` (MiMo)
   - Performance → fallback a `gentleman-deep` (Nemotron)
   - Data Science → fallback a `gentleman-codex` (DeepSeek Flash)
   - Docs → fallback a `gentleman-vMK` (default)
4. Documenta el problema en `docs/mejoras/MODEL-AVAILABILITY.md`

### 9.2 Un agente especializado produce peor output que el genérico

**Síntoma:** El output de `gentleman-security` es menos detallado que el de `gentleman-vMK` para la misma tarea de seguridad.

**Solución:**
1. Revisa el prompt del agente — ¿tiene las instrucciones correctas?
2. Compara los prompts de `gentleman-vMK` (en `AGENTS.md`) con el prompt del agente especializado
3. Ajusta el prompt del agente especializado para incluir:
   - Instrucciones más específicas del dominio
   - Ejemplos de output esperado
   - Referencias a skills relevantes (ej: `security-scanner` para seguridad)
4. Si el problema persiste, prueba un modelo diferente (ej: si Qwen3.7 Max falla, prueba Nemotron)
5. Documenta el ajuste en `docs/mejoras/MODEL-ROUTING-LEARNINGS.md`

### 9.3 El costo excede $10/mes

**Síntoma:** A mitad de mes, el gasto ya supera $7.

**Solución:**
1. Revisa qué agentes se están usando más (si hay métricas)
2. Cambia tareas de modelos caros a modelos baratos:
   - Tareas de seguridad rutinarias → `gentleman-deep` (Nemotron) en vez de `gentleman-security` (Qwen3.7 Max)
   - Tareas de performance simples → `gentleman-deep` en vez de `gentleman-performance`
3. Aplica la regla 90/10 estrictamente: 90% de tareas con modelos baratos, 10% con modelos caros
4. Documenta el ajuste en `docs/mejoras/MODEL-COST-TRACKING.md`

### 9.4 Un modelo trial desaparece mid-task

**Síntoma:** Un agente que funcionaba ayer hoy reporta "model unavailable".

**Solución:**
1. Usa el fallback chain (sección 3.2)
2. Reemplaza el modelo trial con un modelo production similar:
   - MiMo V2.5 Pro → MiMo V2.5 o Qwen3.7 Plus
   - MiniMax M2.5 → DeepSeek V4 Flash
   - Nemotron 3 Ultra → Qwen3.7 Max
3. Actualiza la configuración del agente con el nuevo modelo
4. Documenta el cambio en `docs/mejoras/MODEL-AVAILABILITY.md`

### 9.5 El routing no delega al agente correcto

**Síntoma:** El usuario pide una tarea de seguridad pero `gentleman-vMK` la ejecuta en vez de delegar a `gentleman-security`.

**Solución:**
1. Revisa el skill `opencode-model-router` — ¿tiene la tabla v2 actualizada?
2. Revisa las palabras clave de detección — ¿incluye términos como "seguridad", "vulnerabilidad", "OWASP"?
3. Ajusta el skill para incluir más palabras clave por área
4. Si el problema persiste, el usuario puede forzar el agente manualmente con `/agent gentleman-security`
5. Documenta el ajuste en `docs/mejoras/MODEL-ROUTING-LEARNINGS.md`

---

## 10. Ejemplos de uso (cómo se verá el sistema en producción)

### Ejemplo 1: Tarea de seguridad

**Usuario:** "Audita este código en busca de vulnerabilidades de inyección SQL"

**Flujo esperado:**
1. `gentleman-vMK` recibe la tarea
2. Detecta palabras clave: "vulnerabilidades", "inyección SQL", "seguridad"
3. Consulta `opencode-model-router` → mapea a `gentleman-security`
4. Delega a `gentleman-security` con prompt: "Audita el código en busca de vulnerabilidades de inyección SQL. Usa OWASP Top 10 como referencia."
5. `gentleman-security` (Qwen3.7 Max) ejecuta la auditoría
6. Devuelve resultados a `gentleman-vMK`
7. `gentleman-vMK` integra resultados y presenta al usuario

**Fallback:** Si `gentleman-security` falla, `gentleman-vMK` ejecuta directamente con skill `security-scanner`.

### Ejemplo 2: Tarea de SEO

**Usuario:** "Genera meta descriptions para las 50 páginas de mi sitio"

**Flujo esperado:**
1. `gentleman-vMK` recibe la tarea
2. Detecta palabras clave: "meta descriptions", "SEO"
3. Consulta `opencode-model-router` → mapea a `gentleman-seo`
4. Delega a `gentleman-seo` con prompt: "Genera meta descriptions para 50 páginas. Usa contexto largo para analizar todo el sitio."
5. `gentleman-seo` (Qwen3.7 Plus, 1M tokens) analiza el sitio completo
6. Devuelve 50 meta descriptions optimizadas
7. `gentleman-vMK` presenta resultados al usuario

**Fallback:** Si `gentleman-seo` falla, `gentleman-vMK` ejecuta directamente con skill `seo`.

### Ejemplo 3: Tarea de infraestructura

**Usuario:** "Escribe un Terraform module para desplegar un cluster de Kubernetes en AWS"

**Flujo esperado:**
1. `gentleman-vMK` recibe la tarea
2. Detecta palabras clave: "Terraform", "Kubernetes", "AWS", "cluster"
3. Consulta `opencode-model-router` → mapea a `gentleman-infra`
4. Delega a `gentleman-infra` con prompt: "Escribe un Terraform module para Kubernetes en AWS. Prioriza logical reasoning y dependency management."
5. `gentleman-infra` (GLM-5.2) genera el module
6. Devuelve código a `gentleman-vMK`
7. `gentleman-vMK` presenta resultados al usuario

**Fallback:** Si `gentleman-infra` falla, `gentleman-deep` (Nemotron) ejecuta directamente.

### Ejemplo 4: Tarea de frontend

**Usuario:** "Convierte este diseño de Figma a React + Tailwind"

**Flujo esperado:**
1. `gentleman-vMK` recibe la tarea
2. Detecta palabras clave: "Figma", "React", "Tailwind", "diseño"
3. Consulta `opencode-model-router` → mapea a `gentleman-frontend`
4. Delega a `gentleman-frontend` con prompt: "Convierte el diseño de Figma a React + Tailwind. Usa contexto largo para leer la documentación de Tailwind completa."
5. `gentleman-frontend` (Kimi K2.6, 1M tokens) genera el código
6. Devuelve componentes React a `gentleman-vMK`
7. `gentleman-vMK` presenta resultados al usuario

**Fallback:** Si `gentleman-frontend` falla, `gentleman-quick` (MiMo) ejecuta directamente.

### Ejemplo 5: Tarea de performance

**Usuario:** "Optimiza esta query SQL que tarda 10 segundos"

**Flujo esperado:**
1. `gentleman-vMK` recibe la tarea
2. Detecta palabras clave: "optimiza", "query SQL", "tarda", "performance"
3. Consulta `opencode-model-router` → mapea a `gentleman-performance`
4. Delega a `gentleman-performance` con prompt: "Optimiza esta query SQL. Analiza Big O complexity y sugiere índices."
5. `gentleman-performance` (Qwen3.7 Max) analiza y optimiza
6. Devuelve query optimizada a `gentleman-vMK`
7. `gentleman-vMK` presenta resultados al usuario

**Fallback:** Si `gentleman-performance` falla, `gentleman-deep` (Nemotron) ejecuta directamente.

### Ejemplo 6: Tarea de data science

**Usuario:** "Limpia este dataset de 100K filas con Pandas"

**Flujo esperado:**
1. `gentleman-vMK` recibe la tarea
2. Detecta palabras clave: "dataset", "Pandas", "limpia"
3. Consulta `opencode-model-router` → mapea a `gentleman-datascience`
4. Delega a `gentleman-datascience` con prompt: "Limpia este dataset con Pandas. Prioriza precisión matemática y evita alucinar librerías."
5. `gentleman-datascience` (GLM-5.1) genera el script de limpieza
6. Devuelve script a `gentleman-vMK`
7. `gentleman-vMK` presenta resultados al usuario

**Fallback:** Si `gentleman-datascience` falla, `gentleman-codex` (DeepSeek Flash) ejecuta directamente.

### Ejemplo 7: Tarea de documentación

**Usuario:** "Escribe un README para esta librería"

**Flujo esperado:**
1. `gentleman-vMK` recibe la tarea
2. Detecta palabras clave: "README", "librería", "documentación"
3. Consulta `opencode-model-router` → mapea a `gentleman-docs`
4. Delega a `gentleman-docs` con prompt: "Escribe un README para esta librería. Prioriza claridad, consistencia y reducción de carga cognitiva."
5. `gentleman-docs` (MiMo V2.5 Pro) genera el README
6. Devuelve README a `gentleman-vMK`
7. `gentleman-vMK` presenta resultados al usuario

**Fallback:** Si `gentleman-docs` falla, `gentleman-vMK` ejecuta directamente con skill `cognitive-doc-design`.

---

## 11. Métricas de éxito (cómo medir si el sistema funciona)

### 11.1 Métricas cuantitativas

| Métrica | Objetivo | Cómo medir |
|---|---|---|
| **Tasa de delegación correcta** | ≥ 90% | (tareas delegadas al agente correcto) / (total tareas) |
| **Tasa de fallback** | ≤ 10% | (tareas que necesitaron fallback) / (total tareas delegadas) |
| **Costo mensual** | ≤ $10 | Suma de costos por tarea (si hay métricas) |
| **Tiempo de respuesta** | ≤ tiempo del agente genérico | Promedio de tiempo por tarea especializada vs genérica |
| **Calidad de output** | ≥ agente genérico | Evaluación humana o métricas automáticas (si existen) |

### 11.2 Métricas cualitativas

| Métrica | Objetivo | Cómo medir |
|---|---|---|
| **Satisfacción del usuario** | Alta | Feedback directo del usuario |
| **Facilidad de uso** | Alta | ¿El usuario necesita intervenir manualmente? |
| **Confiabilidad** | Alta | ¿Los agentes especializados funcionan consistentemente? |
| **Mantenibilidad** | Alta | ¿Es fácil agregar nuevos agentes o cambiar modelos? |

### 11.3 Cómo trackear métricas

**Opción 1: Métricas automáticas (si OpenCode las provee)**
- Revisa si OpenCode tiene métricas de uso por agente
- Si las tiene, exporta a `docs/mejoras/metrics-{month}.md`

**Opción 2: Métricas manuales (si no hay automáticas)**
- Crea un log en `docs/mejoras/cost-log.md` con formato:
  ```
  ## 2026-07-05
  - Tarea: Auditoría de seguridad
  - Agente: gentleman-security
  - Modelo: Qwen3.7 Max
  - Tiempo: 2 min
  - Costo estimado: $0.50
  - Resultado: OK
  ```
- Actualiza el log después de cada tarea
- Al final del mes, suma costos y calcula métricas

**Opción 3: Métricas híbridas**
- Usa métricas automáticas si están disponibles
- Complementa con log manual para tareas críticas
- Revisa métricas semanalmente

---

## 12. Checklists de verificación (ejecuta ANTES de marcar fase como completada)

### Checklist Fase 1 — Verificación de disponibilidad

- [ ] Ejecuté `opencode models list` o equivalente
- [ ] Verifiqué los IDs de los 10 modelos de la guía
- [ ] Documenté los IDs correctos en `docs/mejoras/MODEL-AVAILABILITY.md`
- [ ] Identifiqué qué modelos NO están disponibles
- [ ] Para modelos no disponibles, definí fallbacks
- [ ] Pregunté al usuario si hay modelos que necesitan activación manual

### Checklist Fase 2 — Creación de agentes

- [ ] Creé los 7 agentes especializados en `opencode.json`
- [ ] Cada agente tiene el modelo correcto (verificado en Fase 1)
- [ ] Cada agente tiene un prompt específico del dominio
- [ ] Cada agente tiene permisos correctos (bash, edit, read, write)
- [ ] NO modifiqué los agentes existentes (gentleman-deep, gentleman-quick, gentleman-codex)
- [ ] NO cambié el modelo de gentleman-vMK
- [ ] Probé cada agente con una tarea simple para verificar que funciona

### Checklist Fase 3 — Actualización del router

- [ ] Actualicé la tabla de routing en `opencode-model-router/SKILL.md`
- [ ] La tabla incluye los 7 agentes nuevos + los 4 existentes
- [ ] Agregué la sección "Model Risk & Cost"
- [ ] Agregué la sección "Delegation Pattern (v2)"
- [ ] Las palabras clave de detección cubren todos los dominios
- [ ] Los fallback chains están documentados
- [ ] Probé el routing con una tarea de cada dominio

### Checklist Fase 4 — Documentación

- [ ] Creé `docs/mejoras/MODEL-ROUTING-STRATEGY.md` con estrategia 90/10
- [ ] Creé `docs/mejoras/MODEL-COST-TRACKING.md` con ejemplos de costo
- [ ] Creé `docs/mejoras/MODEL-AVAILABILITY.md` con IDs de modelos
- [ ] Los documentos son claros y auto-contenidos
- [ ] Los documentos incluyen ejemplos de uso

### Checklist Fase 5 — Testing

- [ ] Probé cada agente especializado con una tarea de ejemplo
- [ ] Comparé output vs agente genérico
- [ ] Documenté resultados en `docs/mejoras/MODEL-ROUTING-TEST-RESULTS.md`
- [ ] Todos los agentes funcionan correctamente
- [ ] Los fallbacks funcionan cuando un agente falla

### Checklist Fase 6 — Iteración

- [ ] Revisé métricas de uso (si están disponibles)
- [ ] Ajusté prompts de agentes subóptimos
- [ ] Agregué fallbacks si un modelo falla frecuentemente
- [ ] Documenté learnings en `docs/mejoras/MODEL-ROUTING-LEARNINGS.md`
- [ ] El sistema está optimizado para uso real

---

## 13. Resumen final (para el agente implementador)

**Tu trabajo es:**
1. Leer este plan completo
2. Ejecutar las 6 fases en orden
3. Seguir las checklists de verificación
4. Documentar TODO en `docs/mejoras/`
5. Si algo falla, consultar sección 9 (Troubleshooting)
6. Al finalizar, crear `docs/mejoras/IMPLEMENTATION-SUMMARY.md`

**NO hagas:**
- ❌ Modificar agentes existentes
- ❌ Cambiar el modelo de gentleman-vMK
- ❌ Saltar fases
- ❌ Asumir que un modelo está disponible sin verificar
- ❌ Documentar solo al final — documenta mientras avanzas
- ❌ **PERMITIR que los agentes especializados implementen cambios** — solo analizan y proponen planes

**SÍ haz:**
- ✅ Verificar IDs de modelos antes de crear agentes
- ✅ Probar cada agente antes de declararlo listo
- ✅ Documentar decisiones y learnings
- ✅ Preguntar al usuario si hay dudas
- ✅ Trackear el costo mensual
- ✅ **Enfatizar en los prompts que los agentes SOLO analizan y guardan planes en `docs/agentes/{agente-tarea}/`**
- ✅ **Asegurar que los planes sean TAN DETALLADOS que otro agente pueda implementarlos sin contexto adicional**

**Éxito =** 7 agentes especializados funcionando + routing automático + documentación completa + costo ≤ $10/mes + agentes que SOLO analizan y proponen planes detallados

---

## 14. Cómo otro agente puede implementar los planes generados

**IMPORTANTE:** Los agentes especializados SOLO analizan y proponen planes. La implementación la hace OTRO agente (o el usuario). Esta sección explica cómo.

### Flujo de implementación:

```
1. USUARIO pide análisis: "Audita la seguridad de este proyecto"
   ↓
2. GENTLEMAN-VMK detecta tarea de seguridad → delega a gentleman-security
   ↓
3. GENTLEMAN-SECURITY analiza el proyecto (SOLO LEE, no modifica)
   ↓
4. GENTLEMAN-SECURITY guarda plan detallado en:
   docs/agentes/security-auth-audit/
   ├── 00-resumen-ejecutivo.md
   ├── 01-analisis-detallado/
   ├── 02-plan-implementacion.md  ← ESTE es el plan a implementar
   ├── 03-evidencia/
   └── 04-metricas.md
   ↓
5. GENTLEMAN-SECURITY reporta a gentleman-vMK: "Análisis completo, plan guardado"
   ↓
6. GENTLEMAN-VMK presenta al usuario:
   "Análisis de seguridad completado. Encontré X vulnerabilidades.
    Plan detallado guardado en docs/agentes/security-auth-audit/02-plan-implementacion.md
    ¿Quieres que implemente el plan?"
   ↓
7. USUARIO aprueba: "Sí, implementa el plan"
   ↓
8. GENTLEMAN-VMK (o un agente de implementación) lee el plan:
   docs/agentes/security-auth-audit/02-plan-implementacion.md
   ↓
9. GENTLEMAN-VMK ejecuta las tareas del plan EN ORDEN:
   - Tarea 1: Agregar validación de email
   - Tarea 2: Implementar rate limiting
   - Tarea 3: Configurar CORS
   - ...
   ↓
10. GENTLEMAN-VMK verifica métricas de éxito después de cada tarea
    ↓
11. GENTLEMAN-VMK reporta al usuario: "Plan implementado. Métricas: X vulnerabilidades corregidas"
```

### Roles y responsabilidades:

| Rol | Qué hace | Qué NO hace |
|---|---|---|
| **Agente especializado** (security, seo, infra, etc.) | Analiza, identifica gaps, propone plan detallado, guarda en `docs/agentes/` | NO implementa cambios, NO modifica archivos del proyecto |
| **Gentleman-vMK** (orquestador) | Recibe tarea, delega al agente correcto, presenta resultados al usuario, implementa plan si usuario aprueba | NO analiza en detalle (delega) |
| **Usuario** | Aprueba o rechaza el plan, decide si implementar | NO analiza (delega al agente) |

### Ejemplo concreto:

**Paso 1: Usuario pide análisis**
```
Usuario: "Audita la seguridad de mi API"
```

**Paso 2: Gentleman-vMK delega**
```
gentleman-vMK → gentleman-security: "Analiza la seguridad de la API en src/routes/"
```

**Paso 3: Gentleman-security analiza (SOLO LEE)**
```
gentleman-security:
- Lee src/routes/users.ts
- Lee src/routes/auth.ts
- Lee src/middleware/auth.ts
- Identifica 3 vulnerabilidades:
  1. SQL injection en /api/users (línea 45)
  2. Missing rate limiting en /api/login
  3. CORS misconfigured
```

**Paso 4: Gentleman-security guarda plan**
```
Crea docs/agentes/security-api-audit/02-plan-implementacion.md con:

## Tarea 1: Fix SQL injection en /api/users

**Archivo:** src/routes/users.ts (línea 45)

**Cambio:**
```typescript
// ANTES:
const user = await db.query(`SELECT * FROM users WHERE id = ${req.params.id}`);

// DESPUÉS:
const user = await db.query('SELECT * FROM users WHERE id = $1', [req.params.id]);
```

**Comando de verificación:**
```bash
npm test -- --grep "SQL injection"
```

**Tiempo estimado:** 5 minutos
**Riesgo:** Bajo
```

**Paso 5: Gentleman-vMK presenta al usuario**
```
gentleman-vMK: "Análisis de seguridad completado.
Encontré 3 vulnerabilidades:
1. SQL injection en /api/users (Crítico)
2. Missing rate limiting en /api/login (Alto)
3. CORS misconfigured (Medio)

Plan detallado guardado en: docs/agentes/security-api-audit/02-plan-implementacion.md

¿Quieres que implemente el plan?"
```

**Paso 6: Usuario aprueba**
```
Usuario: "Sí, implementa el plan"
```

**Paso 7: Gentleman-vMK implementa**
```
gentleman-vMK lee docs/agentes/security-api-audit/02-plan-implementacion.md
Ejecuta Tarea 1: Fix SQL injection
Ejecuta Tarea 2: Add rate limiting
Ejecuta Tarea 3: Fix CORS
Verifica métricas de éxito
Reporta: "Plan implementado. 3 vulnerabilidades corregidas."
```

### Ventajas de este enfoque:

1. **Separación de responsabilidades:** Los agentes especializados son expertos en análisis, no en implementación.
2. **Control humano:** El usuario aprueba el plan antes de que se implemente.
3. **Trazabilidad:** Todos los planes están documentados en `docs/agentes/` para referencia futura.
4. **Reutilización:** Otros agentes o desarrolladores pueden implementar los planes sin contexto adicional.
5. **Seguridad:** Los agentes de análisis NO pueden modificar el proyecto accidentalmente.

### Desventajas:

1. **Dos pasos:** Primero análisis, luego implementación (más lento que hacer todo de una vez).
2. **Más archivos:** Se generan muchos documentos en `docs/agentes/`.
3. **Requiere aprobación humana:** No es 100% automático.

### Cuándo usar este enfoque:

✅ **Úsalo para:**
- Auditorías de seguridad, performance, SEO, accesibilidad
- Análisis de arquitectura o código
- Tareas críticas donde el error es costoso
- Cuando quieres revisar el plan antes de implementar

❌ **NO lo uses para:**
- Tareas triviales (renombrar una variable, agregar un comentario)
- Cambios rápidos de una línea
- Cuando el usuario dice "solo hazlo, no me preguntes"

En esos casos, gentleman-vMK puede implementar directamente sin delegar a un agente especializado.
