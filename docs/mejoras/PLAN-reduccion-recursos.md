# Plan de Reducción de Recursos — gentleman-agent-gh

> Fecha: 2026-07-08
> Objetivo: Reducir CPU/RAM/VRAM del agente OpenCode en ~2.5-3 GB

## Diagnóstico base

**Consumo actual**: ~4.5 GB RAM · ~21 procesos · 0 VRAM (inferencia remota)

| Componente | Procesos | RAM |
|---|---|---|
| opencode (×2 instancias) | 2 | ~2,056 MB |
| codebase-memory-mcp workers (node pool) | ~15 | ~1,500 MB |
| engram | 1 | ~20 MB |
| headroom | 1 | ~4 MB |
| context7 (npx) | ~2 | ~150 MB |
| **TOTAL** | **~21** | **~4,546 MB** |

## 🔴 HIGH — Matafuegos inmediatos

### 1. Matar procesos huérfanos
- 2 instancias de opencode abiertas (~2 GB)
- Cerrar la más vieja si está en desuso
- **Ahorro**: -1 GB

### 2. Bajar workers de codebase-memory-mcp
- numWorkers actual: detectado automático (16 workers en esta máquina)
- Bajar a 4 workers + limitar heap a 256 MB por worker
- **Ahorro**: -1.0 a -1.8 GB
- **Archivo**: config de codebase-memory-mcp (no encontrada aún — puede ser flag en opencode.json)

### 3. Instalar context7 global y sacar npx
- `npm i -g @upstash/context7-mcp@3.2.2`
- Cambiar MCP command de `npx -y @upstash/context7-mcp@3.2.2` a `context7-mcp`
- **Ahorro**: -150 MB + startup más rápido

## 🟡 MEDIUM — Skills y config

### 4. Comprimir opencode-skill-creator
- 76.5 KB → ~15 KB (Karpathy L1)
- Separar eval data a archivos externos
- **Ahorro**: -61 KB de contexto por sesión

### 5. Mergear Web Quality stack
- 5 skills (accessibility, best-practices, performance, performance-tracker, seo) → web-quality-audit
- **Ahorro**: -20 KB de contexto

### 6. Ajustes opencode.json
- compaction.reserved: 20000 → 12000
- MCP engram: agregar timeout 30000
- **Ahorro**: -200 a -400 MB

### 7. Restricciones git/gh en agents
- 7 agents con `bash:allow` sin heredar restricciones globales
- Agregar `git commit *: ask`, `git push *: ask`, etc.

## 🟢 LOW — Mantenimiento

### 8. VACUUM context-mode DBs
- Session DB más grande: 2.37 MB

### 9. Eliminar scripts/skills zombie
- external-auditor, performance, performance-tracker, seo, best-practices
- ps5-detect.ps1, auto-clean.ps1, token-count.ps1, etc.

## Correcciones del análisis

- **codebase-memory-mcp**: El análisis preliminar reportó ~15 workers × 200 MB. La realidad es 2 procesos node × 47 MB (~94 MB total). FALSO POSITIVO. No requiere optimización.
- **Restricciones git/gh**: Agents con `"bash": "allow"` (string) heredan las reglas globales. No son un hueco de seguridad real. FALSO POSITIVO. No requiere acción.

## Resumen de impacto

| Categoría | Antes | Después | Ahorro |
|---|---|---|---|
| RAM | ~4,546 MB | ~4,150 MB | **~-400 MB** |
| Procesos | ~21 | ~18 | **-3 procesos** |
| VRAM | 0 | 0 | Sin cambio |
| Contexto skills | 76.5 KB (dir completo) | 56.6 KB (compressed) | **-19.9 KB (63% en SKILL.md)** |
| Startup time | npx ~3s por instancia | direct binary | **-2-3s** |

## Estado de implementación

- [x] 1. Matar procesos huérfanos (sequential-thinking zombie + cached context7 npx) — ✅ -200 MB
- [x] 2. Instalar context7 global + sacar npx — ✅ -150 MB, -2-3s startup
- [x] 3. Comprimir opencode-skill-creator (481 → 222 líneas, 31.7 → 11.8 KB) — ✅ -63% SKILL.md
- [x] 4. Ajustes opencode.json: compaction 20000→12000, engram timeout 30s, context7 binary — ✅
- [x] 5. global-setup.ps1: detectar cambios reales en MCP context7 — ✅ previene regresiones
- [x] 6. Eliminar scripts zombie: ps5-detect.ps1, auto-clean.ps1 — ✅ -2.9 KB
- [ ] 7. Mergear Web Quality stack (5 skills → 1) — ❌ **SKIP**: skills 2KB c/u con triggers específicos. web-quality-audit ya existe como skill combinada. Pérdida de precisión > beneficio.
- [ ] 8. VACUUM context-mode DBs — ❌ **SKIP**: DBs de sesión activa bloqueados. VACUUM infló DBs chicos (4→96KB). ~3 MB total, impacto despreciable.

## Lecciones aprendidas

1. **No confiar en análisis de subagentes sin verificar**: codebase-memory-mcp NO tenía 15 workers × 200 MB (2 × 47 MB real). Agents con `bash: allow` heredan reglas globales (no bypass). **Siempre verificar antes de actuar**.
2. **DBs SQLite activas no se vacunan**: VACUUM requiere lock exclusivo. Cambiar journal_mode (WAL→DELETE) puede inflar DBs chicos.
3. **Skills de plugin no se comprimen agresivamente**: opencode-skill-creator tiene `.opencode-skill-creator-version` → el plugin puede sobrescribir cambios. Compresión moderada de SKILL.md está bien, pero no tocar agentes/referencias.
