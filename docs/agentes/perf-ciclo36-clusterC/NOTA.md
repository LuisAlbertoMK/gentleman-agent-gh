# Ciclo 36 — Cluster C: payload skills/MCP segunda oleada (dieta restante + lazy + refs cache)

Fecha: 2026-09-15. Env: Win32NT, harness en PowerShell (parse-check PS5.1 Firmado
compatible; sin jobs/runspaces — solo FS + .NET sync, 0 hangs).
Metodo: harness aislado en TEMP
(`C:\Users\MK\AppData\Local\Temp\opencode\c36-clusterC\c36-clusterC-harness.ps1`),
repo read-only (solo lecturas SKILL.md/ps1). Cada exp: hipotesis, cambio minimo,
Measure-Command 3-run + WorkingSet, veredicto. Plan 02 ausente — se uso el Goal
como plan (sin desvio, replica C36-clusterA/B).
`.agents/skills/codebase-memory-mcp/SKILL.md` AUSENTE en repo (Test-Path False) —
ver Nota MCP.

SkillOpt: 6/6 archivos parse OK (0 errores), size delta 0% (sin cambios aplicados).
Sizes: performance-tracker 3367B (~3.29KB, over-3KB), engram-protocol 3280B
(~3.20KB, over-3KB), skill-testing 2433B, cross-project-wisdom 2724B,
build-skill-registry.ps1 4946B, scan-skills.ps1 7865B, skill-graph.ps1 15.04KB.
Payload 4 SKILL.md = 11.53KB; AR total = 1892B (~16.3% del payload).

## Tabla 10 experimentos (avg 3-run; run1 = warmup/JIT, ver notas)

| ID | Hipotesis | Base (ms avg) | Opt (ms avg) | Delta | WS (MB) | Veredicto |
|----|-----------|---------------|--------------|-------|---------|-----------|
| E1 | Frontmatter-only (StreamReader hasta 2do `---`) gana a full read x4 SKILL.md (lazy payload) | 15.71 [24.28,14.86,8.01] | 8.44 [21.57,1.94,1.80] | +46.3% | 89.67 | ADOPTAR lazy: resolver solo frontmatter (registry/scan no necesitan el cuerpo) |
| E2 | Stripear `## Anti-Rationalization` gana a parsear full (dieta restantes over-3KB) | 8.85 [13.34,5.84,7.36] | 17.62 [36.28,8.81,7.77] | -99.1% PIERDE | 91.30 | RECHAZAR strip en caliente — regex paga 2x; dieta via edicion estatica (AR ya externalizado a reference en engram-protocol); AR co-ubicado vale sus 1892B |
| E3 | Hashtable de Refs gana a re-parsear `## Refs` por llamada x200 (refs unicos cache) | 1823.70 [2130.94,1829.53,1510.64] | 6.93 [13.79,2.98,4.03] | +99.6% | 104.80 | ADOPTAR refs cache — top edicion-win del cluster (junto a E4/E5) |
| E4 | Lazy MCP (guard + memo, sin probe) gana a `Get-Module -ListAvailable` x20 (MCP lazy) | 21306.11 [25105.78,19971.45,18841.11] | 1.19 [3.36,0.09,0.13] | +99.99% | 175.87 | ADOPTAR no-probear-providers hasta uso; skill `codebase-memory-mcp` AUSENTE (ver Nota MCP) |
| E5 | Memo frontmatter gana a re-parsear x20 (registry memo, patron E10/C36A) | 130.81 [139.32,127.04,126.06] | 1.21 [2.87,0.40,0.36] | +99.1% | 177.08 | ADOPTAR memo en sesion con invalidacion por hash/mtime (steady 0.4ms vs 126ms) |
| E6 | `[IO.File]::ReadAllText` gana a `Get-Content -Raw` x50 en payload skills | 231.49 [214.15,243.48,236.84] | 50.80 [61.38,43.60,47.41] | +78.1% | 175.83 | ADOPTAR ReadAllText en batch caliente (replica E2/C36A, E6/C36B — tercera confirmacion) |
| E7 | 1 regex combinada (named groups) gana a 3x `-match` en frontmatter x2000 | 30.10 [31.27,28.78,30.25] | 88.81 [94.85,86.16,85.43] | -195.0% PIERDE | 176.07 | RECHAZAR combinada — `-match` cachea regex internamente (replica E6/C36B Compiled -244.5%) |
| E8 | 1 enumeracion + set gana a N `Test-Path` (95 skill dirs x10; registry build) | 583.99 [592.31,653.37,506.29] | 728.91 [839.59,690.01,657.12] | -24.8% PIERDE | 181.79 | RECHAZAR batch-recursivo: `-Recurse` + filtro `_shared` domina; MANTENER N Test-Path (~0.6ms c/u) o memoizar set 1x (E10) |
| E9 | Hoist `$root` gana a leer `$env:` por llamada x2000 (patron E9/C36B) | 184.36 [150.28,220.60,182.20] | 191.17 [177.20,199.05,197.26] | -3.7% empate | 179.76 | MANTENER simple — empate tecnico (ruido); hoist gratis pero no medible a este N (E9/C36B +28% solo en x5000 extremo) |
| E10 | Memo drift-check gana a re-leer grafo+disco x10 (scan-skills: graph 15.04KB + 4 SKILL.md) | 56.72 [66.21,54.34,49.61] | 0.95 [2.48,0.18,0.19] | +98.3% | 179.85 | ADOPTAR memo drift con mtime (steady 0.18ms vs ~50ms) |

