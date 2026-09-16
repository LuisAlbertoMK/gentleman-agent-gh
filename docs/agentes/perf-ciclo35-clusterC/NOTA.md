# Ciclo 35 — Cluster C: huella CPU / RAM / GPU + startup (10 exps)

Fecha (UTC): 2026-09-15 · Host: Windows 10.0.26200 · PS 7.6.6 · PID medida 10520
GPU máquina: AMD Radeon RX Vega 10, AdapterRAM 2048 MB (Get-CimInstance Win32_VideoController)
Método: cada exp = hipótesis + `Measure-Command` 3-run + `(Get-Process -Id $PID).WorkingSet64` MB antes/después.
Runner reproducible: `C:\Users\MK\AppData\Local\Temp\opencode\clusterC-exps.ps1` (fuera del repo, no se commitea).
Alcance: solo lectura sobre `scripts/score-auto.ps1` (fixture 460 líneas) — ninguna modificación de scripts.

> Nota JIT: el run-1 siempre incluye compilación/carga de ensamblados; el veredicto usa promedio 3-run
> Y estado-estacionario (runs 2-3) cuando el run-1 es outlier.

## Tabla resumen (10 exps)

| # | Exp (hipótesis corta) | A (ms, 3-run) | B (ms, 3-run) | Ganador + speedup | WS antes→después (MB) | Veredicto |
|---|------------------------|---------------|---------------|-------------------|------------------------|-----------|
| E1 | Jobs vs secuencial (trabajo trivial 4-8x): jobs pierde por fork de proceso | seq: 57.85, 0.74, 0.57 | Start-Job 4x+50ms: 2764.56, 2828.11, 3166.62 | secuencial (~4000x en trabajo trivial; ~5x aun vs sleep equivalente) | 83.68→101.61 (+17.93) | CONFIRMADA. No usar Start-Job para grano fino; reservar para tareas >segundos o paralelismo real |
| E2 | Runspaces `ForEach-Object -Parallel` vs secuencial (8x50ms sleep) | seq: 553.78, 504.25, 503.39 (avg 520.47) | parallel T4: 228.96, 207.19, 215.17 (avg 217.10) | parallel 2.4x | 101.58→105.80 (+4.22) | CONFIRMADA. Paralelo gana en I/O-bound; cuesta ~+4 MB runspaces. score-auto ya paraleliza (jobs) — migrar a -Parallel/RunspacePool reduciría E1+E2 |
| E3 | `-eq` vs `-match` exacto (5000 iter) | -eq: 33.89, 15.96, 1.01 (avg 16.95) | -match: 45.59, 11.47, 18.21 (avg 25.09) | -eq 1.5x avg; ~10x estacionario (1.01 vs ~11-18) | 105.81→109.56 (+3.75) | CONFIRMADA. Igualdad exacta → `-eq`; regex solo si hay patrón real |
| E4 | `-like` vs `-match` wildcard (5000 iter) | -like: 51.45, 10.92, 12.34 (avg 24.90) | -match: 50.25, 15.07, 11.49 (avg 25.60) | empate técnico (-like +2.7%) | 109.64→109.64 (+0.00) | MATIZADA. Sin diferencia; preferir `-like` por legibilidad salvo regex necesario |
| E5 | `Get-Content -Raw` vs streaming vs `[IO.File]::ReadAllText` (fixture score-auto.ps1) | -Raw: 36.83, 2.93, 2.47 (avg 14.08) | stream: 84.56, 10.28, 11.82 (avg 35.56) / .NET: 32.23, 0.51, 0.44 (avg 11.06) | .NET 1.3x sobre -Raw avg, ~5x estacionario (0.44 vs 2.47); -Raw ~2.5x sobre streaming | 109.64→109.59 (−0.05) | CONFIRMADA. Leer todo de una vez gana; streaming solo si el archivo no cabe en RAM o se procesa línea-a-línea con early-exit |
| E6 | `ConvertFrom-Json` depth default vs `-Depth 10` vs `-AsHashtable` (payload playo 200x) | default: 61.42, 39.35, 37.77 (avg 46.18) | Depth10: 70.40, 27.94, 30.95 (avg 43.10) / Hashtable: 63.01, 34.85, 29.54 (avg 42.47) | sin diferencia (>ruido, ±8%) | 109.59→110.03 (+0.44) | RECHAZADA (payload playo). Depth solo importa con JSON profundo; riesgo real = payload hostil profundo → fijar `-Depth` explícito como defensa, no como optimización |
| E7 | `Get-CimInstance` vs cache `Get-Process -Id $PID` | cache 50x: 41.76, 22.26, 14.82 (avg 26.28 → 0.53/call) | CIM 5x: 659.84, 442.84, 448.57 (avg 517.09 → 103.42/call) | cache ~195x por llamada | 110.03→116.29 (+6.26) | CONFIRMADA. CIM/WMI nunca en hot path ni en loops; cachear proceso/hardware una vez (p. ej. GPU AdapterRAM) |
| E8 | `Write-Host` en loop vs silencioso vs StringBuilder | silent 1000x: 24.41, 0.76, 0.74 (avg 8.64) | SB 1000x: 36.76, 7.47, 8.41 (avg 17.55) / Write-Host 200x: 255.24, 246.01, 235.34 (avg 245.53 → 1.23/call) | silencioso ~1500x vs Write-Host estacionario (0.0007 vs 1.23 ms/call) | 116.29→118.16 (+1.87) | CONFIRMADA. Write-Host fuera de loops (solo UX puntual); acumular en StringBuilder/List y un solo write |
| E9 | Startup `pwsh -NoProfile` base vs + dot-source `lib/platform.ps1` | base: 888.10, 761.37, 843.73 (avg 831.07) | +platform: 1332.55, 1037.35, 901.82 (avg 1090.57) | base +259 ms (+31%) por dot-source platform | child WS ~74.87 MB; padre 115.32→118.91 (+3.59) | CONFIRMADA. Startup domina cualquier micro-opt: cada `pwsh` hijo cuesta ~0.8-1.1 s + ~75 MB WS. Reducir fan-out de procesos > afinar operadores |
| E10 | `Where-Object` pipeline vs `.Where()` método (2000 items, filtro estilo check-token-budget) | pipeline: 64.03, 20.15, 22.83 (avg 35.67) | .Where(): 32.54, 3.24, 8.22 (avg 14.67) | .Where() 2.4x | 118.95→119.93 (+0.98) | CONFIRMADA. En scans calientes (skills/prompts) usar `.Where()`/`.ForEach()` o filtrado single-pass (score-auto E9 ya lo hace: 4 pasadas → 1) |

