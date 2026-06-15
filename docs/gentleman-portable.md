# Gentleman-vMK Portable — Corrección de Herencia

> **Fecha**: 2026-06-15
> **Problema**: El project `AGENTS.md` heredaba de un path absoluto (`C:\Users\MK\.config\opencode\AGENTS.md`), haciendo que el agente `gentleman-vMK` dependiera de un usuario específico. En cualquier otra máquina o con otro usuario, el agente perdía su personalidad, reglas y protocolos.

---

## Síntomas

- `AGENTS.md` del proyecto tenía solo 23 líneas con una sección `## Inheritance` apuntando a `C:\Users\MK\.config\opencode\AGENTS.md`
- Skills y paths hardcodeados a `C:\Users\MK\...` en múltiples archivos
- El agente `gentleman` en `opencode.json` global tenía `"tools": {"edit": true, "write": true}` — restringía TODOS los demás tools
- Al clonar el repo en otra máquina o con otro usuario, el agente no tenía instrucciones

## Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `AGENTS.md` (raíz del proyecto) | Se copió TODO el contenido inline (Rules, Personality, Pre-Flight, Engram protocol, Agent protocol) — ahora es self-contained (338 líneas) |
| `.gitignore` | `C:\Users\MK\.config\opencode\` → `$env:USERPROFILE\.config\opencode\` |
| `~/.config/opencode/AGENTS.md` | Paths hardcodeados `C:\Users\LuisOrozco\...` → portables: `{file:ANTI-PATTERN-CATALOG.md}` (relativo), `$env:TEMP\opencode\` |
| `~/.config/opencode/opencode.json` | Se agregó `gentleman-vMK` como primary agent con `{file:AGENTS.md}`, `permission { edit: allow, write: allow }` (sin tools restriction). `gentleman` queda como alias legacy. |

## Qué se eliminó

- **Sección `## Inheritance`**: Ya no existe. No se hereda de ningún archivo global.
- **Paths absolutos**: Todos los `C:\Users\MK\...` y `C:\Users\LuisOrozco\...` en archivos de configuración activa fueron reemplazados.

## Lo que NO se tocó

`CHANGELOG.md`, `BITACORA.md`, `docs/metricas/`, `docs/bitacora.md` — son registros históricos. Documentan eventos reales con el user `MK`. Reescribirlos sería falsificar el historial.

---

## Cómo replicar en una máquina nueva

### 1. Clonar el repo

```bash
git clone https://github.com/LuisAlbertoMK/gentleman-agent-gh.git
cd gentleman-agent-gh
```

### 2. Vincular skills (junctions powershell)

```powershell
# Desde la raíz del proyecto
Get-ChildItem -Path ".\.agents\skills" -Directory | ForEach-Object {
    $target = "$env:USERPROFILE\.config\opencode\skills\$($_.Name)"
    if (!(Test-Path $target)) {
        New-Item -ItemType Junction -Path $target -Target $_.FullName
    }
}
```

### 3. Copiar/actualizar opencode.json global

```powershell
# Opción A: Copiar el del proyecto como base
Copy-Item ".\opencode.json" "$env:USERPROFILE\.config\opencode\opencode.json"

# Opción B: Agregar gentleman-vMK manualmente
# Copiar el bloque "gentleman-vMK" del opencode.json del proyecto
# al opencode.json global
```

### 4. Copiar prompts SDD globales

```powershell
Copy-Item -Recurse ".\prompts\sdd" "$env:USERPROFILE\.config\opencode\prompts\sdd"
```

### 5. Copiar AGENTS.md global (fallback)

```powershell
Copy-Item ".\AGENTS.md" "$env:USERPROFILE\.config\opencode\AGENTS.md"
```

---

## Arquitectura final

```
~/.config/opencode/
├── opencode.json        → define gentleman-vMK + subagentes SDD
├── AGENTS.md            → self-contained (fallback global)
├── prompts/sdd/         → prompts para subagentes SDD
└── skills/              → junctions → proyecto/.agents/skills/{name}

proyecto/
├── AGENTS.md            → self-contained (canónico, en git)
├── opencode.json        → define gentleman-vMK + subagentes SDD
├── .agents/skills/      → 55 skills (canónico, en git)
└── prompts/sdd/         → prompts SDD (en git)
```

**En el proyecto**: `gentleman-vMK` usa `AGENTS.md` del proyecto (self-contained + Project Context).
**Fuera del proyecto**: `gentleman-vMK` usa `AGENTS.md` global (self-contained, sin Project Context).
**Ambos funcionan** porque ambos AGENTS.md tienen el mismo contenido de personalidad, reglas y protocolos.

---

## Dato clave

El agente `gentleman` VIEJO tenía `"tools": {"edit": true, "write": true}` que bloqueaba bash, read, delegate, etc. El nuevo `gentleman-vMK` usa `"permission"` — permite todos los tools por defecto, solo pide confirmación para operaciones destructivas (commit, push, etc.) según las reglas de `permission.bash`.

Ver `docs/quality-standard.md` para el estándar de calidad aplicado.
