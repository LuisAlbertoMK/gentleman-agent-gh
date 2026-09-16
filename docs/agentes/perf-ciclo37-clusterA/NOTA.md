# Ciclo 37 — Cluster A: aplicar 10 top-wins PS validados en C33-C36 (SOLO PS)

Fecha: 2026-09-15. Env: pwsh 7.6.6 Win32NT. Metodo: aplicar + verificar (no
re-experimentar). Plan 02 ausente — se uso el Goal como plan (sin desvio,
replica C36-clusterA). Cambios minimos reversibles en 3 archivos; 5 archivos
ya traian el win aplicado en worktree (solo verificados, 0 toques).
PROHIBIDO delete/push/commit/rm: cumplido. No se toco opencode.json, cmd/,
skills. Worktree ya venia sucio de otros clusters — no se revirtio trabajo
ajeno; los hunks propios estan comentados `perf-ciclo37-clusterA`.

SkillOpt: 8/8 archivos parse OK (0 errores), size delta propio <1% por archivo.

## Tabla 10 aplicados (file:line, antes/después, keep/revert)

| # | Win (origen) | Archivo:linea | Antes | Después | Veredicto |
|---|--------------|---------------|-------|---------|-----------|
| 1 | E7 memo manifestDir (C35A/E7) | scripts/sync-n-projects.ps1:130 (nuevo `$manifestDir` hoisted) | `Split-Path` por bloque (`$addPath`, dedup, loop) | 1 cálculo, 3 reusos | KEEP |
| 2 | E8 path precomputado (C35A/E8) | scripts/sync-n-projects.ps1:266-268 (fallback loop usa `$manifestDir`) | `Join-Path (Split-Path $manifestPath -Parent)` por proyecto (~139.24ms x50) | `Join-Path $manifestDir` (~83.06ms x50, mismo N) | KEEP (-40% micro) |
| 3 | E9 Quiet bulk (C35A/E9) | scripts/sync-n-projects.ps1:282-286 (`if ($Quiet) { $null = & ... }`) | hijo `use-gentleman` emite por proyecto aun con `-Quiet` (no tiene param Quiet propio: verificado use-gentleman.ps1:44-52) | con `-Quiet` se silencia por proyecto; resumen final ya era `-not $Quiet` | KEEP |
| 4 | E7 short-circuit IsOSPlatform (C33/E7) | scripts/lib/platform.ps1:23-41 | ya completo en worktree (Windows 1 llamada; Linux 1 + OSX guardada por `-not $IsLinux`) | sin cambio — verificado, parse 0 | KEEP (verificado) |
| 5 | E1/E9 timeout 300→60 (C36A/E1, C34/E9) | scripts/score-auto.ps1:201 | `Wait-Job -Timeout 300` (peor-caso 300s por PSSA colgado) | `Wait-Job -Timeout 60` (jobs rapidos: empate tecnico C36A/E1) | KEEP |
| 6 | E4 Dispose anti-leak (C36A/E4) | scripts/inter-track.ps1:78-80 (init `$reader/$writer`) + :98-103 (Dispose) | `finally { Close solo }`; `$reader/$writer` sin Dispose (fuga +2.94MB/60 runspaces en C36A/E4) | Dispose writer+reader, Close+Dispose stream; lock `FileShare::None` intacto; Pester 16/16 PASS | KEEP |
| 7 | E10 regex precompilada + early-exit (C34B/E10) | scripts/validate-write-scope.ps1:100-102,137-138 | ya aplicado en worktree (`$runtimeFilesRe` combinada, `$compiledPatterns` + `$matchAll`) | sin cambio — smoke `'*' → CLEAN 14/14 exit 0`, parse 0 | KEEP (verificado) |
| 8 | E09 batch + hoist Get-Location (C34B/E09) | scripts/check-token-budget.ps1:85-87,94 | ya aplicado (2 foreach conteo, `$locPrefix` hoisted) | sin cambio — smoke `-Json passed=True exit 0` (warning Depth pre-existente, lateral C34B) | KEEP (verificado) |
| 9 | E08 literales -eq (C34B/E08) | scripts/delegation-fit-gate.ps1:88-91 | ya aplicado (4x `-eq`) | sin cambio — smoke quick/1 PASS exit 0, quick/93 FAIL exit 2 | KEEP (verificado) |
| 10 | E2 ReadAllText + E1 single-pass (C36A/E2, C33/E1) | scripts/cross-ref-check.ps1:47 (`ReadAllText`), :206-213 (config_refs mismo pass) | ya aplicado | sin cambio — parse 0 | KEEP (verificado) |

Reverts: 0/10. Ningún aplicado regresó (parse 8/8, smokes PASS, Pester 16/16).

## Parse antes → después (ms, 1 run c/u — ruido JIT, solo anti-regresión)

| Archivo | Antes | Después |
|---------|-------|---------|
| sync-n-projects.ps1 | 83.35 | 25.00 |
| lib/platform.ps1 | 2.47 | 4.05 |
| score-auto.ps1 | 24.57 | 28.10 |
| inter-track.ps1 | 3.36 | 4.23 |
| validate-write-scope.ps1 | 2.31 | 4.45 |
| check-token-budget.ps1 | 2.64 | 3.27 |
| delegation-fit-gate.ps1 | 2.18 | 2.65 |
| cross-ref-check.ps1 | 5.59 | 5.59 |

Suma: ~126.47 → ~77.34 (delta = cache/JIT, no claim de win; el win real es el
micro del loop -40% + peor-caso timeout 300s→60s + anti-leak Dispose).

## Delta total + top edicion-win

- Micro loop sync (única medida patronal con N fijo): 139.24 → 83.06ms x50
  (-40.3%). Timeout: peor-caso 300s → 60s (caso feliz intacto). Dispose:
  corrección (fuga contenida, sin costo medible; Pester 16/16 lo cubre).
- Top edicion-win aplicado: **E8 path precomputado + E7 memo (mismo hunk,
  path real fallback sin binario) + E1 timeout 60 (peor-caso)**. Verificados
  que más pesan sin tocar: E10 validate-scope (peor caso `*` → 0 loops),
  E09 token-budget (N-1 `Get-Location`), ReadAllText (fast-path x95 skills).

## Verificación

- Parse: 8/8 OK antes y después (errs=0).
- Smoke: delegation-fit-gate PASS/FAIL idénticos; validate-write-scope `*`
  CLEAN 14/14 exit 0; check-token-budget `-Json` passed=True exit 0.
- Pester scripts/tests/inter-track.Tests.ps1: 16/16 PASS (backup/restore
  intacto; `.learnings/` limpio en `git status`).
- score-auto/sync-n-projects NO ejecutados end-to-end (escriben cache,
  history, proyectos) — verificación por parse + grep + micro-patrón.
- Repro patrón: `(Measure-Command { $d = Split-Path 'D:/gentleman-agent-gh/projects.json' -Parent; 1..50 | ForEach-Object { if ([IO.Path]::IsPathRooted('x')) { 'a' } else { Join-Path $d 'x' } } }).TotalMilliseconds`
- Rollback (si hiciera falta): `git diff` hunks marcados `perf-ciclo37-clusterA`
  en sync-n-projects.ps1, score-auto.ps1, inter-track.ps1 — revert por hunk,
  0 dependencias cruzadas.
