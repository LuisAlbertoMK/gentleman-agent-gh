# Ciclo 36 — Cluster B: cache/batching .NET + string building (SOLO PS)

Fecha: 2026-09-15. Env: pwsh 7.6.6 Win32NT (harness corre en 7.6.6).
Metodo: harness aislado en TEMP
(`C:\Users\MK\AppData\Local\Temp\opencode\c36-clusterB\c36-clusterB-harness.ps1`),
sin modificar repo. Cada exp: hipotesis, cambio minimo, Measure-Command 3-run +
WorkingSet, veredicto. `scripts/benchmark.ps1` AUSENTE en repo — se uso
`scripts/benchmark-core.ps1` + `scripts/bench-compare.ps1` como referencia
(sin crear nada; ver Nota benchmark). Plan 02 ausente — se uso el Goal como
plan (sin desvio, replica C36-clusterA).

SkillOpt: 6/6 archivos parse OK (0 errores), size delta 0% (sin cambios aplicados).

## Tabla 10 experimentos (avg 3-run; run1 = warmup/JIT, ver notas)

| ID | Hipotesis | Base (ms avg) | Opt (ms avg) | Delta | WS (MB B/O) | Veredicto |
|----|-----------|---------------|--------------|-------|-------------|-----------|
| E1 | StringBuilder gana a `+=` en reporte chico 200 lineas (patron salida check-token-budget/bench-compare) | 9.90 [28.79,0.51,0.41] | 11.07 [28.65,2.29,2.26] | -11.8% (empate tecnico, ruido warmup) | 84.70/84.45 | RECHAZAR SB en chico — MANTENER simple; E3 decide el patron real |
| E2 | StringBuilder gana a `+=` en reporte grande 1000 lineas (escala) | 19.50 [37.76,7.80,12.95] | 17.33 [27.34,15.03,9.61] | +11.1% marginal | 84.93/82.73 | ADOPTAR solo si >~500 lineas; E3 (`-join`) lo supera igual |
| E3 | Array + `-join` gana a StringBuilder (200 lineas) | 9.65 SB [25.39,1.87,1.70] | 6.81 join [18.75,1.10,0.59] | +29.4% | 80.80/80.27 | ADOPTAR `-join` para reportes — top edicion-win de string building |
| E4 | Hashtable lookup gana a `Where-Object` lineal (90 skills x200 lookups; patron domainSpecialists/score-dims) | 471.24 [536.52,494.73,382.47] | 12.75 [36.35,0.94,0.95] | +97.3% | 89.03/84.48 | ADOPTAR Hashtable — top win absoluto del cluster |
| E5 | Hashtable index gana a PSCustomObject prop (5000 lookups; patron stats.skills/stats.prompts) | 24.17 [45.25,14.85,12.40] | 19.74 [33.59,13.38,12.26] | +18.3% | 86.93/85.32 | ADOPTAR Hashtable en path caliente; MANTENER PSCustomObject si legibilidad manda (win chico) |
| E6 | `[regex]` Compiled + IsMatch gana a `-match` (4000 strings; patron runtimeFilesRe) | 21.13 match [42.02,8.61,12.75] | 72.80 compiled [84.91,67.16,66.32] | -244.5% PIERDE | 88.11/89.79 | RECHAZAR Compiled — MANTENER `-match` (ver E6b) |
| E7 | 1 regex combinada gana a 3x `-match` (4000 ficheros; extiende E10/ciclo34) | 30.91 [50.80,25.67,16.27] | 14.39 [18.70,6.84,17.63] | +53.4% | 85.91/87.51 | ADOPTAR combinada (ya aplicado en runtimeFilesRe:101 — confirmar, no re-tocar) |
| E8 | Batch enumeration + set gana a N `Test-Path` (50 ficheros TEMP; patron skills-exists) | 78.44 [84.57,78.79,71.96] | 31.77 [75.00,13.11,7.20] | +59.5% | 92.11/88.36 | ADOPTAR batch cuando N>~10; Test-Path suelto solo para 1-2 guards (E3/C36A intacto) |
| E9 | Cachear `$env:GENTLEMAN_AGENT_ROOT` en local gana a leer env en loop x5000 (patron E9/ciclo34 + Get-GentlemanRoot) | 802.56 [836.66,775.94,795.10] | 574.95 [547.27,621.52,556.04] | +28.4% | 96.87/100.70 | ADOPTAR hoist a `$root` en todo loop caliente (Join-Path x5000 es el caso extremo; en 1-shot irrelevante) |
| E10 | Memo session-scope gana a re-leer+parsear x20 (patron E10/C36A registry) | 34.22 [67.64,21.54,13.49] | 14.53 [42.65,0.46,0.48] | +57.5% | 96.63/97.00 | ADOPTAR memo con invalidacion por hash/mtime (steady 0.4ms vs 13-21ms) |

