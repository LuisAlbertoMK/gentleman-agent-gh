# Análisis: Modos de Permisos Semi-Automático y Automático

**Fecha**: 2026-07-28
**Trigger**: Solicitud de usuario — crear modos semi/auto/manual con shortcuts
**Estado**: Análisis completo, pendiente de implementación en opencode.json

---

## Resumen Ejecutivo

Se analizaron 4 opciones arquitectónicas para implementar 3 modos de permisos:

| Modo | Comportamiento |
|------|---------------|
| `manual` | Todo comando pide permiso (`*: ask`) — comportamiento actual |
| `semi` | Comandos seguros (read-only, test) auto-ejecutan; destructivos/network piden permiso o se deniegan |
| `auto` | Todo auto-ejecuta excepto `git push`, `rm`, `Remove-Item`, y comandos de red/seguridad |

**Decisión**: Opción A — Perfiles de agente por modo + script de switching + skill de routing.

---

## Opciones Analizadas

### Opción A — Perfiles de Agente por Modo (RECOMENDADA ✅)

Crear agentes espejo con distintos permisos en `opencode.json`. Un archivo `.gentleman-mode` + script de switching + shortcuts `!auto/!semi/!manual`.

**Ventajas**:
- ✅ Enforcement real a nivel OpenCode runtime
- ✅ Subagents aislados correctamente
- ✅ Rollback trivial (cambiar el flag)
- ✅ Compatible con arquitectura existente

**Desventajas**:
- ❌ Duplica agents (~6-12 nuevos)
- ❌ opencode.json es write-protected — usuario debe aplicar cambios

### Opción B — opencode.json Mutante (DESCARTADA ❌)

Script que reescribe `opencode.json` en caliente.

**Riesgos**:
- Corrupción del archivo si el script falla
- opencode.json está auto-protegido contra escritura
- No recoverable sin intervención manual

### Opción C — Command-Gate Wrapper (DESCARTADA ❌)

Wrapper script intermediario para cada comando.

**Riesgos**:
- Sin enforcement real (subagent puede saltárselo)
- Overhead enorme por command-gate por cada tool call
- Rompe el flujo natural

### Opción D — Variable de Entorno + Prompt (DESCARTADA ❌)

`$env:GENTLEMAN_MODE` + instrucción en `_core-behavior-gp.md`.

**Riesgos**:
- Sin enforcement real — es instrucción, no permiso
- Subagents ignoran la variable si no se pasa explícitamente
- No escala

---

## Arquitectura Detallada (Opción A)

### Archivos

```
.gentleman-mode              ← Flag de modo (manual|semi|auto)
scripts/switch-mode.ps1      ← Script de switching
```

### opencode.json — Nuevos Agents (6 por modo)

Por cada agente ejecutable existente (quick, deep, codex, implementer), crear 2 variantes:

| Agente | Bash Permission |
|--------|----------------|
| `gentleman-*-semi` | Safe whitelist `allow`, resto `ask`, denials estándar |
| `gentleman-*-auto` | `*: allow` con push + destructivos en `ask`/`deny` |

### Routing

El orquestador (`gentleman-vMK`) lee `.gentleman-mode` y agrega sufijo al delegar:

```
🔀 → gentleman-quick-semi | modo semi, single-file known pattern
```

### Shortcuts

```
!auto   → .gentleman-mode = auto   (todo allow except push + deletes)
!semi   → .gentleman-mode = semi   (safe commands allow, rest ask)
!manual → .gentleman-mode = manual (current: everything asks)
```

---

## Implementación Testeable

### 1. `.gentleman-mode` — Archivo de Flag

```bash
manual    # default
```

### 2. `scripts/switch-mode.ps1` — Script de Switching

```powershell
# switch-mode.ps1 [-Mode manual|semi|auto] [-Status]
param(
    [ValidateSet('manual','semi','auto')][string]$Mode,
    [switch]$Status,
    [switch]$Help
)

$modeFile = Join-Path (Split-Path $PSScriptRoot -Parent) '.gentleman-mode'

if ($Help -or $PSBoundParameters.Count -eq 0) {
    $current = if (Test-Path $modeFile) { Get-Content $modeFile -Raw } else { 'manual' }
    Write-Host "╔══════════════════════════════════════╗"
    Write-Host "║      Gentleman Agent — Modo Actual   ║"
    Write-Host "╠══════════════════════════════════════╣"
    Write-Host "║  Modo: $($current.ToUpper().PadRight(25))║"
    Write-Host "╠══════════════════════════════════════╣"
    Write-Host "║  Uso: ./switch-mode.ps1 -Mode       ║"
    Write-Host "║       manual | semi | auto           ║"
    Write-Host "║                                      ║"
    Write-Host "║  manual: Todo pide permiso           ║"
    Write-Host "║  semi:   Comandos seguros auto       ║"
    Write-Host "║  auto:   Todo auto excepto push+del  ║"
    Write-Host "╚══════════════════════════════════════╝"
    return
}

if ($Status) {
    $current = if (Test-Path $modeFile) { Get-Content $modeFile -Raw } else { 'manual' }
    Write-Host "Current mode: $current"
    return
}

$current = if (Test-Path $modeFile) { Get-Content $modeFile -Raw } else { 'manual' }

if ($Mode -eq $current.Trim()) {
    Write-Host "ℹ️ Already in $Mode mode."
    return
}

$Mode | Set-Content $modeFile -NoNewline
Write-Host "✅ Switched to $Mode mode."
Write-Host ""
Write-Host "⚠️  Para que el cambio tenga efecto a nivel permisos OpenCode:"
Write-Host "   El orquestador debe recargar la skill de routing."
Write-Host "   En la próxima delegación usará agents con sufijo -$Mode."
```

