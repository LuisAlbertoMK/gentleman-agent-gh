# SYNC-N-PROJECTS — Sincro masiva reproducible

## Qué hace

Propaga la chain SSoT a N proyectos hermanos en un solo comando.

- **SSoT chain:** `scripts/lib/opencode-base.json` → `opencode.json`
- **Modelo chain pinchado:** `opencode/muse-spark-1.3-contributor-free` en 5 subs:
  `gentleman-quick-sub`, `frontend-sub`, `datascience-sub`, `docs-sub`, `quick-sub-auto`.
  Resto de subs: Go / deepseek / mimo / qwen (sin tocar).
- **Wrapper:** `scripts/sync-n-projects.ps1` (fallback `hashtable-splat` reparado 2026-09-15).
  Binario Go `cmd/sync/main.go` OK (toolchain go1.27.1, build exit 0; recompilado post-rename 2026-09-21, default `gentle-MK`); fallback PS a `use-gentleman.ps1` se mantiene como respaldo.
- **Manifest:** `projects.json` (`version: 1`, `chainRoot: "."`, `defaultMode: chain-wins`).

## Manifest por máquina (NO se versiona)

`projects.json` es específico de cada máquina: lista proyectos hermanos con paths
relativos (`../<name>`) que sólo existen en el equipo que lo generó. Por eso
**no está versionado** (ver `.gitignore`). Lo versionado es la plantilla
`projects.json.example`, que usa el mismo esquema.

En un equipo nuevo, generá el manifest con auto-descubrimiento (no lo escribas a mano):

```powershell
pwsh ./scripts/sync-n-projects.ps1 -Discover -DryRun
```

Vista previa (no escribe). Para generarlo:

```powershell
pwsh ./scripts/sync-n-projects.ps1 -Discover
```

- `-Discover` escanea el directorio padre del repo chain y considera candidatos los
  subdirectorios directos que sean repos git (tengan `.git`) o que contengan `opencode.json`.
- Excluye: el propio repo chain, directorios ocultos (`.`), `node_modules`.
- `.gitignore` no se consulta: el manifest es una allowlist por máquina que el operador
  cura después (ver NOTA en el script).
- Nunca pisa un `projects.json` existente sin `-Force` (falla con mensaje claro).
- `-DiscoverRoot` permite escanear otra raíz; `-DryRun` imprime sin escribir;
  `-Json` emite el manifest como JSON. El output es determinístico (orden alfabético).
- `-Discover` sale sin sincronizar: no toca `chain-wins`/`project-wins`, fallback ni reportes.

> Discovery vive hoy en el wrapper PS. La paridad en el binario Go (`cmd/sync`) es un
> follow-up explícito, no parte de este cambio.

## Prerequisitos

- `pwsh` 7+ (obligatorio).
- Go: opcional. Si el toolchain está sano compila el binario; si no, el wrapper usa el fallback PS.
- Ejecutar desde la raíz del repo chain.

```powershell
pwsh --version
```

## Manifest schema (`projects.json`)

```json
{
  "version": 1,
  "chainRoot": ".",
  "defaultMode": "chain-wins",
  "projects": [
    { "path": "../mi-api", "defaultAgent": "gentle-MK" },
    { "path": "../mi-web", "defaultAgent": "gentle-MK" }
  ]
}
```

- `version`: `1`.
- `chainRoot`: `"."` (raíz del repo chain).
- `defaultMode`: `chain-wins`.
- `projects[]`: `path` (relativo a la raíz chain, layout hermano `../<name>`) +
  `defaultAgent` (ej. `gentle-MK`). No hay `name` ni `mode` por proyecto en el archivo
  (el esquema `name`+`path`+`mode` con paths absolutos `D:\...` de versiones
  anteriores de este doc quedó obsoleto).

## Dry-run vs Real

Dry-run (no escribe, 15/15 OK `success:true binaryUsed:false` verificado 2026-09-15):

```powershell
pwsh ./scripts/sync-n-projects.ps1 -Manifest ./projects.json -Mode chain-wins -DryRun -Json -Yes
```

Real (escribe; resultado verificado: 15/15 OK — 11 actualizados por merge, 4 creados:
`conversor`, `leandro`, `musica`, `youtube_transcription`):

```powershell
pwsh ./scripts/sync-n-projects.ps1 -Manifest ./projects.json -Mode chain-wins -Json -Yes
```

Sin `-Yes` pide confirmación interactiva. `-Json` emite el reporte por proyecto.

## Modos chain-wins / project-wins

- `chain-wins` (default): la chain pisa el modelo en los 5 subs pinchados.
- `project-wins`: preserva el modelo local del proyecto (merge conserva `big-pickle` / `nemotron` / `laguna` donde existan).

```powershell
pwsh ./scripts/sync-n-projects.ps1 -Manifest ./projects.json -Mode project-wins -Json -Yes
```

## Verificación

```powershell
python -c "import json; d=json.load(open('projects.json')); print(len(d['projects']))"
```

```powershell
pwsh -Command "$d = Get-Content ./projects.json | ConvertFrom-Json; foreach ($p in $d.projects) { $f = Join-Path $p.path 'opencode.json'; $n = Split-Path $p.path -Leaf; if (Test-Path $f) { $j = Get-Content $f -Raw | ConvertFrom-Json; $c = @($j.subagent.PSObject.Properties | Where-Object { $_.Value.model -like 'opencode/muse-spark-1.3-contributor-free' }).Count; Write-Output \"${n}: $c\" } else { Write-Output \"${n}: MISSING\" } }"
```

Criterio: `zen-free >= 5` en cada proyecto con `opencode.json` chain-compatible.
Verificado: `erp-talleres` 16, `musica` 5 exacto, `arturo` 0 — divergencia conocida, no fallo
(merge `project-wins` preservó `big-pickle` / `nemotron` / `laguna` locales).

## `.gentleman-mode`

El sync no lo gestiona. Crear manual solo si ausente; no pisar existentes.

```powershell
pwsh -Command "$d = Get-Content ./projects.json | ConvertFrom-Json; foreach ($p in $d.projects) { $f = Join-Path $p.path '.gentleman-mode'; $n = Split-Path $p.path -Leaf; if (-not (Test-Path $f)) { 'manual' | Set-Content $f; Write-Output \"created: ${n}\" } }"
```

Conocido: `automatizacion` y `Reportes-myco` ya están en `auto` — no tocar.

## Troubleshooting

| Síntoma | Causa | Fix |
|---|---|---|
| `ValidateSet` / splat falla en `sync-n-projects.ps1` | splat directo de hashtable con `ValidateSet` | usar fallback `hashtable-splat` (reparado 2026-09-15) |
| Go no compila `cmd/sync/main.go` | toolchain dañado (verificado OK go1.27.1 el 2026-09-21) | recompilar `go build -o bin/sync.exe ./cmd/sync`; si falla, el wrapper cae a `use-gentleman.ps1` (`binaryUsed:false` es OK) |
| `target missing` | path `../...` inexistente en esta máquina (manifest de otro equipo) | regenerar con `-Discover -Force` o verificar path |
| freeze en `.model-cache` | caché de modelo colgada | borrar `<proyecto>\.model-cache` y reintentar |
| `arturo` con 0 `zen-free` | merge `project-wins` preservó `big-pickle`/`nemotron`/`laguna` | divergencia conocida, no fallo; para alinearlo correr ese proyecto en `chain-wins` |