Notas honestas:
- Warmup: run1 siempre domina (JIT + cold FS). Steady-state (run2-3) el win es
  AUN mayor en E3/E4/E8/E10 (ej E4 steady 494/382ms -> 0.9ms; E10 steady
  21/13ms -> 0.4ms). Tabla usa avg 3-run como pide el constraint (conservador).
- E1 honesto: a 200 lineas `+=` (steady ~0.4ms) empata o gana a SB (steady
  ~2.2ms); el -11.8% es ruido+overhead de `Append(format)` vs `+=`. E2 a 1000
  lineas SB si gana (+11.1%) pero E3 `-join` (steady 0.5-1.1ms) gana a AMBOS.
  Regla: reportes = array + `-join`; SB solo si se construye por fragmentos
  condicionales sin array natural. No tocar salidas 1-shot (Write-Output
  directo ya es gratis).
- E6/E6b honesto: Compiled PIERDE -244.5% y `[regex]` NO-compilado tambien
  pierde ~2x (e6b-check: match [37.57,12.68,26.80] vs RegexNC-IsMatch
  [57.60,47.83,45.33] en re-run; primer run [51.43,17.04,28.33] vs
  [84.00,51.26,71.43]). El operador `-match` cachea el regex internamente y
  evita el overhead de llamada `.IsMatch` + objeto. Conclusion: NO compilar,
  NO instanciar `[regex]` en caliente — `-match` literal o 1 combinada (E7).
- E5 honesto: win +18.3% chico y dentro de ruido parcial (steady 12.4 vs 12.2
  en run3); el valor es en loops >1K lookups (score-dims, token-budget). En
  accesos 1-shot la legibilidad de PSCustomObject manda.
- E8 honesto: el opt paga 1 enumeracion (run1 75ms) y luego steady 7-13ms vs
  72-79ms de N Test-Path. Con N<=2 el guard suelto sigue ganando (E3/C36A);
  batch solo cuando N>~10 o el dir ya esta en mano.
- E9 honesto: caso extremo x5000 Join-Path para hacerlo medible; en codigo
  real el win por llamada es ~45us (env-provider + Join-Path.bind). Gratis de
  aplicar (`$root = $env:GENTLEMAN_AGENT_ROOT` una vez) — patron ya exigido
  en check-token-budget:94 (`$locPrefix` hoist).
- E10 honesto: compara TEMP (90-line memo file), no el registry real; el opt
  run1 (42.65ms = 1 read+parse) luego 0.4ms memo-hit. Sin invalidacion el memo
  es STALE — exigir hash/mtime (replica E10/C36A).
- Edge cases: reporte 0 lineas (`''` vs `SB.ToString()` vs `'' -join`) empate;
  Test-Path inexistente = `$false` en ambos brazos (set miss = `$null` ->
  `$false` via ContainsKey); env ausente = `$null` Join-Path falla igual en
  ambos (hoist no cambia semantica); memo vacio = `$null` guard re-lee.
- Sin cuelgues: 0 hangs en 10 exps (+1 e6b). WS 80.27 -> 100.70 MB total
  harness (+20MB; por-exp estable, sin fuga monotona). Sin jobs/runspaces en
  este cluster (solo .NET sync + FS TEMP).

## Refs archivos (ataques -> lineas)

- StringBuilder vs `+=` / `-join` en reportes: scripts/check-token-budget.ps1:135-142
  (Write-Output por lineas — candidato a array + `-join` si se unifica);
  scripts/bench-compare.ps1:72-76 (Format-Table — no tocar, pipeline nativo);
  scripts/benchmark-core.ps1:146-151 (`dump` con Write-Output multilinea).