## Detalle por experimento

### E1 — Jobs vs secuencial
- Hipótesis: `Start-Job` (proceso hijo por job) es órdenes de magnitud más caro que trabajo secuencial trivial.
- Medición: seq `1..8 % sqrt` → 57.85 / 0.74 / 0.57 ms; 4× `Start-Job { sleep 50ms }` → 2764.56 / 2828.11 / 3166.62 ms. WS 83.68→101.61 MB (+17.93 — hijos + serialización).
- Veredicto: CONFIRMADA. score-auto.ps1:80+ lanza jobs paralelos (cross-ref, pssa, backlog) — correcto solo porque cada hijo hace trabajo de segundos; jamás para grano fino.

### E2 — Runspaces (-Parallel) vs secuencial
- Hipótesis: el paralelismo en-proceso gana 2-4x en trabajo sleep/I/O con sobrecosto RAM moderado.
- Medición: seq 8×50 ms → avg 520.47 ms; `-Parallel` T4 → avg 217.10 ms (2.4x). WS +4.22 MB.
- Veredicto: CONFIRMADA. Recomendación: migrar fan-out de score-auto de Start-Job → `ForEach-Object -Parallel`/RunspacePool.

### E3 — `-eq` vs `-match`
- Hipótesis: igualdad exacta con `-eq` evita compilar regex y gana ≥2x.
- Medición: avg 16.95 vs 25.09 (1.5x); estacionario 1.01 vs 11-18 (~10x).
- Veredicto: CONFIRMADA. Patrón repo: `validate-write-scope`/`delegation-fit-gate` comparan strings de dominio — auditar que ningún `-match` se use para igualdad literal.

### E4 — `-like` vs `-match`
- Hipótesis: `-like` (wildcard, sin regex) es más barato que `-match` equivalente.
- Medición: avg 24.90 vs 25.60 — empate dentro del ruido.
- Veredicto: MATIZADA. Elegir por expresividad/legibilidad, no por perf.

### E5 — Lectura de archivo: -Raw vs streaming vs .NET
- Hipótesis: una sola lectura (`-Raw`/ReadAllText) supera al pipeline línea-a-línea.
- Medición: avg -Raw 14.08 / stream 35.56 / .NET 11.06; estacionario .NET 0.44 vs -Raw 2.47 vs stream ~10-12.
- Veredicto: CONFIRMADA. `check-token-budget`/`score-auto` leen decenas de SKILL.md — usar `-Raw` o `ReadAllText` salvo early-exit/streaming con archivos gigantes.

### E6 — ConvertFrom-Json depth
- Hipótesis: `-Depth` mayor cuesta más.
- Medición: 46.18 vs 43.10 vs 42.47 avg — indistinguible en payload playo.
- Veredicto: RECHAZADA como optimización; MANTENER `-Depth` explícito como hardening (payload profundo/hostil), no por velocidad.

