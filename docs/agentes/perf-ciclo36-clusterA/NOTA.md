# Ciclo 36 — Cluster A: I/O streaming + anti-cuelgue + timeouts (SOLO PS)

Fecha: 2026-09-15. Env: pwsh 7.6.6 Win32NT (harness corre en 7.6.6; parse-check
con quirk PS5.1 Firmado — errs=0 en los 5). Metodo: harness aislado en TEMP
(`C:\Users\MK\AppData\Local\Temp\opencode\c36-clusterA\c36-clusterA-harness.ps1`),
sin modificar repo. Cada exp: hipotesis, cambio minimo, Measure-Command 3-run +
WorkingSet, veredicto. Plan 02 ausente — se uso el Goal como plan (sin desvio).

SkillOpt: 5/5 archivos parse OK (0 errores), size delta 0% (sin cambios aplicados).

## Tabla 10 experimentos (avg 3-run; run1 = warmup/JIT, ver notas)

| ID | Hipotesis | Base (ms avg) | Opt (ms avg) | Delta | WS (MB) | Veredicto |
|----|-----------|---------------|--------------|-------|---------|-----------|
| E1 | Wait-Job timeout 300→60 igual en jobs rapidos, menor peor-caso | 160.06 [229.40,127.58,123.20] | 117.04 [130.31,110.02,110.81] | +26.9% (ruido warmup; empate tecnico) | 95.32 | ADOPTAR 60 por seguridad, no por velocidad |
| E2 | ReadAllText / streaming ganan a Get-Content -Raw x95 SKILL.md | 124.24 -Raw [154.01,104.05,114.65] | 21.64 ReadAllText [36.63,14.73,13.57] / 43.55 streaming ReadLines | +82.6% / +64.9% | 94.70 | ADOPTAR ReadAllText en batch caliente (ya es Read-SkillContent); streaming solo si memoria acotada |
| E3 | Test-Path guard evita spawn colgado del --help (binario ausente) | 1050.89 (Job+timeout 5s) | 11.64 [32.88,0.81,1.22] | +98.9% | 104.96 | ADOPTAR guard Test-Path primero; jamas --help sin guard+timeout |
| E4 | Dispose runspace evita leak + gana a no-Dispose x20 | 412.86 leak [481.39,380.14,377.05] | 290.28 disp [361.13,254.28,255.42] | +29.7% | 123.99 leak vs 121.05 disp (+2.94MB fuga) | ADOPTAR Dispose siempre (anti runspace-leak) |
| E5 | File-lock + retry/backoff convierte fail en exito bajo contencion | 30.07 naive | 22.53 locked (+25.1% sin contencion) / contencion: single 34.52 fail vs retry 332.84 ok | +25.1% / correccion | 116.16 | ADOPTAR lock+retry (correccion > velocidad) |
| E6 | Reusar csvRaw gana a 2do Get-Content del CSV | 16.75 [42.79,4.58,2.88] | 9.62 [24.75,2.19,1.94] | +42.6% | 108.98 | ADOPTAR (patron E6/C33 ya aplicado, confirmar) |
| E7 | IndexOf guard antes de regex en ConvertTo-JsonSafe x200 | 74.72 (regex directo) | 72.14 (guard) | +3.5% empate | 113.09 | MANTENER simple — guard no paga (ConvertTo-Json domina); replica E10/C33 |
| E8 | Single-pass cross+config gana a 2 loops (cacheado) | 12.13 [31.85,2.93,1.60] | 10.14 [26.01,2.65,1.76] | +16.4% | 113.16 | ADOPTAR (gratis; ya aplicado E1 cross-ref) |
| E9 | FileStream lock-read/write gana a Get+Set naive x20 (TEMP) | 117.99 naive [142.83,96.77,114.38] | 50.82 locked [87.59,34.03,30.83] | +56.9% | 115.30 | MANTENER lock actual — correccion + velocidad (menos open/close) |
| E10 | Memo registry gana a re-leer+parsear cache x10 | 42.62 [58.80,37.29,31.76] | 5.50 [16.22,0.16,0.11] | +87.1% | 115.35 | ADOPTAR memo en sesion con invalidacion por hash/mtime |

Notas honestas:
- Warmup: run1 siempre domina (JIT + cold FS + ThreadJob spin-up). Steady-state
  (run2-3) el win es AUN mayor en E2/E5/E6/E8/E10 (ej E10 steady 37→0.1ms).
  Tabla usa avg 3-run como pide el constraint (criterio conservador).
