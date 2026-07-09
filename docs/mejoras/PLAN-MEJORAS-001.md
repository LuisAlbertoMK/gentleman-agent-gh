# Plan de Mejoras — Análisis Inicial (v1.1)

**Fecha**: 2026-07-08
**Última actualización**: 2026-07-08 (fase 1 completa + test caching)
**Contexto**: `!analisis` — 3 problemas identificados por el usuario.

---

## Resumen Ejecutivo

| # | Problema | Impacto | Prioridad | Estado |
|---|----------|---------|-----------|--------|
| 1 | Pipeline sync-all incompatible con PS5/CMD | ALTO | 🔴 Alta | ✅ Implementado |
| 2 | Tests lentos y secuenciales | MEDIO | 🟡 Media | ✅ Implementado |
| 3 | Servidores (ng serve, etc.) bloquean al agente | ALTO | 🔴 Alta | ✅ Implementado |

---

## Problema 3: Servidores bloquean al agente ✅ IMPLEMENTADO

### Diagnóstico

- El agente ejecuta comandos vía `bash` tool que espera a que **termine** el proceso
- Comandos como `ng serve`, `npm run dev`, `dotnet run`, `python -m http.server` **nunca terminan**
- El agente queda esperando hasta el timeout (2min default)
- `bash-safe.ps1` no tenía detección de server patterns ni modo background
- `dev-server.ps1` YA existía pero el agente **no sabía usarlo automáticamente**

### Qué se implementó

**Archivos modificados:**

- `scripts/bash-safe.ps1`:
  - `$script:ServerPatterns` — catálogo de 14 patrones de comandos servidor
  - `Test-IsServerCommand` — función que detecta si un comando es servidor
  - `Invoke-Bash -Background` — nuevo switch para lanzar procesos sin esperar
  - Detección automática: si un comando es servidor y no se usa `-Background`, emite WARNING
  - `Test-ServerDetection` — 8 tests de validación (8/8 PASS)
  - Integrado en self-test al ejecutar el script directamente

- `AGENTS.md`:
  - Nueva sección **Server Commands — LONG-LIVED PROCESSES** que documenta:
    - Cómo iniciar servidores con `dev-server.ps1`
    - Cómo verificar estado, leer logs, matar procesos
    - Cómo detectar si un comando es servidor (`Test-IsServerCommand`)
    - Cómo detectar puertos en uso (`Get-NetTCPConnection`)

### Uso

```powershell
# Lanzar servidor sin bloquear
Invoke-Bash "ng serve" -Background

# O mejor: usar dev-server.ps1
.\scripts\dev-server.ps1 -Action Start -Name frontend -Command ng -Arguments "serve"

# Verificar estado
.\scripts\dev-server.ps1 -Action Status -Name frontend

# Matar
.\scripts\dev-server.ps1 -Action Kill -Name frontend

# Probar detección
Test-IsServerCommand "npm run dev"   # → $true
Test-IsServerCommand "git status"    # → $false
```

### Tests

```powershell
. .\scripts\bash-safe.ps1
Test-ServerDetection
# Output: 8/8 PASS
```

---

## Problema 1: sync-all incompatible con PS5/CMD ✅ IMPLEMENTADO

### Diagnóstico

- **Todos** los scripts en `scripts/` (70+) tienen `#requires -Version 7.6`
- **PS5**: Falla con error críptico
- **CMD**: No ejecuta `.ps1` directamente
- Features PS7: `ConvertFrom-Json -AsHashtable`, `Register-ObjectEvent`, `ForEach-Object -Parallel`, etc.

### Qué se implementó

- `scripts/sync-all.bat`:
  - Busca `pwsh.exe` en PATH
  - Si no está, muestra instrucciones de instalación
  - Invoca `sync-all.ps1` con todos los argumentos

- `scripts/sync-all.ps1`:
  - Reemplazó `#requires -Version 7.6` por version check flexible
  - `PS < 7.0`: intenta auto-redirigir a `pwsh.exe`
  - `PS 7.0 - 7.5`: advierte pero permite continuar
  - `PS 7.6+`: funciona normal
  - Mensajes de error claros con instrucciones

### Uso

```bat
REM Desde CMD:
scripts\sync-all.bat
scripts\sync-all.bat -Json
```

```powershell
# Desde PS5 (auto-redirige a pwsh si está disponible):
.\scripts\sync-all.ps1
```

---

## Problema 2: Tests lentos ✅ IMPLEMENTADO

### Diagnóstico

- **11 smoke tests** ejecutados secuencialmente
- Sin paralelización, sin caching, sin warm-up
- Cada test espera al anterior para empezar

### Qué se implementó

- `scripts/smoke/smoke-all.ps1`:
  - Reemplazó `foreach` secuencial por `ForEach-Object -Parallel -ThrottleLimit 4`
  - Resultados se recolectan en paralelo y se serializan después
  - Ahorro estimado: ~60-70% en tiempo de ejecución

### Código clave

```powershell
# Antes: secuencial — 11 tests uno atrás del otro
foreach ($s in $smokeScripts) {
    & $path *>&1 | Out-Null
}

# Después: paralelo — hasta 4 simultáneos
$parallelResults = $smokeScripts | ForEach-Object -Parallel -ThrottleLimit 4 {
    $path = Join-Path $using:smokeDir $_.file
    $null = & $path *>&1
    @{ name = $_.name; passed = ($LASTEXITCODE -eq 0); detail = "exit $LASTEXITCODE" }
}
```

### Pendiente para futuro

- Test caching por git hash (skip si no hay cambios)
- Pester 5 con `Invoke-Pester -Parallel`
- Delegación a subagentes para suites independientes

---

## Resumen de Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `scripts/bash-safe.ps1` | +Server patterns, +`-Background`, +`Test-IsServerCommand`, +test |
| `scripts/sync-all.bat` | **NUEVO** — wrapper CMD para sync-all |
| `scripts/sync-all.ps1` | Version check graceful en lugar de `#requires` |
| `scripts/smoke/smoke-all.ps1` | Loop secuencial → `ForEach-Object -Parallel` + **test caching por hash** |
| `AGENTS.md` | Nueva sección Server Commands |
| `docs/mejoras/PLAN-MEJORAS-001.md` | Este archivo |

---

## Mejora Extra: Test Caching (post-implementación)

Se agregó a `smoke-all.ps1` un sistema de caché que:
1. Calcula un **hash combinado** = `git HEAD` + contenido de todos los smoke scripts
2. Si el hash no cambió, **salta la ejecución** y usa resultados cacheados
3. Cache se guarda en `$env:TEMP\gentleman-smoke-cache.json` (no ensucia el repo)
4. Flag `-Force` para bypass forzado

```powershell
# Caché activo (no cambió nada)
scripts\smoke\smoke-all.ps1       # → "[cache] No changes detected"

# Forzar ejecución aunque haya caché
scripts\smoke\smoke-all.ps1 -Force  # → ejecuta todo
```

Ahorro estimado: ~80-90% en runs repetidos sin cambios.

---

## Próximos Pasos

1. 🔄 **Medio plazo**: Pester 5 upgrade + `Invoke-Pester -Parallel`
2. 🔄 **Medio plazo**: Delegar test suites a subagentes en pipeline de commit
3. 🔄 **Largo plazo**: Auto-detectar servidores existentes en puertos comunes al iniciar

---

## Seguimiento

- **Propietario**: Señor Arquitecto
- **Próxima revisión**: 2026-07-22
- **Actualizar este archivo** en cada interacción/corrección que afecte estos temas