Notas honestas:
- Warmup: run1 domina en E1/E2 (cold FS). Steady-state (run2-3) el win es AUN
  mayor en E1 (14.8/8 -> 1.9/1.8), E3 (1829/1510 -> 3/4), E5 (127/126 -> 0.4/0.36)
  y E10 (54/49 -> 0.18/0.19). Tabla usa avg 3-run (conservador, como A/B).
- E4 honesto: outlier de 21s — `Get-Module -ListAvailable` escanea TODOS los
  modulos instalados, no es un handshake MCP real. El punto intacto: probing
  eager de providers es el costo dominante por ordenes de magnitud; lazy-guard
  + memo lo elimina. No hubo spawn de procesos ni jobs (0 hangs).
- E2 honesto: el strip AHORRA 1892B (~16.3% tokens por carga) pero PAGA 2x CPU
  por parseo. Como el parseo ocurre 1x por sesion y los tokens se pagan por
  carga, la dieta correcta es estatica (editar el .md una vez), no runtime.
  `engram-protocol` ya externalizo a `docs/skills/engram-protocol/reference.md`
  (lineas 36-41) — ese es el patron a replicar en performance-tracker (3367B).
- E7 honesto: la combinada con named groups paga construccion de MatchCollection
  x2000; `-match` usa cache interna del motor. Replica exacta de E6/C36B.
- E8 honesto: contradice E8/C36B SOLO en apariencia — alli batch gano con 50
  ficheros TEMP sin `-Recurse` ni `Where-Object`; aqui el `-Recurse` sobre todo
  el arbol + filtro `_shared` cuesta mas que 95 Test-Path (~0.6ms c/u). Regla:
  batch solo con enumeracion acotada (`-Directory`, sin recurse), o set
  memoizado construido 1x (E10).
- E9 honesto: a x2000 la dif. esta dentro del ruido (run2-3 invertidos); el win
  de E9/C36B (+28%) requirio x5000 Join-Path para emerger (~45us/llamada).
  Gratis de aplicar, irrelevante en 1-shot.
- Bug de harness documentado: primer run midio 1 sola iteracion en E3-E7/E9-E10
  (variable `$i` del loop de medicion colisionaba con `$i` interno del
  scriptblock) + `fullKB=0` (Get-ChildItem con array LiteralPath). Corregido
  (`$k` externo, `$rep` en E8, suma por Get-Item) y re-ejecutado 3-run completo.
- Sin cuelgues: 0 hangs en 10 exps. WS 89.67 -> 179.85 MB total harness (+90MB;
  salto en E3/E4 por carga de modulos en `Get-Module -ListAvailable` — prueba
  adicional de que el probe eager es caro tambien en memoria).

## Refs archivos (ataques -> lineas)

- Lazy frontmatter (E1/E5): scripts/build-skill-registry.ps1:86-89
  (`Get-Content -Raw` full por skill + `Get-Frontmatter` que solo usa el bloque
  `---`; E1 dice leer solo hasta 2do `---`).