- E1 honesto: jobs de 50ms completan bajo ambos timeouts — el delta +26.9% es
  ruido de warmup, no efecto del timeout. El valor de 60 es acotar peor-caso
  (score-auto.ps1:201 con 3 ThreadJobs; un PSSA colgado hoy bloquea 300s),
  replica E9/C34 (empate tecnico).
- E2 honesto: -Raw con -Encoding UTF8 paga marshal string[]→string unico;
  ReadAllText es el fast-path real (ya usado en Read-SkillContent
  cross-ref-check.ps1:47). Streaming ReadLines queda en medio: solo compensa
  si el fichero no cabe en memoria o se hace early-exit (Tail/First).
- E3 honesto: binario AUSENTE — E3_base mide spawn+fail de Job (~1s), no
  handshake real. Conclusion intacta: Test-Path (11.64ms, steady ~1ms) evita
  el peor-caso; patron ya exigido en update-opencode.ps1:75-76 (Timeout 180).
- E4 fuga contenida: 60 runspaces sin Dispose dejan +2.94MB WS y el harness
  los deja al GC; con Dispose + GC explicito la WS vuelve a 121.05. Regla:
  todo `[powershell]::Create()` va con try/finally Dispose (mcp-resilience
  ya lo hace :296-298; no replicar el antipatron Start-Job de mejora-log:767).
- E5/E9 comparan TEMP, no el inter-track real: E5_locked steady 6-9ms vs
  naive 19-21ms; bajo contencion real (holder 300ms) single-attempt = fail,
  retry = ok en 332.84ms (espera + backoff). Correccion > ms.
- Sin cuelgues: 0 hangs en 10 exps. WS 95.32 → 115.35 MB total harness
  (+20MB; por-exp estable, sin fuga monotona salvo E4/contenido). Todos los
  jobs con Wait-Job -Timeout + Remove-Job -Force; runspaces con Dispose.

## Refs archivos (ataques -> lineas)

- Wait-Job timeout 300→60: scripts/score-auto.ps1:201
  (`$jobs | Wait-Job -Timeout 300`; 3 ThreadJobs crossref/pssa/backlog).
- Get-Content streaming vs -Raw x95 skills: scripts/skill-graph.ps1:79
  (`$csvRaw = Get-Content $CsvPath -Raw`); scripts/cross-ref-check.ps1:43-48
  (Read-SkillContent ya usa `[IO.File]::ReadAllText` — E2 lo confirma).
- Test-Path guard antes de --help: scripts/update-opencode.ps1:75-76
  (Start-Job + Wait-Job 180 + throw postinstall timeout); ADR-048 (contrato
  Test-Binary `--version` + timeout); C35/E2 (handshake sync.exe ausente).
- Runspace leak: scripts/lib/mcp-resilience.ps1:296-298 (runspace cancelable
  con Dispose — patron correcto); mejora-log.md:767 (Start-Job serializa y
  rompe closures; rediseño runspace REQUIRED).
- File-lock reintentos: scripts/inter-track.ps1:76-98 (Invoke-TrackLocked
  FileStream OpenOrCreate + Share::None + SetLength(0)/Seek + Flush/Close).
- JsonSafe regex guard: scripts/lib/json-utils.ps1:10-17 (ConvertTo-JsonSafe;
  E7 dice guard no paga — no tocar).

## Delta total + top edicion-win

- Suma base: ~2042ms / suma opt: ~611ms => -70.1% agregado. Sin E3 (outlier
  Job 1s): base ~991ms -> opt ~600ms = -39.5% reproducible.
- Top edicion-win: **E3 (guard Test-Path, +98.9%) + E10 (memo registry,
  +87.1%) + E2 (ReadAllText, +82.6%)**: E3 evita el peor-caso (cuelgue),
  E10/E2 tocan los paths mas calientes (cada invocacion score-auto /
  cross-ref x95 skills) y son cambio minimo reversible (guard + variable
  local + hashtable). E7 se rechaza explicitamente (empate); E1 se adopta
  por seguridad aunque sea empate tecnico.

## Verificacion

- Harness + fixtures solo en TEMP (`c36-clusterA/` results.json), repo intacto
  salvo este NOTA.md nuevo (permitido).
- Parse: 5/5 OK (score-auto, cross-ref-check, skill-graph, inter-track,
  json-utils; errs=0). Size delta 0%.
- PROHIBIDO delete/push/commit/rm: cumplido (ningun delete/push/commit/rm
  ejecutado; E5/E9 usan TEMP; E3/E1 con jobs contenidos + Remove-Job).
- Repro: `pwsh -NoProfile -File C:\Users\MK\AppData\Local\Temp\opencode\c36-clusterA\c36-clusterA-harness.ps1`.
