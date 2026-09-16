# Ciclo 34 — Cluster A: cache / memoización / I-O batch (SOLO PS)

Fecha: 2026-09-15. Env: pwsh 7.6.6, Win32. Método: harness aislado en Temp
(`c34-harness.ps1`), sin modificar repo (0 bytes delta). Cada exp: 3-run
Measure-Command + tamaño KB. Plan base C33: single-pass 43-84%, List.Add 57%,
reusar csvRaw 68%.

SkillOpt: 7/7 archivos parse OK (0 errores), size delta 0% (≤20% OK, sin cambios aplicados).

## Tabla 10 experimentos

| ID | Hipótesis | Base (ms avg 3-run) | Opt (ms avg 3-run) | Δ | KB fixture | Veredicto |
|----|-----------|---------------------|--------------------|---|------------|-----------|
| E1 | historia: `-Tail 1` gana a full-read | 33.29 (full) | 15.98 (tail) | +52.0% | 34.18 (500 líneas) | ADOPTAR tail+append |
| E2 | memo score-dims por hash/mtime gana a re-read | 37.86 (20 scripts re-read) | 7.77 (memo-hit) | +79.5% | 146.97 | ADOPTAR (mejor elección) |
| E3 | `[IO.File]::ReadAllText` gana a `Get-Content -Raw` x20 | 24.82 | 12.49 | +49.7% | 5.10 | ADOPTAR en batch caliente |
| E4 | `List.Add` gana a `+=` (C33 57%) | 16.13 (`+=`, N=2000) | 54.85 (List, N=2000) | -240% | 0 | NO ADOPTAR ciego — re-verif N=5000: `+=` 70-101ms vs List 157-167ms, `+=` gana en este rango/env |
| E5 | single-pass foreach gana a 4x Where (C33 43-84%) | 519.96 (4x Where, N=5000) | 22.14 (single-pass) | +95.7% | 0 | ADOPTAR (mayor Δ absoluto) |
| E6 | reusar split gana a re-split (C33 68%) | 9.34 (re-split x10) | 7.76 (reusar x10) | +16.9% | 5.08 | ADOPTAR (Δ menor por fixture chico; gratis) |
| E7 | inter-track FileStream lock-read vs Get+Set | 29.54 (Get+Set c/write) | 20.99 (lock-read s/write) | +28.9% lectura | 0.11 | MANTENER lock actual — lock-read no escribe; no cambiar sin contención medida |
| E8 | lazy PSSA (skip) gana a ThreadJob | 194.27 (ThreadJob+50ms sleep) | 9.45 (skip) | +95.1% | 0 | ADOPTAR lazy: PSSA solo en cache-miss (ya existe guard PESTER_TEST) |
| E9 | jobs timeout 60s = 300s en jobs rápidos | 49.71 (timeout 300) | 44.48 (timeout 60) | +10.5% / empate técnico | 0 | ADOPTAR 60s por seguridad (igual perf, menor peor-caso) |
| E10 | `Add-Content` append gana a rewrite | 30.92 (rewrite 500 líneas) | 12.05 (append) | +61.0% | 34.18 | ADOPTAR append (ya es el patrón actual) |

Notas honestas:
- E4 contradice C33 en este entorno: con warmup y N=2000/5000, `+=` supera a
  `List[string].Add` (-65% a -240%). Hipótesis: costo fijo de genéricos + interpolación
  domina a N chico; el O(n²) de `+=` solo muerde a N mayor. Recomendación: no
  reescribir loops existentes; para listas grandes usar `List` con capacidad
  pre-asignada o `AddRange`, y medir en el call-site real antes de tocar.
- E9 es empate técnico (±5ms ruido de ThreadJob); el valor de 60s es acotar
  peor-caso, no acelerar caso feliz.
- E7 compara lectura contra lectura+escritura: no es apples-to-apples; el lock
  FileStream se mantiene por corrección (carrera read-modify-write), no por velocidad.

## Cambios mínimos reversibles propuestos (NO aplicados — solo medidos)

1. score-auto.ps1 cache-hit: ya usa `-Tail 1` + `Add-Content` (E1/E10 confirman, nada que cambiar).
2. score-dims.ps1: extender `$scriptContentCache`/`$skillContentCache` con clave
   mtime+size para hits inter-proceso (E2: -79.5%). Reversible: borrar hashtable.
3. Batch reads calientes: `[IO.File]::ReadAllText` en CC/BP (E3: -49.7%). Reversible: volver a `Get-Content -Raw`.
4. Mantener single-pass E9/E5/E4 (ya aplicado en C33): `manifest split`, `CC counters`, `SE counters` (E5: -95.7%).
5. Lazy PSSA: generalizar el guard `PESTER_TEST` a "cache-hit ⇒ skip pssa-gate" (E8: -95.1%).
6. Jobs `Wait-Job -Timeout 300 → 60` (E9: empate, menor peor-caso).
7. inter-track.ps1: mantener `Invoke-TrackLocked` FileStream (E7: corrección > Δ).

## Mejor elección

**E2 (memo score-dims por hash/mtime) + E5 (single-pass) + E8 (lazy PSSA)**:
son los tres de mayor Δ reproducible (79.5% / 95.7% / 95.1%) y tocan los paths
más calientes (cada invocación de score-auto). E1/E10 confirman que el patrón
actual de historia ya es óptimo. E4 se rechaza explícitamente en este ciclo.

## Verificación

- `c34-harness.ps1` 3-run por exp (ver tabla). Harness + fixtures solo en
  `%TEMP%\c34-clusterA` (results.json/txt), repo intacto.
- Parse: 7/7 OK (score-auto 21.58KB, score-dims 26.49KB, inter-track 8.77KB,
  json-utils 0.61KB, template-detection 6.36KB, cross-ref-check 13.10KB,
  benchmark-core 24.52KB). Size delta 0%.
- PROHIBIDO delete/push/commit/rm: cumplido (solo append de este NOTA.md;
  `history.jsonl` no tocado por script, `git status` worktree ya sucio pre-sesión).
