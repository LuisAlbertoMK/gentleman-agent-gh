# SYNC-N-PROJECTS — Sincro masiva reproducible

## Qué hace

Propaga la chain SSoT a los 15 proyectos D:\ en un solo comando.

- **SSoT chain:** `scripts/lib/opencode-base.json` → `opencode.json`
- **Modelo chain pinchado:** `opencode/muse-spark-1.3-contributor-free` en 5 subs:
  `gentleman-quick-sub`, `frontend-sub`, `datascience-sub`, `docs-sub`, `quick-sub-auto`.
  Resto de subs: Go / deepseek / mimo / qwen (sin tocar).
- **Wrapper:** `scripts/sync-n-projects.ps1` (fallback `hashtable-splat` reparado 2026-09-15).
  Binario Go `cmd/sync/main.go` no compila por toolchain corrupto → fallback a `use-gentleman.ps1`.
- **Manifest:** `projects.json` (`version: 1`, `chainRoot: "."`, `defaultMode: chain-wins`).
  15 proyectos reales en `D:\`: `arturo`, `automatizacion`, `clash`, `control-pedidos`,
  `conversor`, `erp-talleres`, `herramienta-tecnico`, `huawei-unlock-agent`, `kitchenos-full`,
  `leandro`, `monoMKservices`, `musica`, `Reportes-myco`, `sushi`, `youtube_transcription`.
  `Ford-MYCO` excluido por inexistente.

## Prerequisitos

- `pwsh` 7+ (obligatorio).
- Go: opcional. Si el toolchain está sano compila el binario; si no, el wrapper usa el fallback PS.
- Ejecutar desde la raíz del repo chain (`D:\gentleman-agent-gh`).

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
    { "name": "arturo", "path": "D:\\arturo", "mode": "chain-wins" }
  ]
}
```

- `version`: `1`.
- `chainRoot`: `"."` (raíz del repo chain).
- `defaultMode`: `chain-wins`.
- `projects[]`: `name` + `path` (absoluto `D:\...`) + `mode` opcional por proyecto.

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
pwsh -Command "$d = Get-Content ./projects.json | ConvertFrom-Json; foreach ($p in $d.projects) { $f = Join-Path $p.path 'opencode.json'; if (Test-Path $f) { $j = Get-Content $f -Raw | ConvertFrom-Json; $n = @($j.subagent.PSObject.Properties | Where-Object { $_.Value.model -like 'opencode/muse-spark-1.3-contributor-free' }).Count; Write-Output \"$($p.name): $n\" } else { Write-Output \"$($p.name): MISSING\" } }"
```

Criterio: `zen-free >= 5` en cada proyecto con `opencode.json` chain-compatible.
Verificado: `erp-talleres` 16, `musica` 5 exacto, `arturo` 0 — divergencia conocida, no fallo
(merge `project-wins` preservó `big-pickle` / `nemotron` / `laguna` locales).

## `.gentleman-mode`

El sync no lo gestiona. Crear manual solo si ausente; no pisar existentes.

```powershell
pwsh -Command "$d = Get-Content ./projects.json | ConvertFrom-Json; foreach ($p in $d.projects) { $f = Join-Path $p.path '.gentleman-mode'; if (-not (Test-Path $f)) { 'manual' | Set-Content $f; Write-Output \"created: $($p.name)\" } }"
```

Conocido: `automatizacion` y `Reportes-myco` ya están en `auto` — no tocar.

## Troubleshooting

| Síntoma | Causa | Fix |
|---|---|---|
| `ValidateSet` / splat falla en `sync-n-projects.ps1` | splat directo de hashtable con `ValidateSet` | usar fallback `hashtable-splat` (reparado 2026-09-15) |
| Go no compila `cmd/sync/main.go` | toolchain corrupto | ignorar binario; el wrapper cae a `use-gentleman.ps1` (`binaryUsed:false` es OK) |
| `target missing` | path `D:\...` inexistente | verificar path; `Ford-MYCO` está excluido a propósito |
| freeze en `.model-cache` | caché de modelo colgada | borrar `<proyecto>\.model-cache` y reintentar |
| `arturo` con 0 `zen-free` | merge `project-wins` preservó `big-pickle`/`nemotron`/`laguna` | divergencia conocida, no fallo; para alinearlo correr ese proyecto en `chain-wins` |
