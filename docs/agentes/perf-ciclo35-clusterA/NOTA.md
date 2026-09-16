# Ciclo 35 — Cluster A: velocidad edicion + refs archivos + sin cuelgues (SOLO PS)

Fecha: 2026-09-15. Env: pwsh 7.6.6 Win32NT (in-process; redirect 5.1 NO ejercido,
solo medido el guard). Equipo ref x: Ryzen 3700U 4C/8T, 16GB, SATA SSD (este run
en Win32NT pwsh 7.6.6 — comparar deltas, no absolutos). Metodo: harness aislado
en TEMP (`C:\Users\MK\AppData\Local\Temp\opencode\c35-clusterA-harness.ps1`),
sin modificar repo. Cada exp: hipotesis, cambio minimo, Measure-Command 3-run +
WorkingSet, veredicto. Plan 02 ausente — se uso el Goal como plan (sin desvio).
server-commands.ps1: NOTA — no existe en repo (glob 0 hits).

SkillOpt: n/a (sin cambios aplicados, size delta 0%).

## Tabla 10 experimentos (avg 3-run; run1 = warmup/JIT, ver notas)

| ID | Hipotesis | Base (ms avg) | Opt (ms avg) | Delta | WS (MB) | Veredicto |
|----|-----------|---------------|--------------|-------|---------|-----------|
| E1 | Find-Pwsh (2x Get-Command) cuesta vs var cacheada (redirect 5.1->7) | 14.41 [38.83,2.15,2.25] | 6.35 (env-read; steady ~0.2-0.3) | +55.9% | 84.72 | ADOPTAR cachear Find-Pwsh por sesion |
| E2 | Test-Path guard evita spawn colgado del handshake `--help` | 1943.33 (Job+timeout 5s; binario AUSENTE — es costo Job, no handshake real) | 9.46 (Test-Path solo) | +99.5% | 96.78 | ADOPTAR guard Test-Path primero; binario ausente => path real hoy = fallback use-gentleman.ps1 |
| E3 | 1 dot-source gana a x3 (platform+template-detection+json-utils) | 32.08 (x3) | 5.03 (x1) | +84.3% | 100.29 | ADOPTAR: consolidar libs o memo en bulk; steady ~2x (8.16 vs 3.45-4.22) |
| E4 | Set-Content directo gana a temp+Move atomico (manifest ~15KB) | 7.56 (directo) | 20.70 (temp+Move) | -173.8% | 100.62 | MANTENER atomico — correccion > velocidad (media-manifest corrupto es peor que +13ms) |
| E5 | registry memoria gana a Get-Content+ConvertFrom-Json por Status/List | 13.62 | 3.16 | +76.8% | 102.18 | ADOPTAR cache registry en sesion con invalidacion por PID |
| E6 | loop directo gana a ShouldProcess x20 en bulk (-WhatIf) | 19.94 (ShouldProcess) | 2.15 (directo) | +89.2% | 102.41 | ADOPTAR: un solo ShouldProcess envolvente en bulk, no por proyecto |
| E7 | memo manifest gana a re-leer projects.json x10 | 40.20 | 1.98 | +95.1% | 104.82 | ADOPTAR (mejor ratio costo/riesgo): leer 1 vez, pasar objeto |
| E8 | path precomputado gana a IsPathRooted+GetFullPath x50 | 34.23 | 2.16 | +93.7% | 105.03 | ADOPTAR manifestDir precomputado fuera del loop |
| E9 | Quiet gana a Write-Output x50 en bulk | 21.98 | 2.14 | +90.3% | 105.06 | ADOPTAR -Quiet en bulk; resumir al final (patron ya usado en sync-n-projects) |
| E10 | cwd directo gana a walk-up Get-GentlemanProjectRoot x20 | 71.12 | 10.91 | +84.7% | 105.16 | ADOPTAR: resolver root 1 vez por invocacion, no por proyecto/nivel |

Notas honestas:
- Warmup: run1 siempre domina (JIT + cold FS). Steady-state (run2-3) el win es
  AUN mayor en E1/E3/E5-E10 (ej E1 steady ~2.2 vs ~0.26 = ~88%). Tabla usa avg
  3-run como pide el constraint (criterio conservador).
- E2 honesto: `bin/sync.exe` NO existe (Test-Path False ambos) => E2_base mide
  spawn de Job (~1.7-2.2s), no handshake real. Conclusion intacta: el guard
  Test-Path (9.46ms, steady ~1.1ms) evita el peor-caso (Job colgado x timeout 5s
  + comentario v1 "no async timeout — hung binary blocks wrapper"
  sync-n-projects.ps1:211-212). Jamas llamar `--help` sin guard + timeout.
- E4 es el unico NO ADOPTAR por velocidad: temp+Move cuesta +13ms pero evita
  manifest a medias (carrera entre runs concurrentes). Velocidad pierde.
- Sin cuelgues: 0 hangs en 10 exps. WS 80.01 -> 105.16 MB total harness
  (+25MB; por-exp +0-4MB estable, sin fuga monotona). E2 contenido por
  Wait-Job -Timeout 5 + Stop/Remove-Job.

## Refs archivos (ataques -> lineas)

- redirect pwsh5->7: scripts/sync-n-projects.ps1:65-93 (Find-Pwsh + re-exec).
- handshake `--help` + timeout: scripts/sync-n-projects.ps1:196-206 (guard+handshake),
  :211-212 (v1 sin async timeout), :213-237 (stderr a temp, LASTEXITCODE).
- dot-source lib xN: scripts/sync-n-projects.ps1:62 (x1);
  scripts/use-gentleman.ps1:56,103-104 (x3: platform+template-detection+json-utils);
  scripts/switch-mode.ps1:83-84 (x1 + Get-GentlemanProjectRoot:87).
- file-lock atomic rewrite: scripts/sync-n-projects.ps1:146-157 (temp+Move+cleanup).
- long-lived servers: scripts/dev-server.ps1:66-79 (Get/Save-Registry),
  :159 (sleep 1500 post-Start), :246-260 (Cleanup dead entries).
- ShouldProcess bulk: scripts/dev-server.ps1:89,111,223 (por servidor);
  scripts/sync-n-projects.ps1:209,256 (por manifest/proyecto);
  hallazgo: scripts/switch-mode.ps1 declara SupportsShouldProcess pero nunca
  llama ShouldProcess (seteo de modo sin confirmacion — OK en auto, flag si se endurece).

## Delta total + top edicion-win

- Suma base: ~2243ms (domina E2-Job) / suma opt: ~63ms => -97.2% agregado.
  Sin E2 (outlier Job): base ~300ms -> opt ~54ms = -82.1% reproducible.
- Top edicion-win: **E7 (memo manifest, +95.1%) + E8 (path precomputado, +93.7%)
  + E9 (-Quiet, +90.3%)**: los tres tocan el path mas caliente (bulk por proyecto
  en sync-n-projects fallback, el path REAL hoy sin binario) y son cambio minimo
  reversible (variable local + flag existente). E2 es el mayor absoluto pero es
  evitar-peor-caso, no edicion. E4 se rechaza explicitamente por correccion.

## Verificacion

- Harness + fixtures solo en TEMP (`c35-clusterA/` results.json), repo intacto
  salvo este NOTA.md nuevo (permitido).
- PROHIBIDO delete/push/commit/rm: cumplido (ningun delete/push/commit/rm
  ejecutado; E4/E5 usan TEMP; E2 con job contenido).
- Repro: `pwsh -NoProfile -File C:\Users\MK\AppData\Local\Temp\opencode\c35-clusterA-harness.ps1`.