- Hashtable vs PSCustomObject lookup: scripts/delegation-fit-gate.ps1:108-116
  (`$domainSpecialists` Hashtable — E4 lo confirma, no tocar);
  scripts/check-token-budget.ps1:53-59,97-112 (`$stats.skills/prompts`
  PSCustomObject 1-shot — E5 dice no tocar).
- Compiled regex: scripts/validate-write-scope.ps1:101,123-137
  (`$runtimeFilesRe` combinada + `Convert-GlobToRegex` precompilado 1x fuera
  del loop — E6/E7 dicen NO agregar Compiled, patron actual correcto).
- Batch Test-Path: scripts/lib/platform.ps1:58,78
  (`Test-Path .git` 1-shot por llamada — E8 dice NO batchear; guard suelto
  correcto); batch solo si N>~10 (ej walk de skills).
- Cache GENTLEMAN_AGENT_ROOT/env: scripts/lib/platform.ps1:59
  (`return $env:GENTLEMAN_AGENT_ROOT` fallback — E9: hoistear en loops);
  scripts/check-token-budget.ps1:94 (`$locPrefix` hoist — patron correcto).
- Session-state memo: scripts/benchmark-core.ps1:173-186 (baseline read por
  Gate — candidato a memo en sesion con mtime); replica E10/C36A (memo
  registry +87.1%).

## Nota benchmark (scripts/benchmark.ps1 ausente)

- El Goal lista `scripts/benchmark.ps1` como permitido, pero NO existe en repo
  (glob `scripts/bench*.ps1` -> benchmark-core.ps1, bench-compare.ps1,
  benchmark-regression.ps1). No se creo nada (habria violado "patch-first" y
  el scope). Referencia usada: benchmark-core.ps1:Regression (3-run? usa
  5-50 runs + mediana+IQR — este cluster usa avg 3-run por constraint del
  Goal, criterio mas conservador que mediana) y bench-compare.ps1 (tabla
  delta-vs-prev, mismo formato adoptado aqui).
- Pattern matched from: benchmark-core.ps1:222-237 (Stopwatch + Sort +
  mediana/IQR) para el harness; bench-compare.ps1:61-70 (DeltaVsPrev) para la
  columna Delta. Novel: WS por exp (no existe en benchmark-core) — no habia
  patron, se agrego WorkingSet64 MB.

## Delta total + top edicion-win

- Suma base: ~1501.72ms / suma opt: ~776.14ms => -48.3% agregado. Sin E9
  (outlier Join-Path x5000, 802ms): base ~699.16ms -> opt ~201.19ms = -71.2%
  reproducible en paths reales.
- Top edicion-win: **E4 (Hashtable lookup, +97.3%) + E8 (batch enumeration,
  +59.5%) + E10 (memo session, +57.5%)**: E4 toca cada lookup en listas de
  skills/agentes (cada invocacion gate/score), E8/E10 eliminan I/O repetido
  (el costo dominante real; el resto es µs de cuerpo). E7 (+53.4%) ya esta
  aplicado (runtimeFilesRe) — confirmar, no re-tocar. E6 se rechaza
  explicitamente (Compiled -244.5%); E1 se rechaza (SB en chico -11.8%) en
  favor de E3 (`-join` +29.4%).

## Verificacion

- Harness + fixtures solo en TEMP (`c36-clusterB/` harness + results.json +
  e6b-check + parse-check), repo intacto salvo este NOTA.md nuevo (permitido).
- Parse: 6/6 OK (check-token-budget, validate-write-scope, delegation-fit-gate,
  lib/platform, benchmark-core, bench-compare; errs=0). Size delta 0%.
- PROHIBIDO delete/push/commit/rm: cumplido (ningun delete/push/commit/rm
  ejecutado; E8/E10 usan TEMP; `git status` previo muestra cambios ajenos de
  otros clusters — no tocados por este task).
- Repro: `pwsh -NoProfile -File C:\Users\MK\AppData\Local\Temp\opencode\c36-clusterB\c36-clusterB-harness.ps1`
  + `pwsh -NoProfile -File C:\Users\MK\AppData\Local\Temp\opencode\c36-clusterB\e6b-check.ps1`.
