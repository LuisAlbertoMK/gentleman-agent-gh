# Análisis gentleman-agent-gh — 2026-07-13 (CORREGIDO)

## Executive Summary

Análisis verificado del proyecto gentleman-agent-gh (82 skills, 69 scripts). Se encontraron **5 hallazgos confirmados** y **3 hallazgos incorrectos/exagerados** del análisis inicial.

| Dimensión | Estado | Score |
|-----------|--------|-------|
| Auto-Aprendizaje | 🔴 CRÍTICO | 2/10 |
| Performance | 🟠 PROBLEMÁTICO | 4/10 |
| UI/UX Skills | 🟡 MEJORABLE | 6/10 |
| Cross-File | 🟢 BUENO | 7/10 |
| Seguridad | 🟢 BUENO | 7/10 |

---

## ✅ HALLAZGOS VERIFICADOS

### 🔴 CRÍTICO — Auto-Aprendizaje

| # | Hallazgo | Verificación | Impacto |
|---|----------|--------------|---------|
| **C1** | `.learnings/` data files missing | ✅ CONFIRMADO — Solo existe bias-calibration.json | Pipeline completo es no-op |
| **C2** | session-miner.ps1 NO wired a close-session.ps1 | ✅ CONFIRMADO — Zero referencias en el archivo | Mining nunca se ejecuta |

### 🟠 PROBLEMÁTICO — Performance

| # | Hallazgo | Verificación | Impacto |
|---|----------|--------------|---------|
| **P1** | skill-graph.ps1 reconstruye graph en cada llamada | ✅ CONFIRMADO — 2 llamadas New-Graph, zero caching | +150-300ms cold start |
| **P2** | score-auto.ps1 lee archivos múltiples veces | ✅ CONFIRMADO — 3 file reads redundantes | ~1MB I/O redundante |
| **P3** | score-auto.ps1 usa Start-Job | ✅ CONFIRMADO — 3 llamadas Start-Job | +2-5s overhead por job |

---

## ❌ HALLAZGOS INCORRECTOS/EXAGERADOS

| # | Hallazgo Original | Corrección | Lección |
|---|-------------------|------------|---------|
| **D2** | lib/JsonFast.psm1 es orphan | ❌ INCORRECTO — Referenciado en smoke-all.ps1, smoke-jsonfast.ps1, docs | Verificar referencias en TODOS los archivos antes de declarar orphan |
| **D3** | 3 scripts orphaned (token-count, intake-debug, tokenize-all) | ❌ INCORRECTO — Todos referenciados en algún lado | Buscar en .md, .json, no solo .ps1 |
| **P4** | score-dims.ps1 tiene condición unreachable | ❌ INCORRECTO — No existe esa condición | Verificar código real antes de reportar |
| **D1** | run.ps1 tiene riesgo de infinite recursion | ⚠️ EXAGERADO — No hay self-references actuales | Riesgo teórico, no actual |
| **P2-EX** | score-auto.ps1 lee scripts 4 veces | ⚠️ EXAGERADO — Son 3 reads, no 4 | Contar exactamente, no estimar |

---

## 📋 PRIORIDADES CORREGIDAS

### P0 — Inmediato (hoy)
1. **Bootstrap .learnings/** — Crear LEARNINGS.md + ERRORS.md (15 min)
2. **Wire session-miner** — Agregar a close-session.ps1 (10 min)

### P1 — Esta semana
3. **Cache skill-graph.ps1** — Evitar reconstruir graph (30 min)
4. **Consolidate score-auto.ps1 reads** — Reducir I/O (45 min)
5. **Replace Start-Job con ForEach-Object -Parallel** — Eliminar process spawn (30 min)

### P2 — Próximo ciclo
6. **Add capture enforcement** — Verificar compliance (30 min)
7. **Document global-setup.ps1 manifest** — Evitar olvidos (10 min)

### P3 — Backlog
8. **Improve skill docs** — Agregar failure modes (1h)
9. **Fix regex false negatives** — check-mcp-security.ps1 (15 min)

---

## 🚫 LECCIONES PARA FUTUROS ANÁLISIS

### Errores de Verificación Cometidos

1. **Declarar archivos como "orphan" sin buscar en .md/.json** — Los scripts pueden ser referenciados en documentación, no solo en código
2. **Reportar condiciones de código sin verificar** — La condición unreachable no existía
3. **Exagerar números (4 reads → 3 reads)** — Contar exactamente, no estimar
4. **Confundir riesgo teórico con actual** — run.ps1 no tiene self-references

### Protocolo Mejorado para Próximos Análisis

```
1. Buscar referencias en TODOS los tipos de archivo (.ps1, .psm1, .md, .json, .jsonc)
2. Verificar código real ANTES de reportar bugs
3. Contar instancias exactas, no estimar
4. Distinguir "riesgo teórico" de "riesgo actual"
5. Confirmar con el usuario antes de presentar como hecho
```

---

## Estado del Proyecto

| Componente | Estado | Notas |
|------------|--------|-------|
| Scripts | 69 | 8 comprimidos, 8 nuevos |
| Skills | 69 | 25 nuevos (~~skills-link~~ eliminado 2026-07-16) |
| Config | opencode.json | Permisos fix aplicado |
| .learnings/ | ⚠️ VACÍO | Necesita bootstrap |
| Learning pipeline | 🔴 MUERTO | Sin datos = sin aprendizaje |
| Performance | 🟠 LENTO | skill-graph + score-auto |

---

*Análisis generado: 2026-07-13*
*Verificado: Sí (con correcciones)*
*Próxima revisión: Cuando se implementen P0 y P1*