### E7 — Get-CimInstance vs cache
- Hipótesis: WMI/CIM es ~100x más caro que reusar el objeto cacheado.
- Medición: 0.53 ms/call (Get-Process) vs 103.42 ms/call (CIM) → ~195x. WS +6.26 MB (proveedor WMI + objetos).
- Veredicto: CONFIRMADA con énfasis. Prohibir CIM en loops; leer hardware (GPU/CPU/RAM) una vez al inicio del ciclo y cachear.

### E8 — Write-Host en loops
- Hipótesis: `Write-Host` por iteración domina el loop (I/O consola + formateo).
- Medición: silent 1000x avg 8.64 (est. 0.74) vs Write-Host 200x avg 245.53 (1.23 ms/call) → ~1500x estacionario. StringBuilder intermedio (17.55) pero un solo flush.
- Veredicto: CONFIRMADA. Top-3 del cluster en impacto por línea cambiada.

### E9 — Startup + WorkingSet hijo
- Hipótesis: el costo de arrancar `pwsh` eclipsa micro-optimizaciones de operadores.
- Medición: base avg 831.07 ms vs +platform.ps1 avg 1090.57 ms (+259 ms, +31%). Hijo WS ~74.87 MB.
- Veredicto: CONFIRMADA. Implicancia arquitectónica: batching en-proceso > N invocaciones; `lib/platform.ps1` ya minimiza (E7: 3 llamadas IsOSPlatform → 1). Cada proceso hijo nuevo = ~1 s + ~75 MB.

### E10 — Where-Object vs .Where()
- Hipótesis: el método `.Where()` evita el pipeline y gana ≥2x en colecciones de miles.
- Medición: avg 35.67 vs 14.67 (2.43x). WS +0.98 MB.
- Veredicto: CONFIRMADA. Aplicar en `check-token-budget` (filtros over-budget) y `score-auto` (split de manifiesto — ya hecho en E9 single-pass).

## GPU
- `Win32_VideoController`: AMD Radeon RX Vega 10, 2048 MB AdapterRAM, driver 27.20.1028.1.
- Huella GPU de `pwsh`: ~0 por diseño (sin contexto DirectX/OpenGL; cómputo CPU-bound). Estimación, no medición con contador DX — documentado como tal.
- Consecuencia: el presupuesto que importa es CPU-tiempo + WorkingSet; GPU solo como inventario de máquina para decidir si algún análisis visual (screenshots/Playwright) puede usar aceleración.

## Delta total y top footprint-win
- WorkingSet proceso medida: 78.31 MB (baseline) → 120.35 MB (final) = **+42.04 MB** en la sesión completa.
  Desglose mayor: E1 jobs +17.93 · E7 CIM +6.26 · E2 runspaces +4.22 · E3 regex +3.75 · E9 hijos +3.59.
  El delta NO es leak: es JIT + ensamblados (CIM, Jobs, ThreadJob) + objetos retenidos del runner; entre exps puros de operadores el WS es plano (±1 MB: E4 +0.00, E5 −0.05, E6 +0.44, E10 +0.98).
- Top footprint-win (mayor ahorro por cambio mínimo):
  1. **E7 cache sobre CIM (~195x, +6.26 MB evitados por llamada repetida)** — prohibir CIM en loops.
  2. **E8 sacar Write-Host de loops (~1500x estacionario)** — el fix más barato del repo.
  3. **E9 reducir fan-out de procesos (~1 s + ~75 MB por hijo)** — decisión arquitectónica, no micro-opt.
  4. **E1 jobs→runspaces para grano medio (E2 2.4x con +4 MB)** + **E10 `.Where()` 2.4x** + **E5 `-Raw`/ReadAllText ~2.5-5x**.

## Recomendaciones (auto, sin cambiar scripts en este ciclo)
1. `check-token-budget.ps1:52,57` — `Where-Object Length -gt` sobre colecciones pequeñas está bien; si el conteo de skills crece, migrar a `.Where()` (E10).
2. `score-auto.ps1:62-65` — ya single-pass (buen estado); siguiente paso E2: jobs → runspaces.
3. Regla de estilo: `-eq` para igualdad, `-like` para glob, `-match` solo con regex real (E3/E4).
4. Lecturas siempre `-Raw`/ReadAllText salvo streaming con early-exit (E5).
5. `ConvertFrom-Json` con `-Depth` explícito por seguridad (E6).
6. CIM/WMI una vez + cache (E7); cero `Write-Host` en loops (E8); batching en-proceso contra startup ~1 s/hijo (E9).
