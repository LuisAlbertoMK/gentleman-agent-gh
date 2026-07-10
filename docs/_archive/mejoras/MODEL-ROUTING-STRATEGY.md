# Multi-Model Routing Strategy

> **Version**: 2.0
> **Date**: 2026-07-05
> **Budget**: $10/mes
> **Strategy**: 90/10 Rule

---

## Executive Summary

Este documento explica cómo usar el sistema de multi-model routing para optimizar costo y calidad. La estrategia se basa en la **regla 90/10**: 90% de tareas con modelos baratos, 10% con modelos caros para análisis crítico.

---

## Arquitectura del Sistema

### Flujo de Trabajo

```
USUARIO pide tarea
  ↓
GENTLEMAN-VMK detecta tipo de tarea
  ↓
¿Es análisis (seguridad, SEO, infra, etc.)?
  → SÍ: Delega a agente especializado (SOLO ANALIZA)
  → NO: Ejecuta directamente o delega a gentleman-codex/quick
  ↓
Agente especializado analiza y guarda plan en docs/agentes/{agent}-{task}/
  ↓
GENTLEMAN-VMK presenta plan al usuario
  ↓
Usuario aprueba
  ↓
GENTLEMAN-VMK delega a gentleman-implementer (MiMo V2.5 Pro)
  ↓
Implementer ejecuta el plan paso a paso
  ↓
Implementer reporta completitud
```

### Roles y Responsabilidades

| Rol | Agente | Modelo | Qué hace | Qué NO hace |
|---|---|---|---|---|
| **Orquestador** | gentleman-vMK | (default) | Recibe tareas, delega, presenta resultados | NO analiza en detalle |
| **Analista de Seguridad** | gentleman-security | Qwen3.7 Max | Analiza vulnerabilidades, OWASP, supply chain | NO implementa cambios |
| **Analista SEO** | gentleman-seo | Qwen3.7 Plus | Analiza SEO, contenido, schema markup | NO implementa cambios |
| **Analista Infra** | gentleman-infra | GLM-5.2 | Analiza IaC, K8s, Terraform, CI/CD | NO implementa cambios |
| **Analista Frontend** | gentleman-frontend | Kimi K2.6 | Analiza UI/UX, React, Tailwind, a11y | NO implementa cambios |
| **Analista Performance** | gentleman-performance | Qwen3.7 Max | Analiza performance, queries, bottlenecks | NO implementa cambios |
| **Analista Data** | gentleman-datascience | GLM-5.1 | Analiza pipelines, SQL, estadísticas | NO implementa cambios |
| **Analista Docs** | gentleman-docs | MiMo V2.5 Pro | Analiza documentación, READMEs, API docs | NO implementa cambios |
| **Implementador** | gentleman-implementer | MiMo V2.5 Pro | Ejecuta planes de agentes especializados | NO analiza, solo ejecuta |
| **Quick Edit** | gentleman-quick | MiMo V2.5 | Ediciones rápidas, cambios pequeños | NO análisis complejos |
| **Code Gen** | gentleman-codex | DeepSeek V4 Flash | Scripts, tool calling, código general | NO análisis complejos |
| **Deep Reasoning** | gentleman-deep | Nemotron 3 Ultra | Arquitectura, debugging complejo | NO tareas rutinarias |

---

## Regla 90/10

### 90% de Tareas (Modelos Baratos)

Usa estos modelos para la mayoría del trabajo diario:

| Modelo | Costo | Uso |
|---|---|---|
| Qwen3.7 Plus | Medio | SEO, contenido, análisis de contexto largo |
| DeepSeek V4 Flash | Muy Bajo | Scripts, ediciones rápidas, tool calling |
| MiMo V2.5 | Muy Bajo | Ediciones rápidas (trial) |
| MiMo V2.5 Pro | Bajo | Documentación, implementación de planes |

**Ejemplos:**
- Escribir una función simple → `gentleman-codex` (DeepSeek V4 Flash)
- Generar un README → `gentleman-docs` (MiMo V2.5 Pro)
- Analizar SEO de una página → `gentleman-seo` (Qwen3.7 Plus)
- Implementar un plan de 5 tareas → `gentleman-implementer` (MiMo V2.5 Pro)

### 10% de Tareas (Modelos Caros — Modo Sniper)

Usa estos modelos SOLO cuando sea crítico:

| Modelo | Costo | Uso |
|---|---|---|
| Qwen3.7 Max | Alto | Análisis de seguridad, optimización de performance |
| GLM-5.2 | Alto | Infraestructura crítica, Terraform, K8s |
| GLM-5.1 | Medio | Data science complejo, análisis estadístico |
| Kimi K2.6 | Medio | Frontend complejo, análisis de componentes grandes |