### 3. Tests Realizados

Ver `tests/` y resultados en sección de resultados abajo.

---

## Resultados de Pruebas

### Test 1: Creación y lectura de `.gentleman-mode`

| Paso | Resultado |
|------|-----------|
| Crear archivo con contenido `manual` | ✅ |
| Leer archivo | ✅ Contenido correcto |
| Cambiar a `semi` | ✅ |
| Cambiar a `auto` | ✅ |
| Validar valores inválidos | ✅ `switch-mode.ps1` rechaza valores inválidos |

### Test 2: Script switch-mode.ps1

| Comando | Resultado |
|---------|-----------|
| `switch-mode.ps1` (sin args) | ✅ Muestra help + modo actual |
| `switch-mode.ps1 -Status` | ✅ Retorna modo actual |
| `switch-mode.ps1 -Mode semi` | ✅ Cambia a semi |
| `switch-mode.ps1 -Mode auto` | ✅ Cambia a auto |
| `switch-mode.ps1 -Mode manual` | ✅ Cambia a manual |
| `switch-mode.ps1 -Mode invalido` | ✅ Error por ValidateSet |

### Test 3: Comandos por Modo (Simulado)

Se simuló el comportamiento esperado basado en las reglas de permisos:

| Comando | manual | semi | auto |
|---------|--------|------|------|
| `git status` | ask | ✅ allow | ✅ allow |
| `git diff` | ask | ✅ allow | ✅ allow |
| `git log` | ask | ✅ allow | ✅ allow |
| `ls` / `Get-ChildItem` | ask | ✅ allow | ✅ allow |
| `pwd` / `Get-Location` | ask | ✅ allow | ✅ allow |
| `echo` / `Write-Output` | ask | ✅ allow | ✅ allow |
| `npm test` / `pytest` | ask | ✅ allow | ✅ allow |
| `grep` / `Select-String` | ask | ✅ allow | ✅ allow |
| `cat` / `Get-Content` | ask | ✅ allow | ✅ allow |
| `git commit` | ask | ask | ✅ allow |
| `git add` | ask | ask | ✅ allow |
| `New-Item` | ask | ask | ✅ allow |
| `mkdir` | ask | ask | ✅ allow |
| `git push` | ask | ask | ❌ ask (deny en --force) |
| `git push --force` | ask | ask | ❌ deny |
| `rm -rf` | ❌ deny | ❌ deny | ❌ deny |
| `Remove-Item` | ❌ deny | ❌ deny | ❌ deny |
| `curl` | ❌ deny | ❌ deny | ❌ deny |
| `ssh` | ❌ deny | ❌ deny | ❌ deny |
| `python` | ❌ deny | ❌ deny | ❌ deny |
| `reg add` | ❌ deny | ❌ deny | ❌ deny |

---

## Cambios Necesarios en Archivos Protegidos

Para activar el enforcement real, el usuario debe aplicar estos cambios manualmente:

### 1. `opencode.json` — Agregar 6 nuevos agents

Ver `docs/mejoras/2026-07-28-permission-modes-opencode.md` para el diff exacto.

### 2. `prompts/gentleman-vMK.md` — Agregar routing por modo

Agregar en la sección de routing:
```
## Mode-Aware Routing
1. Read `.gentleman-mode` → `manual` | `semi` | `auto`
2. Append suffix to delegation target:
   - manual → no suffix (current agents, `*: ask`)
   - semi → suffix `-semi`
   - auto → suffix `-auto`
3. Fallback: if `-semi`/`-auto` agent missing → fallback to base agent
```

### 3. `SHORTCUTS.md` — Agregar shortcuts

```markdown
## Permission Modes

| Shortcut | Action |
|----------|--------|
| `!auto` | Switch to AUTO — all commands auto-approved except push + deletes |
| `!semi` | Switch to SEMI-AUTO — safe commands auto-approved, rest ask |
| `!manual` | Switch to MANUAL — every command asks (default) |
| `!mode` | Show current permission mode |
```

---

## Decisión

**Opción A — Perfiles de agente por modo**, por las siguientes razones cuantificadas:

| Criterio | Peso | A (Perfiles) | B (Mutante) | C (Wrapper) | D (Prompt) |
|----------|------|-------------|-------------|-------------|------------|
| Enforcement real | 30% | 10/10 | 10/10 | 2/10 | 1/10 |
| Riesgo de impl | 20% | 8/10 | 2/10 | 5/10 | 9/10 |
| Mantenibilidad | 20% | 7/10 | 3/10 | 6/10 | 8/10 |
| Experiencia usuario | 15% | 9/10 | 7/10 | 4/10 | 8/10 |
| Escalabilidad | 15% | 8/10 | 4/10 | 3/10 | 2/10 |
| **Ponderado** | **100%** | **8.5/10** | **5.5/10** | **3.9/10** | **5.0/10** |

**Score final Opción A: 8.5/10** — Viabilidad alta, enforcement real, riesgo bajo.

---

## Próximos Pasos

1. ✅ Análisis completo (este documento)
2. ✅ `.gentleman-mode` creado
3. ✅ `scripts/switch-mode.ps1` creado y testeado
4. ⏳ Usuario aplica cambios en `opencode.json` (archivo protegido)
5. ⏳ Usuario aplica cambios en `prompts/gentleman-vMK.md` (archivo protegido)
6. ⏳ Usuario actualiza `SHORTCUTS.md` (archivo protegido)
7. ⏳ Test de integración con agents reales

---

*Documento generado como parte del análisis de modos de permisos*
