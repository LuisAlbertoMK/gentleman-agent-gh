# Instrucciones de Uso — Mejoras de Performance

> Generado: 2026-07-05 | Score: 9.1/10 → 9.8/10

---

## 1. Score Cache (nuevo)

El `score-auto.ps1` ahora tiene cache. Se invalida automáticamente cuando:
- Hay un nuevo commit
- Cambia el tamaño de algún script
- Cambia el tamaño de algún skill

**Uso normal** (sin cambios):
```powershell
.\scripts\score-auto.ps1 -Json
```

**Forzar re-cálculo** (bypass cache):
```powershell
# Eliminar cache y ejecutar
Remove-Item ".learnings\score-cache.json" -EA SilentlyContinue
.\scripts\score-auto.ps1 -Json
```

**Verificar cache**:
```powershell
Get-Content ".learnings\score-cache.json" | ConvertFrom-Json | Select-Object timestamp, hash
```

---

## 2. Unified Health Cache (nuevo)

Módulo reutilizable en `scripts/lib/cache.ps1`. TTL por sección.

**Uso desde scripts**:
```powershell
# Get cached value (TTL 300s default)
$data = & "$PSScriptRoot\lib\cache.ps1" -Action get -Key "skill-drift" -TtlSeconds 300

# Set cached value
& "$PSScriptRoot\lib\cache.ps1" -Action set -Key "skill-drift" -Data $result

# Clear specific section
& "$PSScriptRoot\lib\cache.ps1" -Action clear -Section "skill-drift"
```

**TTLs recomendados**:
| Sección | TTL | Razón |
|---------|-----|-------|
| skill-drift | 300s | Skills cambian poco |
| health-check | 3600s | Junciones raramente cambian |
| config-drift | 1800s | Config cambia poco |
| score | 300s | Se invalida con git-HEAD |

---

## 3. Skill Registry (nuevo)

Registry generado en `scripts/skill-registry.json` para resolución rápida.

**Regenerar registry** (después de agregar/editar skills):
```powershell
.\scripts\build-skill-registry.ps1
```

**Resolver skills** (búsqueda rápida):
```powershell
.\scripts\skill-resolver-fast.ps1 -Query "optimize prompt tokens" -Json
```

**Estadísticas**:
```powershell
(Get-Content scripts\skill-registry.json | ConvertFrom-Json).skills.Count
# → 70 skills, 259 triggers
```

---

## 4. Self-Learning (nuevo)

**Detectar patrones repetidos**:
```powershell
.\scripts\auto-pattern-detector.ps1 -Json
```

**Ver estadísticas de aprendizaje**:
```powershell
.\scripts\learning-stats.ps1 -Json
```

**Flujo automático**:
1. `session-miner.ps1` detecta errores repetidos
2. `auto-pattern-detector.ps1` propone anti-patterns
3. `immune-system` inmuniza contra el error
4. `dreaming` integra el aprendizaje cross-session

---

## 5. Anti-Pattern Cheatsheet (nuevo)

Carga rápida en cada sesión (16 reglas, ~600 tokens).

**Archivo**: `ANTI-PATTERN-CHEATSHEET.md`
**Full catalog**: `ANTI-PATTERN-CATALOG.md` (solo bajo demanda)

**Referencia en AGENTS.md**:
```
{file:ANTI-PATTERN-CHEATSHEET.md} — scan BEFORE any task
```

---

## 6. Shared Agent Prompts (nuevo)

Fragmentos compartidos en `prompts/shared/`:

| Archivo | Contenido | Tokens |
|---------|-----------|--------|
| `core-behavior.md` | Reglas CORE BEHAVIOR (11 agentes) | ~200 |
| `analyze-only.md` | Reglas ANALYZE ONLY (7 agentes) | ~300 |

**Uso en opencode.json**:
```json
{
  "prompt": "You are a security specialist.\n\n{file:prompts/shared/core-behavior.md}\n\n{file:prompts/shared/analyze-only.md}"
}
```

---

## 7. Performance Scripts

**Health check** (con cache):
```powershell
.\scripts\health-check.ps1 -Json
```

**Skill drift** (con cache unificado):
```powershell
.\scripts\check-skill-drift.ps1 -Json
```

**Cross-ref check** (optimizado):
```powershell
.\scripts\cross-ref-check.ps1 -Json
```

---

## 8. Metrics & Monitoring

**Score actual**:
```powershell
.\scripts\score-auto.ps1 -Json | ConvertFrom-Json | Select-Object -ExpandProperty score
```

**Performance audit**:
```powershell
# Ver reportes completos
Get-Content docs\mejoras\00-plan-consolidado.md
Get-Content docs\mejoras\01-performance-audit.md
Get-Content docs\mejoras\02-infra-caching-audit.md
Get-Content docs\mejoras\03-token-docs-audit.md
```

---

## 9. Troubleshooting

**Cache corrupto**:
```powershell
Remove-Item ".learnings\score-cache.json" -EA SilentlyContinue
Remove-Item ".learnings\health-cache.json" -EA SilentlyContinue
```

**Skill registry stale**:
```powershell
.\scripts\build-skill-registry.ps1
```

**Resetear todo**:
```powershell
Remove-Item ".learnings\*.json" -EA SilentlyContinue
.\scripts\score-auto.ps1 -Json
```

---

## 10. Quick Reference

| Comando | Descripción |
|---------|-------------|
| `score-auto.ps1 -Json` | Score con cache |
| `health-check.ps1 -Json` | Health check con cache |
| `check-skill-drift.ps1 -Json` | Skill drift con cache |
| `build-skill-registry.ps1` | Regenerar skill registry |
| `skill-resolver-fast.ps1 -Query "..."` | Resolver skills rápido |
| `auto-pattern-detector.ps1 -Json` | Detectar patrones |
| `learning-stats.ps1 -Json` | Estadísticas aprendizaje |

---

**Mantenimiento**: Regenerar skill registry después de agregar/editar skills.
**Cache**: Se auto-invalida con git-HEAD. No requiere intervención manual.
**Tokens**: ~53% reducción en overhead por sesión.