**Ejemplos:**
- Auditoría de seguridad completa → `gentleman-security` (Qwen3.7 Max)
- Optimización de query que tarda 10s → `gentleman-performance` (Qwen3.7 Max)
- Migración de Terraform a producción → `gentleman-infra` (GLM-5.2)
- Análisis de librería de componentes completa → `gentleman-frontend` (Kimi K2.6)

---

## Modo Sniper

### Cuándo Activar Modo Sniper

Cambia a modelos caros SOLO cuando:

1. **Seguridad**: Vulnerabilidad crítica detectada, auditoría de código sensible
2. **Performance**: Query que bloquea producción, bottleneck en API crítica
3. **Infraestructura**: Cambios en producción, migraciones de base de datos
4. **Arquitectura**: Decisiones que afectan todo el sistema
5. **Contexto Largo**: Necesitas analizar >100K tokens de una vez

### Cuándo NO Activar Modo Sniper

NO uses modelos caros para:

- Tareas rutinarias (escribir functions, tests, componentes)
- Ediciones rápidas (renombrar variables, agregar comentarios)
- Scripts simples (automatización básica)
- Documentación estándar (READMEs, comentarios)

---

## Contexto Largo (1M tokens)

### Cuándo Usar Modelos de Contexto Largo

Usa **Kimi K2.6** o **Qwen3.7 Plus** cuando:

- Analizar todo el repositorio para una migración
- Revisar una librería de componentes completa (Material UI, Shadcn)
- Auditoría SEO de un sitio completo
- Análisis de dependencias transitivas

### Por Qué No Usar Modelos Pequeños para Contexto Largo

Intentar analizar >100K tokens con modelos pequeños:
- ❌ Fallará por falta de memoria
- ❌ Perderá contexto importante
- ❌ Generará análisis incompleto
- ❌ Costará más (múltiples llamadas)

---

## Fallback Chains

### Qué Hacer Cuando un Modelo Falla

Si un agente especializado falla:

```
gentleman-security (Qwen3.7 Max) falla
  → Fallback a gentleman-deep (Nemotron)
  → Si falla, gentleman-vMK ejecuta directamente

gentleman-seo (Qwen3.7 Plus) falla
  → Fallback a gentleman-vMK (directo)

gentleman-infra (GLM-5.2) falla
  → Fallback a gentleman-deep (Nemotron)
  → Si falla, gentleman-vMK ejecuta directamente

gentleman-implementer (MiMo V2.5 Pro) falla
  → Fallback a gentleman-vMK (directo)
```

### Cuándo Usar Fallback

- Modelo trial desaparece (MiMo, MiniMax, Nemotron)
- Modelo caros agotado (quota excedida)
- Timeout o error de API
- Output de baja calidad (alucinaciones)

---

## Métricas de Costo

### Cómo Trackear Gasto

**Opción 1: Métricas automáticas (si OpenCode las provee)**
```bash
opencode stats
```

**Opción 2: Log manual**
Crea `docs/mejoras/cost-log.md`:
```markdown
## 2026-07-05
- Tarea: Auditoría de seguridad
- Agente: gentleman-security
- Modelo: Qwen3.7 Max
- Tiempo: 2 min
- Costo estimado: $0.50
- Resultado: OK

## 2026-07-06
- Tarea: Implementar plan de seguridad
- Agente: gentleman-implementer
- Modelo: MiMo V2.5 Pro
- Tiempo: 5 min
- Costo estimado: $0.10
- Resultado: OK
```

### Costos Estimados por Modelo

| Modelo | Costo por minuto | Costo por tarea típica |
|---|---|---|
| Qwen3.7 Max | ~$0.25/min | $0.50-1.00 (análisis complejo) |
| Qwen3.7 Plus | ~$0.10/min | $0.20-0.40 (análisis SEO) |
| GLM-5.2 | ~$0.20/min | $0.40-0.80 (análisis infra) |
| GLM-5.1 | ~$0.15/min | $0.30-0.60 (análisis data) |
| Kimi K2.6 | ~$0.12/min | $0.25-0.50 (análisis frontend) |
| MiMo V2.5 Pro | ~$0.05/min | $0.10-0.20 (implementación) |
| DeepSeek V4 Flash | ~$0.02/min | $0.05-0.10 (scripts) |
| MiMo V2.5 | ~$0.02/min | $0.05-0.10 (quick edits) |

### Alertas de Presupuesto

