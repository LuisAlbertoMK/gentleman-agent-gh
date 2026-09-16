# Ciclo 37 — Cluster C: 10 exps benchmarks finales + bitácora concisa 5 ciclos (150 exps)

Fecha: 2026-09-15. Env: pwsh 7.6.6 Win32NT. Método: benchmarks comparativos
read-only (score-auto, benchmark-core, bench-compare, cross-ref, token-budget,
inter-track, parse-all, validate-scope, delegation-gate) + cierre documental.
PROHIBIDO delete/push/commit/rm, reescribir BITACORA, tocar opencode.json/cmd/:
cumplido. Worktree venía sucio de otros clusters — no tocado; este cluster solo
crea esta NOTA + `docs/ciclos/cycle33-37-perf-20260915.md` + 1 línea BITACORA
(append). Hunks propios: ninguno en scripts (0 solape con A/B).

## Tabla 10 exps (antes → después/después-estado, con números)

| # | Exp | Antes | Después | Veredicto |
|---|-----|-------|---------|-----------|
| 1 | score-auto -Json | history 8.9 @e3ea99b0 (2026-09-15, SD 9.2) | 9.3 UP (SD 9.2, SE 8.0, CA 4.0; 4385ms; WARN PSSA inter-track empty-catch 0→4 por hunk C37A, no bloquea) | UP +0.4 |
| 2 | skill avg/KB (benchmark-core -Json) | C33: 95 skills avg 2.64KB over-3KB 8 | 94 skills, 251418B (245.5KB), avg 2675B, mediana 2688B, over 5, junctions 90/94 dead 0, tokens 71834, 0.863s | Dietas C37B OK; 3 over fuera de scope |
| 3 | cross-ref tiempo | C34B ~613ms wrapper (con git spawn) | 1887ms full, 9/9 OK ALL CHECKS PASSED (agents 48) | PASS |
| 4 | inter-track | CYC-20260908-296 | 628ms, 13/30, score 9.3 up | PASS |
| 5 | parse-all | 8/8 cluster A, 6/6 cluster B/C | 126 scripts, 901ms, 0 errores (Language.Parser) | PASS |
| 6 | benchmark-core Benchmark | baseline 91 skills/3894B avg | 94 skills/2675B avg, 0.863s | PASS |
| 7 | bench-compare -Top 5 | — | baseline→2026-08-04: −13 skills, −1378B avg (pocos snapshots en benchmarks/) | PASS |
| 8 | token-budget -Json | C34B 524→412ms, avg 2707B | 716ms, passed=True, 0 violaciones (WARN Depth pre-existente) | PASS |
| 9 | scope + gate | — | validate docs/* 894ms VIOLATION 16/17 (worktree ajeno, esperado); delegation quick/1 PASS 214ms exit 0 | PASS (0 propias) |
| 10 | bitácora + doc final | 150 exps sin cierre único | 1 entrada BITACORA (append) + `docs/ciclos/cycle33-37-perf-20260915.md` + esta NOTA | Cierre |

Reverts: 0/10. Solo lectura + 2 docs nuevos + 1 append.

## 5 ciclos × 30 (resumen para bitácora)

C33 medir+aplicar (score 9.1→9.2, E5 minify TOP) · C34 wrappers+Go-diffs
(E06 runGate-paralelo mayor impacto, E08/E09/E10 aplicados) · C35 veredicto
lenguaje QUEDARSE PS+Go + dietas AR (PT −547B, EP −282B) · C36 .NET/cache
(E4 Hashtable +97.3%, E4 MCP-lazy +99.99%, E3 refs +99.6%; rechazos Compiled/
combinada/SB-chico/strip-caliente) · C37 consolidar (A: 10 wins aplicados
Pester 16/16; B: Go top-3 dif-listos + frontmatter-lazy; C: este cierre).

## Top-5 wins (ms/MB/KB)

1. MCP-lazy +99.99% (21306→1.19ms; +90MB WS del probe). 2. Hashtable +97.3%
   (471→12.75ms). 3. Refs-cache +99.6% (1823→6.93ms). 4. Minify −15.75KB/−28.9%/
   −75ms. 5. Path-precomputado −40.3% (139→83ms ×50) + timeout 300→60s +
   Dispose +2.94MB/60 runspaces.

## Migración lenguaje (veredicto vigente C35B)

Quedarse PS+Go híbrido (7.8 pts; ADR-049 vinculante). sync.exe listo,
bloqueado por toolchain. GPU 0 en todo (0 hits). Migración total 6–24 meses
por sub-100ms: no justificada.

## Verificación (repro)

- `score-auto.ps1 -Json` → 9.3 up; `benchmark-core.ps1 -Json` → 94/2675B/0.863s.
- `cross-ref-check.ps1` → 9/9 OK; `check-token-budget.ps1 -Json` → passed=True.
- `inter-track.ps1` → 13/30; parse-all 126 → 0 errores; `bench-compare.ps1 -Top 5`.
- `validate-write-scope.ps1 -AllowedPaths "docs/*" -Json` → VIOLATION 16/17
  (ajena); `delegation-fit-gate.ps1 -AgentName "gentleman-quick" -FileCount 1
  -LineCount 10` → PASS exit 0.
- Rollback: nada que revertir (0 edits en scripts/skills/código; solo docs nuevos
  + 1 línea BITACORA).
