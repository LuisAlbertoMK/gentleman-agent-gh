# Plan de Mejora Integral — Gentleman Agent

> Basado en investigación: Gentleman Programming ecosystem (Alan Buscaglia), Pawel Dudev "Get things done", OpenCode SDD best practices, Dynamic Context Pruning.
> Score actual: **9.1** — Target: **9.8**

---

## 📋 Diagnóstico Actual

| Dimensión | Score | Estado |
|-----------|-------|--------|
| Project Artifacts | 10.0 | ✅ |
| Bitacora | 10.0 | ✅ |
| Orthography | 10.0 | ✅ |
| Metrics | 10.0 | ✅ |
| Best Practices | 10.0 | ✅ |
| Dead Code | 10.0 | ✅ |
| Clean Code | 10.0 | ✅ |
| Security | 10.0 | ✅ |
| Backlog Integrity | 10.0 | ✅ |
| Script Performance | 10.0 | ✅ |
| Score Depth | 8.9 | ⚠️ 35 sub-dims, room for growth |
| Skill Effectiveness | 8.0 | ⚠️ 15 skills >3KB, 2 >5KB |
| **Cycle Activity** | **1.0** | 🔴 **Solo 3/30 intercycles — PRIORIDAD #1** |

---

## 🔥 Fase 0: Quick Wins (inmediato)

### 0.1 Fix scroll horizontal en after demo
- ✅ `html/body { overflow-x: hidden; width: 100%; }`
- ✅ Media query movida al final del stylesheet (cascade bug)
- ✅ Theme switch en grid `1fr 1fr` en mobile

### 0.2 Karpathy compression de skills grandes
- 15 skills >3KB → comprimir a ≤2.5KB
- Prioridad: las 2 >5KB primero

---

## 🎯 Fase 1: Ciclo de Actividad — CA 1.0 → 8.0+

**27 intercycles faltantes** para llegar a 30/30.

### 1.1 Batch de ciclos (macro)
- Ejecutar `!cycle` 5-10 veces por sesión
- Cada ciclo: diagnosticar → 3 subagentes → verificar → aprender → `docs/ciclos/`

### 1.2 Micro-mejoras diarias
- Post-cada-tarea: capturar learning en Engram
- 1 mejora concreta por ciclo

---

## 🧠 Fase 2: Skill Optimization — SE 8.0 → 9.5

### 2.1 Compresión Karpathy (urgente)
| Skill | Size | Target |
|-------|------|--------|
| baseline-ui | 3.9KB | ≤2.5KB |
| accessibility | 3.3KB | ≤2.5KB |
| delivery-harness | ~4KB | ≤2.5KB |
| +12 más >3KB | | ≤2.5KB |

### 2.2 Merge skills overlapping
- `css-layout` + `responsive-design` + `ui-animation` + `design-tokens` → 1 skill unificada "ui-engine"
- `performance` + `performance-tracker` → merge
- `web-quality-audit` + `accessibility` + `seo` → merge parcial

### 2.3 Auto-ejecución de `!score` post-compresión
- Cada batch de compresión → `!score` para verificar impacto

---

## 🔧 Fase 3: Infraestructura de Scripts

### 3.1 Dynamic Context Pruning (DCP)
- Investigar plugin `opencode-dcp-plugin`
- Configurar `max_tokens: 8000, strategy: smart`
- Reducción estimada: 50-70% tokens

### 3.2 SDD Multi-Model Profiles
- Crear perfil "fast" (modelos rápidos para explore/tasks)
- Crear perfil "premium" (modelos fuertes para design/verify)
- Integrar con `gentle-ai sync --profile`

### 3.3 Limpieza de scripts legacy
- `docs/_archive/` → revisar qué se puede eliminar
- Scripts duplicados o muertos → purge

---

## 📐 Fase 4: Arquitectura del Agente

### 4.1 Delegación Subagent-First (lección de gentle-ai)
- **Regla 4 archivos**: si requiere leer 4+ archivos → delegar a subagent explore
- **Regla 20 tool calls**: pausar y re-planificar al llegar a 20 calls
- **Regla 2+ archivos**: un solo writer por cambio no-trivial
- **Regla post-incidente**: fresh audit antes de continuar

### 4.2 Engram uso proactivo
- Save automático post-decision/bugfix (ya implementado en §M)
- Mini-dream cada 5 interacciones
- Capturar correcciones del usuario inmediatamente

### 4.3 Persona refinement
- Menos ceremony para tareas SIMPLE
- Más autonomía en zonas GREEN
- Aplicar lección de Pawel Dudev: "Get things done instead of making your code perfect"

---

## 🌐 Fase 5: Integración con Gentle-ai Ecosystem

### 5.1 Evaluar gentle-ai re-install
- Revisar si `gentle-ai install --preset full-gentleman` aporta algo nuevo
- Comparar skills actuales vs las del registry community

### 5.2 gentleman-book-mcp
- Usar MCP server para acceder a 18 capítulos de arquitectura
- Aplicar patrones del libro directamente

### 5.3 Community skills
- Explorar `Gentleman-Skills` (570 stars)
- Identificar skills que podemos adoptar o adaptar

---

## 📊 Fase 6: Score Depth — SD 8.9 → 9.8

### 6.1 Nuevas sub-dimensiones
- Engram usage rate
- Subagent delegation ratio
- Context compression efficiency
- Skill freshness (last update per skill)

### 6.2 Auto-reporting semanal
- `!score` automático cada 7 días
- Reporte de tendencias vs baseline

---

## 📁 Archivos Afectados

| Archivo | Cambio |
|---------|--------|
| `.project.json` | Score updates |
| `docs/ciclos/` | +27 nuevos ciclos |
| `.agents/skills/*/SKILL.md` | Compresión Karpathy |
| `docs/mejoras/skills/demo-after/index.html` | CSS cascade fix |
| `~/.config/opencode/opencode.json` | DCP config, SDD profiles |
| `scripts/` | Posible limpieza |

---

## ⚡ Prioridades

```
P0: Cycle Activity (CA 1.0→5.0) — empezar AHORA
P1: Compresión Karpathy (SE 8.0→9.0)
P2: DCP + SDD profiles
P3: Subagent-First enforcement
P4: Gentle-ai ecosystem integration
P5: Score Depth expansion
```

---

## 📚 Referencias

- [Gentle-ai Intended Usage](https://github.com/Gentleman-Programming/gentle-ai/blob/main/docs/intended-usage.md)
- [Pawel Dudev — Get things done](https://medium.com/@paweldudev/get-things-done-instead-of-making-your-code-perfect-73cb21ca1406)
- [OpenCode SDD Guide](https://adurrr.github.io/en/p/opencode-agent-orchestration-and-subagent-driven-development-a-complete-guide/)
- [Dynamic Context Pruning](https://earezki.com/ai-news/2026-04-30-how-to-reduce-token-usage-in-opencode-with-dynamic-context-pruning-dcp/)
- [Gentleman Programming GitHub](https://github.com/Gentleman-Programming)
- [Alan Buscaglia](https://github.com/alan-thegentleman)