- **$5/mes**: Revisar uso, considerar más fallbacks a modelos baratos
- **$8/mes**: Modo Sniper estricto, solo tareas críticas con modelos caros
- **$10/mes**: STOP, solo modelos baratos hasta el próximo mes

---

## Ejemplos de Uso

### Ejemplo 1: Auditoría de Seguridad + Implementación

**Usuario**: "Audita la seguridad de mi API"

**Flujo**:
1. `gentleman-vMK` detecta tarea de seguridad → delega a `gentleman-security` (Qwen3.7 Max)
2. `gentleman-security` analiza (SOLO LEE) → guarda plan en `docs/agentes/security-api-audit/`
3. `gentleman-vMK` presenta resultados: "Encontré 3 vulnerabilidades. Plan guardado."
4. Usuario aprueba: "Sí, implementa el plan"
5. `gentleman-vMK` delega a `gentleman-implementer` (MiMo V2.5 Pro)
6. `gentleman-implementer` ejecuta el plan paso a paso
7. `gentleman-implementer` reporta: "Plan implementado. 3 vulnerabilidades corregidas."

**Costo estimado**:
- Análisis (Qwen3.7 Max): ~$0.50
- Implementación (MiMo V2.5 Pro): ~$0.15
- **Total**: ~$0.65

### Ejemplo 2: Optimización de Performance

**Usuario**: "Esta query tarda 10 segundos, optimízala"

**Flujo**:
1. `gentleman-vMK` detecta tarea de performance → delega a `gentleman-performance` (Qwen3.7 Max)
2. `gentleman-performance` analiza (SOLO LEE) → guarda plan en `docs/agentes/performance-query-optimization/`
3. `gentleman-vMK` presenta resultados: "Encontré 2 bottlenecks. Plan guardado."
4. Usuario aprueba: "Sí, implementa"
5. `gentleman-vMK` delega a `gentleman-implementer` (MiMo V2.5 Pro)
6. `gentleman-implementer` ejecuta el plan
7. `gentleman-implementer` reporta: "Query optimizada. Tiempo: 0.5s (mejora 95%)"

**Costo estimado**:
- Análisis (Qwen3.7 Max): ~$0.40
- Implementación (MiMo V2.5 Pro): ~$0.10
- **Total**: ~$0.50

### Ejemplo 3: Tarea Rutinaria (90% del trabajo)

**Usuario**: "Escribe una función para validar emails"

**Flujo**:
1. `gentleman-vMK` detecta tarea simple → ejecuta directamente con `gentleman-codex` (DeepSeek V4 Flash)
2. `gentleman-codex` escribe la función
3. `gentleman-vMK` presenta resultados

**Costo estimado**:
- Código (DeepSeek V4 Flash): ~$0.05
- **Total**: ~$0.05

---

## Ventajas del Sistema

1. **Separación de responsabilidades**: Analistas expertos vs implementador preciso
2. **Control humano**: Usuario aprueba planes antes de implementación
3. **Trazabilidad**: Todos los planes documentados en `docs/agentes/`
4. **Reutilización**: Otros agentes o desarrolladores pueden implementar planes
5. **Seguridad**: Analistas NO pueden modificar el proyecto accidentalmente
6. **Costo optimizado**: 90% tareas baratas, 10% tareas críticas caras

---

## Desventajas del Sistema

1. **Dos pasos**: Primero análisis, luego implementación (más lento)
2. **Más archivos**: Se generan muchos documentos en `docs/agentes/`
3. **Requiere aprobación**: No es 100% automático
4. **Costo de análisis**: Modelos caros para análisis (pero vale la pena para tareas críticas)

---

## Cuándo NO Usar Este Sistema

**NO uses agentes especializados para:**
- Tareas triviales (renombrar variable, agregar comentario)
- Cambios rápidos de una línea
- Cuando el usuario dice "solo hazlo, no me preguntes"
- Scripts simples de automatización

**En esos casos:**
- Usa `gentleman-codex` (DeepSeek V4 Flash) para scripts
- Usa `gentleman-quick` (MiMo V2.5) para ediciones rápidas
- Usa `gentleman-vMK` directamente para tareas simples

---

## Conclusión

Este sistema de multi-model routing optimiza costo y calidad:
- **90% de tareas**: Modelos baratos (DeepSeek V4 Flash, MiMo V2.5, Qwen3.7 Plus)
- **10% de tareas**: Modelos caros (Qwen3.7 Max, GLM-5.2) para análisis crítico
- **Implementación**: MiMo V2.5 Pro (mejor instruction follower, costo bajo)
- **Presupuesto**: $10/mes alcanzable con disciplina

**Éxito =** Análisis experto + implementación precisa + costo controlado + trazabilidad completa
