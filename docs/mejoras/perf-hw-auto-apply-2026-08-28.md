# Perf — Hardware Profile Auto-Apply (startup tier)

> Rama: `experiment/perf-deep-2026-08-28` · Creado: 2026-08-28
> Script: `scripts/hardware-profile.ps1` · Doc: este archivo

Permite aplicar automáticamente el perfil de hardware detectado a la configuración
de OpenCode en startup, sin sobreescribir config custom.

## Tiers

| Tier   | RAM       | Cores | watcher.enabled | subagent_depth | compaction.reserved | mcp | snapshot |
|--------|-----------|-------|-----------------|----------------|---------------------|-----|----------|
| low    | <=4GB     | <=2   | false           | 1              | 4000                | {}  | false    |
| medium | 4-8GB     | 4     | false + ignore  | 2              | 6000                | {}  | true     |
| high   | 8GB+      | 6+    | true + ignore   | 3              | 8000                | {}  | true     |

Todos los tiers comparten `model=opencode/big-pickle`, `small_model=opencode/free`,
`compaction.auto=true`, `compaction.prune=true`.

## Detección (13.94GB -> medium)

El script usa `Get-CimInstance Win32_ComputerSystem` para leer `TotalPhysicalMemory`
(Win32) y redondea a GB enteros (`[math]::Round(bytes/1GiB, 0)`).

Detección real en este equipo:

```
RAM:  13.94 GB -> round -> 14 GB
Cores: 4
Regla: ram<=8 o cores<=4 -> medium   =>  detected tier = MEDIUM
```

El round a 14GB entra en `medium` por la condición `$ram -le 8 -or $cpu.Cores -le 4`
(4 cores cumple la segunda rama). Aunque el RAM nominal (>8GB) sugeriría HIGH, el
umbral de cores lo fija en MEDIUM — comportamiento esperado del criterio combinado
RAM+cores.

## Settings por tier

Al aplicar, se escribe/emite este subset de `opencode.json` (la sección gestionada):

- `watcher` (enabled + ignore por tier)
- `compaction` (auto/prune/reserved/keep)
- `mcp` (mapa por tier)
- `agent.default.depth` (subagent_depth)
- `model` / `small_model`
- `memory_monitoring` (env vars)

### Compaction en este repo

El `opencode.json` actual define `compaction.reserved=4000` / `keep.tokens=6000`
manualmente. La referencia `medium` usa `reserved=6000` / `tokens=12000`. Dado que
`opencode.json` es custom (13 agents, MCP servers, permission rules), **no se
sobrescribe**: se emite `opencode.configs/medium-opencode.json` para revisión.

## Uso: `-Apply`

```
# Auto-detect tier y aplicar (o emitir referencia si opencode.json es custom)
.\scripts\hardware-profile.ps1 -Apply

# Fijar un tier explícito
.\scripts\hardware-profile.ps1 -OutputProfile high -Apply

# Salida JSON / escribir perfiles sigue funcionando sin -Apply
.\scripts\hardware-profile.ps1 -OutputProfile detect -Json
.\scripts\hardware-profile.ps1 -OutputProfile all -WriteProfile
```

### Comportamiento (no rompe parse ni custom config)

1. Detecta el tier (o usa `-OutputProfile`).
2. Valida: `-Apply` prohíbe `-OutputProfile all`.
3. Emite **siempre** un reference config en `opencode.configs/<tier>-opencode.json`.
4. Escribe en `opencode.json` **solo si**:
   - no existe, **o**
   - existe el sidecar `.opencode-hw-tier` (creado por este script el apply previo).
5. Si `opencode.json` existe pero **no** tiene el marker → lo considera custom y lo
   deja intacto; muestra un mensaje con el path de referencia y el `Copy-Item` sugerido.

## Validación

- `pwsh -Parse`: `System.Management.Automation.Language.Parser::ParseFile` → **PARSE OK**.
- Test aplicado (sandbox temp, sin tocar repo):
  - Sin `opencode.json` → apply a `opencode.json`, crea `.opencode-hw-tier=medium`,
    emite `opencode.configs/medium-opencode.json`.
  - `opencode.json` custom + sin marker → **no overwrite**; deja el json intacto.
- Detección real runtime: `RAM 13.94GB` / `4 cores` → tier `medium`.

## Alcance / limites

- Solo toca `scripts/hardware-profile.ps1` (modificado) y este doc (creado).
- Compat PS5.1/7: sin `::new()`, sin operador ternary; PS5.1-safe.
- No tokeniza ni modifica MCP server block del repo (custom) — solo vía config de
  referencia.
