# Roadmap: Items Pendientes (Post-Prioridad)

> **Contexto**: Tras la tanda de prioridad (scripts try/catch, model pins, SKILLS-INDEX,
> skill-graph restore, bash path auto-detect), quedan 3 items de esfuerzo mayor.
> Fecha: 2026-06-23

---

## 1. Instalador CLI multiplataforma

**Problema**: Hoy el instalador requiere `git clone` + script manual por OS
(`install.ps1` en Windows, `install.sh` en Unix). No hay CLI tipo `gentle-ai`, `brew`, `scoop`, o `npm`.

**Objetivo**: `curl https://gentleman.sh | bash` o equivalente con 0 friction.

| Opción | Esfuerzo | Impacto | Mantenimiento |
|--------|----------|---------|---------------|
| A: Homebrew formula | Medio (crear tap) | Alto (Mac users) | Bajo (auto-update) |
| B: Scoop manifest | Bajo (1 manifest) | Medio (Win users) | Bajo |
| C: npm package | Medio (wrapper JS) | Alto (JS ecosystem) | Medio |
| D: Script `bootstrap.sh` auto-contenido | Bajo | Alto (universal) | Bajo |

**Recomendación**: D (bootstrap.sh) como entry point + A/B como distribución.
Un solo script que detecte OS, clone el repo, corra install.sh/install.ps1, y configure junctions/symlinks.

### Archivos a crear/modificar
- `scripts/bootstrap.sh` — entry point universal
- `scripts/bootstrap.ps1` — entry point Windows
- `scripts/install.sh` — mejorar (add brew/scoop detection)
- `scripts/install.ps1` — mejorar (add scoop detection)

### Ruta de implementación
1. Crear `bootstrap.sh` que detecte OS → clone → instale
2. Agregar detección de brew/scoop en scripts de install
3. Doc: `one-liner` en README para cada plataforma

---

## 2. Backup/Rollback de Configuración

**Problema**: No hay mecanismo de backup para `~/.config/opencode/`. Cambios en
skills/config pueden romper el entorno sin forma de volver atrás.

**Objetivo**: `gentleman backup` / `gentleman restore` que snapshot y restaure configuración.

| Opción | Esfuerzo | Confiabilidad |
|--------|----------|---------------|
| A: Git snapshot del directorio | Bajo | Alta (git) |
| B: Tarball/zip + timestamp | Bajo | Media |
| C: Engram-based versioning | Alto (nuevo feature) | Alta |

**Recomendación**: A (git init en `~/.config/opencode/` + auto-commit diario).
B como fallback si git no está disponible.

### Archivos a crear/modificar
- `scripts/gentleman.sh` — CLI entry point (subcommands backup/restore)
- `scripts/backup.ps1` — backup para Windows
- `scripts/restore.ps1` — restore para Windows
- Config auto-backup via scheduled task/cron

### Ruta de implementación
1. Crear `scripts/backup.ps1` y `scripts/restore.ps1`
2. Crear `scripts/gentleman.sh` wrapper
3. Doc en README sobre backup automático

---

## 3. AGENTS.md Portabilidad (bash/zsh)

**Problema**: AGENTS.md tiene ~58 referencias PowerShell (`$env:`, `.ps1`, `Invoke-Bash`,
`; if ($?)`). Solo funciona con PowerShell 5.1 en Windows. Score actual: 3/10.

**Objetivo**: AGENTS.md funcional en bash/zsh + pwsh (Linux/Mac/Windows). Score target: 8/10.

### Estrategia por capas

| Capa | Qué | Estrategia | Prioridad |
|------|-----|------------|-----------|
| **Scripts core** | Todos los `.ps1` del repo | Crear wrappers `.sh` equivalentes para los 4 scripts más usados | **Fase 1** |
| **Invocaciones** | `$env:` y backslash paths | Normalizar a `$GENTLEMAN_ROOT` (sin `$env:`) + `Join-Path` | **Fase 1** |
| **Junctions/symlinks** | `check-skill-drift.ps1` | Detectar SO y usar Junction (Win) o SymbolicLink (Unix) | **Fase 2** |
| **Health-check** | Scripts de inicio de sesión | Puerto a bash, alternativas a `restore-project-score.ps1` | **Fase 3** |

### Archivos a crear/modificar
- Phase 1 (urgente):
  - `scripts/check-skill-drift.sh` — reemplazo bash de `check-skill-drift.ps1`
  - `scripts/health-check.sh` — health check para Unix
  - AGENTS.md — normalizar referencias a `$GENTLEMAN_ROOT` (variable de entorno agnóstica)
- Phase 2 (siguiente):
  - `check-skill-drift.ps1` — agregar detección de SO para symlink vs junction
- Phase 3 (futuro):
  - Portar scripts restantes según uso

### Ruta de implementación
**FASE 1** (rápida, ~1 sesión):
1. Crear `check-skill-drift.sh` (equivalente bash)
2. Crear `health-check.sh`
3. Normalizar AGENTS.md: `$GENTLEMAN_ROOT` reemplaza `$env:GENTLEMAN_AGENT_ROOT`

**FASE 2-3** (progresivo):
4. Portar scripts según demanda del usuario

---

## Priorización recomendada

| Item | Esfuerzo | Impacto | Depende de | Hacer |
|------|----------|---------|------------|-------|
| Bootstrap.sh | 2h | Alto (instalación) | Nada | **Ahora** |
| Backup básico | 3h | Medio (seguridad) | Nada | **Próximo** |
| Portabilidad Fase 1 | 4h | Alto (multi-OS) | Nada | **Próximo** |
| Portabilidad Fase 2-3 | 8h+ | Medio | Fase 1 | **Futuro** |
| CLI completo (brew/scoop) | 6h+ | Alto (distribución) | bootstrap.sh | **Futuro** |

**Total estimado**: ~15-20h para completar las 3 áreas.