- Dieta restantes over-3KB (E2): .agents/skills/performance-tracker/SKILL.md:28-39
  (tabla Anti-Rationalization inline 3367B — candidato a externalizar a
  reference como ya hace engram-protocol:36-41); skill-testing:33-39 y
  cross-project-wisdom:52-58 (bajo 3KB, no tocar).
- Refs unicos cache (E3): performance-tracker:48-49, skill-testing:48-49,
  cross-project-wisdom:67-68, engram-protocol:57 (`## Refs` 1-liners — E3 dice
  cachearlos en Hashtable en vez de re-parsear).
- MCP lazy (E4): scripts/lib/mcp-resilience.ps1 (patron Dispose correcto, ver
  C36A/E4); skill `codebase-memory-mcp` AUSENTE (ver Nota MCP).
- ReadAllText (E6): scripts/cross-ref-check.ps1:43-48 (ya usa ReadAllText —
  cuarta confirmacion del fast-path); scripts/scan-skills.ps1:59,90
  (`Get-Content -Raw` x2 — candidatos a ReadAllText).
- Regex simple (E7): scripts/scan-skills.ps1:63,70-72,95
  (`-match` simples fuera del loop caliente — patron correcto, no combinar);
  scripts/build-skill-registry.ps1:33-72 (regex frontmatter 1x por archivo —
  correcto, no tocar).
- Batch vs Test-Path (E8): scripts/scan-skills.ps1:53-54
  (`-Recurse -File` + filtro `_shared` — E8 dice acotar o memoizar);
  scripts/lib/platform.ps1:58,78 (guards 1-shot — correctos, ver C36B/E8).
- Hoist env (E9): scripts/build-skill-registry.ps1:16-17 (`$PSScriptRoot`-based
  defaults — patron correcto); scripts/lib/platform.ps1:59 (E9/C36B: hoistear
  en loops).
- Drift memo (E10): scripts/scan-skills.ps1:53-110 (re-escanea disco+grafo por
  invocacion — candidato a memo con mtime); replica E10/C36A (+87.1%) y
  E10/C36B (+57.5%).

## Nota MCP (codebase-memory-mcp/SKILL.md ausente)

- El Goal lista `.agents/skills/codebase-memory-mcp/SKILL.md` como permitido
  "si existe, si no NOTA" — NO existe (`Test-Path` False, E4 lo verifica).
  No se creo nada (habria violado scope + "patch-first" + regla de no crear
  archivos salvo el NOTA permitido).
- Implicancia perf: sin skill MCP dedicado no hay payload extra que adelgazar;
  la leccion E4 (lazy-guard + memo, +99.99% vs probe eager) aplica al wiring
  MCP existente (mcp-resilience.ps1) sin necesidad de skill nueva.

## Delta total + top edicion-win

- Suma base: ~24322.94ms / suma opt: ~908.95ms => -96.3% agregado. Sin E4
  (outlier probe 21s): base ~3016.83ms -> opt ~907.76ms = -69.9% reproducible
  en paths reales (en linea con C36A -70.1% sin outlier y C36B -71.2%).
- Top edicion-win: **E4 (MCP lazy, +99.99%) + E3 (refs cache, +99.6%) + E5
  (registry memo, +99.1%)**: los tres eliminan trabajo repetido/eager en los
  paths mas calientes (cada resolucion skill/MCP) y son cambio minimo
  reversible (guard + Hashtable + memo con mtime). E10 (+98.3%) refuerza el
  mismo patron en scan-skills. E6 (+78.1%) es la cuarta confirmacion del
  fast-path ReadAllText. E7/E8 se rechazan explicitamente (pierden -195%/-24.8%);
  E2 se rechaza en caliente (dieta estatica, no runtime); E9 empate tecnico.

## Verificacion

- Harness + results solo en TEMP (`c36-clusterC/` harness.ps1 + results.txt),
  repo intacto salvo este NOTA.md nuevo (permitido).
- Parse: 6/6 OK (4 SKILL.md + build-skill-registry + scan-skills; errs=0).
  Size delta 0%.
- PROHIBIDO opencode.json directo, delete/push/commit/rm: cumplido (ningun
  acceso a opencode.json; ningun delete/push/commit/rm ejecutado; E4 sin
  probes reales — solo `Get-Module -ListAvailable` local + memo).
- Repro: `C:\Users\MK\AppData\Local\Temp\opencode\c36-clusterC\c36-clusterC-harness.ps1`.
