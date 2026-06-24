# Análisis Consolidado — mdShare → gentleman-agent-gh + opencode-vMK

> Generado: 2026-06-23 desde 12 documentos en D:\mdShare
> Propósito: Centralizar hallazgos, gaps y acciones de los docs de investigación

---

## 1. Documentos Analizados

| Archivo | Temas | Relevancia |
|---------|-------|------------|
| `agente-auto-modificable-host-aware-cuantizacion-extrema.md` | Darwin Gödel Machine, auto-rewriting, host profiling, extreme quantization | Arquitectura futura |
| `agente-ia-vs-gentle-ai.md` | Comparativa agente genérico vs Gentle-AI | Contexto conceptual |
| `aplicacion-plan-auto-mejora-auditoria.md` | Auditoría de claims, anti-patrones, corrección de datos | **Proceso de calidad** |
| `entrenar-vs-mejorar-ciclo-auto-mejora.md` | Scaffolding evolution vs weight training | Arquitectura futura |
| `gentle-ai-mejoras-vs-gentleman-agent-gh.md` | **Comparativa directa: gaps y mejoras** | **ALTA** |
| `opencode-free-specialities-v3.md` | Model routing por especialidad | Contexto de modelos |
| `opencode-free-specialities-v3(1).md` | Model routing con fallback strategy | Contexto de modelos |
| `opencode-vs-luisalbertomk-opencode-optimizacion.md` | Benchmarking fork vMK vs upstream | Estado del fork |
| `optimizacion-ram-cpu-gpu-gentle-ai-vs-gentleman-agent-gh.md` | Resource profiling, token context cost | **Medición de impacto** |
| `plan-auto-mejora-claude-v2.md` | Auto-improvement plan v2 con correcciones | **Proceso de mejora** |
| `plan-auto-mejora-claude.md` | Auto-improvement plan v1 original | Proceso de mejora |

---

## 2. Gaps Identificados — gentleman-agent-gh

### 2.1 Estado actual (verificado vs .project.json)
| Dimensión | Score | Gap respecto a mdShare |
|-----------|-------|------------------------|
| Project Artifacts | 10/10 | Sin gap |
| Security | 10/10 | Sin gap |
| Dead Code | 10/10 | Sin gap |
| Clean Code | 9.9/10 | Sin gap |
| Best Practices | 10/10 | Sin gap |
| Bitacora | 10/10 | Sin gap |
| Metrics | 10/10 | Sin gap |
| Script Performance | 9/10 | Gap menor |
| Skill Effectiveness | 10/10 | Sin gap |
| **Score General** | **9.9/10** | **Muy alto** |

### 2.2 Gaps de mdShare aún potencialmente abiertos
| Gap del doc | Estado actual | Acción |
|-------------|--------------|--------|
| "Path hardcodeado" en AGENTS.md | No verificado | 🔍 Diagnosticar |
| "AGENTS.md no portable" | No verificado | 🔍 Diagnosticar |
| "model pin nulo en sdd-orchestrator" | No verificado | 🔍 Diagnosticar |
| "conteo de skills inconsistente" | 70 dirs vs 69 reportados | 🔍 Diagnosticar |
| Backup/rollback de configuración | No verificado | 🔍 Diagnosticar |

### 2.3 Recomendaciones del doc que aplicar
| Mejora | Esfuerzo | Impacto |
|--------|----------|---------|
| Portar AGENTS.md a formato OS-agnóstico | Medio | Portabilidad |
| Fijar modelo explícito en sdd-orchestrator | Bajo | Consistencia |
| Sincronizar conteo de skills | Bajo | Integridad |
| Script Performance (score 9) | Bajo | Limpieza |

---

## 3. Gaps Identificados — opencode-vMK (D:\opencode)

### 3.1 Estado actual
| Área | Estado | Referencia doc |
|------|--------|----------------|
| `noUncheckedIndexedAccess: false` | ⚠️ Abierto | opencode-vs-luisalbertomk-opencode-optimizacion.md |
| 9 dependencias parcheadas | ⚠️ Riesgo de drift | Misma fuente |
| 95+ runtime deps | ⚠️ Árbol pesado | Misma fuente |
| Sin Dependabot/Renovate | ⚠️ Abierto | Misma fuente |
| Tests con `--only-failures` | ⚠️ Puede ocultar regresiones | Misma fuente |
| Documentación escasa | ⚠️ Abierto | Misma fuente |
| TALE budgets | ✅ Implementado | Sesión anterior |
| sideEffects:false | ✅ Implementado | Sesión anterior |
| Memoization Token.estimate | ✅ Implementado | Sesión anterior |

---

## 4. Plan de Auto-Mejora (de plan-auto-mejora-claude-v2.md)

| Fase | Aplica a | Estado |
|------|----------|--------|
| Fase 0: Baseline medible | Ambos | ✅ Ya existe (.project.json, métricas) |
| Fase 1: Auto-evaluación continua | gentleman-agent-gh | ✅ Judgment Day, triple verify |
| Fase 2: Memoria eficiente | Ambos | ✅ Engram implementado |
| Fase 3: Anti-patrones | gentleman-agent-gh | ✅ ANTI-PATTERN-CATALOG.md existe |
| Fase 4: Token economy | opencode-vMK | ✅ TALE budgets implementados |
| Fase 5: Skills modulares | gentleman-agent-gh | ✅ Skill registry activo |
| Fase 6: Rollback seguro | opencode-vMK | ⚠️ Backup tag creado (v1) |
| Fase 7: Restricciones duras | Ambos | ⚠️ Seguridad OK, recursos OK |

---

## 5. Acciones Prioritarias

### ALTA (implementar ahora)
1. Diagnosticar gaps de mdShare en gentleman-agent-gh
2. Sincronizar conteo de skills
3. Registrar métricas y bitácora

### MEDIA (próximo ciclo)
1. noUncheckedIndexedAccess en opencode-vMK
2. Portar AGENTS.md a path agnóstico
3. Fijar model pin en sdd-orchestrator

### BAJA (monitorear)
1. Dependabot/Renovate
2. Documentación opencode-vMK
3. Backup/rollback automático

---

## 6. Referencias

- D:\gentleman-agent-gh → Repo skills de agente (score actual: 9.9/10)
- D:\opencode → Fork opencode-vMK (score: 7.3/10, tras optimización)
- D:\mdShare → 12 documentos de investigación/análisis
- D:\mdShare\gentle-ai-mejoras-vs-gentleman-agent-gh.md → Comparativa principal
- D:\mdShare\opencode-vs-luisalbertomk-opencode-optimizacion.md → Benchmark fork
- D:\mdShare\plan-auto-mejora-claude-v2.md → Plan de mejora aplicable
