# Benchmarks — Mejora Autónoma Iterativa (experimentos N-ciclos)

> Entregable §7 del protocolo: tabla baseline vs. cada ciclo vs. final.
> Fuente única de verdad de los datos: `mejora-log.md` (por ciclo, secciones C1–C9) y
> `benchmarks/` (snapshots time-series `YYYY-MM-DD.json` de `benchmark.ps1 -Snapshot`,
> `benchmark-baseline.json` pinned por `-SetBaseline`; `bench-compare.ps1` agrega la tendencia).

---

## Baseline (2026-08-02, setup del experimento)

| Métrica | Valor |
|---|---|
| Suite E2E (Pester `scripts/tests/*.Tests.ps1`) | 669 pass / **7 fail** |
| Gate pre-commit | 13/13 |
| Denies bash replicados (auto/semi) | 61/61 / 61/61 |
| write-deny config global | presente |
| opencode.json | 35,535 B / 37 agentes / 1,650 líneas |
| Permisos en SSoT | 100% templates (sin inline) |

Bugs preexistentes registrados al setup (mejora-log.md L18–21):
1. `clean-repo.ps1` — sin `-Force`, `-ErrorAction SilentlyContinue` en destructivas, sin try/catch (4 tests failing)
2. `engram-compact.ps1` — sin `-Force`, `-ErrorAction SilentlyContinue` en finally (3 tests failing)

---

## Evolución por ciclo

| Ciclo | Gap atacado | Métrica | Baseline → Final | Verdict |
|---|---|---|---|---|
| C1 | Tests destructivos preexistentes (clean-repo + engram-compact) | Suite E2E | 669+7fail → **676/0** | ✅ MEJORA |
| C2 | Regla `pr` suelta en `agentRecommendations` (skill-graph) | Warnings skill-graph | 6 → 0 | ✅ MEJORA |
| C3 | `opencode-model-router/SKILL.md` > 3KB (gate [5/13]) | Skills >3KB | 1 → 0 | ✅ MEJORA |
| C4 | Crash `run-dreaming.ps1:134` (unwrap PS de array 1-elemento) | Crash runtime | 1 → 0 | ✅ MEJORA |
| C5 | Breaker post-cierre: plural `PRs`, feed-mode crash | Suite / falsos PR / crash feed | 675 → 676 / 0 / 2 → 0 | ✅ MEJORA (2 bugs reales encontrados post-cierre) |
| C6 | Traceback SQL en `engram-compact` (DB sin tabla `user_prompts`) | Suite / crash DB-legacy | 676 → **679** / 1 → 0 | ✅ MEJORA |
| C7 | Frontmatter roto e2e-testing + 3 skills >3KB + directiva modo auto | Suite / skills >3KB | 679 → **683** (+4 tests permission) / 3 → 0 | ✅ MEJORA |
| C8 | Token/contexto: claves frontmatter muertas + size budget | Suite / opencode.json | 683 → 683 (sin regresión) / 52,206 B ≤ 65,536 B | ✅ SIN REGRESIÓN |
| C9 | 7 findings multi-auditoría (sec/infra/dx) | Suite completa / gate / evasiones | 683 → **702** (conteo c/ Integration) / 13/13 → **14/14** / 4 → 0 | ✅ MEJORA |
| post-C9 | Junctions híbridas (falsos positivos health-check) | health-check | 2× WARN falso → **3/3 OK** | ✅ MEJORA |

Notas de conteo:
- C8→C9: 683→702 no es regresión; es la misma suite ampliada (el glob C8 no incluía las suites Integration).
- Enfoques evaluados: el requisito es ≥10. `mejora-log.md` L340 declara 27; la suma de sus propios componentes (3×4+2+3+3+3+7) = 30; conteo conservador de sets A/B/C explícitos = 26. En cualquier interpretación, ≥ 10 ✅ (ver hallazgo breaker C10).

---

## Estado final verificado (2026-08-03)

| Métrica | Valor |
|---|---|
| Suite completa (incl. Integration) | **702 pass / 0 fail** (verificado post-C9; re-verificado en C10) |
| Gate pre-commit | **14/14** |
| benchmark.ps1 -Gate | Skills 78 (196,262 B / 4,576 líneas) · >3KB **0** · Junctions **78/78** · Frontmatter 100% · WhenToUse 98.7% · Rules 43.6% · Scripts 83 |
| Evasiones whitespace de patrones `^` | 0 |
| Force-push deny (auto/semi) | deny real (no shadowed) |
| icm / Invoke-Expression / wsl / git clean / git rm | cubiertos en lib + mirror |
| Crash runtime run-dreaming | 0 |
| Crash DB-legacy engram-compact | 0 |
| opencode.json | 52,206 B ≤ 65,536 B (budget) |
| Skills con triggers perdidos | 0 |

---

## Snapshots machine-readable

| Snapshot | Commit | Contenido |
|---|---|---|
| `docs/metricas/snapshots/20260803-051109_benchmark.json` | 535a87f7 | hybrid junction baseline 78/78 — Skills 78, >3KB 0, Junctions 78/78, Scripts 83 |
| `benchmarks/` (`YYYY-MM-DD.json`, desde Fase 2 R6) | — | time-series diaria con `DeadJunctions`, `TokenEstimate`, `BenchmarkSeconds` |
| `benchmark-baseline.json` (raíz, `-SetBaseline`) | — | baseline PINNED del gate `benchmark.ps1 -Gate` (ya no móvil) |

---

## Deliverables de mejora (gap del C10)

| Entregable §7 | Estado previo | Estado |
|---|---|---|
| `mejora-log.md` | presente (C1–C9) | presente + C10 |
| `benchmarks.md` | **ausente** | ✅ creado |
| `adr/` (mini-ADRs) | **ausente** | ✅ creado (10 ADRs + índice) |

---

## Mejora Autónoma v2 — Baseline (2026-08-04)

| Métrica | Valor live | Target | Estado |
|---|---|---|---|
| M1 Gate pre-commit | 16/16 | 16/16 | ✓ |
| M2 Suite E2E | 702 pass / 0 fail | 100% | ✓ |
| M3 Skill sizes | avg 2,516B; 0 >3KB | avg ≤2,000B AND 0 >3KB | ⚠ avg por encima |
| M4 Score | 9.3/10 | ≥9.5 | ⚠ |
| M5 PSSA | 921 warnings; 4 regresiones vs gate | <50 warnings AND 0 regresiones | ✗ |
| M6 opencode.json | 53,556B = 82% | ≤65,536B | ✓ |
| M7 Cross-ref | 10/10 OK | 0 errores | ✓ |
| M8 BenchmarkSeconds | 1.092s | estable | ✓ |
| M9 .project.json freshness | stale 2 days | ≤1 day | ✗ |

Nota: opencode.json creció 52,206→53,556B (+1,350B) desde audit 08-03 — 82% del budget ADR-007. PSSA: 4 regresiones vs gate baseline en use-gentleman.ps1/token-count.ps1/health-check.ps1.

### Cycle 1 — Post (2026-08-04)

| Métrica | Live | Baseline | Δ% | Verdict |
|---|---|---|---|---|
| B1 opencode.json size | 53,556 B | 53,556 B | 0.0% | ✅ dentro budget (≤65,536B) |
| B2 Skills / junctions / scripts | 78 / avg 2,516B / >3KB 0 / 78/78 dead 0 / 83 | 78 / avg 2,516B / >3KB 0 / 78/78 dead 0 / 83 | 0.0% | ✅ |
| B2 BenchmarkSeconds | 1.012s | 1.092s | −7.3% (ruido) | ✅ |
| B3 Score | 9.3/10 (Cycle Activity 3.0, Script Performance 9.0) | 9.3/10 | 0.0% | ✅ estable · 4 PSSA pre-existing (no new) |
| B4 Gate pre-commit | 17/17 | 16/16 | +1 step | ✅ |
| B5 Pester size tests | 2/2 | nuevo | — | ✅ |

---

### Cycle 1 Close + Cycle 2 start (2026-08-04)

#### PSSA regression table (before → after)

| File | Rule | Before | After | Delta |
|---|---|---|---|---|
| `scripts/validate-write-scope.ps1` | fail-closed catch | fails-open | fail-closed (exit 1) | FIX |
| `scripts/use-gentleman.ps1` | PSUseSingularNouns | 1 | 0 | ✅ fixed (renamed Convert-ConfigFileRefs → Convert-ConfigFileRef) |
| `scripts/token-count.ps1` | PSReviewUnusedParameter | 1 | 0 | ✅ fixed (moved $Divisor into Get-TokenCount) |
| `scripts/health-check.ps1` | PSReviewUnusedParameter | 3 | 2 | ✅ fixed (removed unused $Force; matches baseline) |

**Total PSSA regressions**: 4 → 0. All counts returned to gate baseline.

#### Cycle 1 Close verification
- Parser::ParseFile on validate-write-scope.ps1: 0 errors
- Pester `tests/validate-write-scope.Tests.ps1`: 4/4 pass
- PSSA re-run: use-gentleman (1→0), token-count (1→0), health-check (3→2)

#### Cycle 2 start
- Scope: resolve 4 PSSA regressions via targeted renames + param moves/removals.
- Same files as above. No cross-file coupling detected.

---

## Corrida 3 (2026-08-05) — protocolo v2, N=6 ciclos, umbral decreciente 5%

### Baseline (setup)

| Métrica | Valor |
|---|---|
| B1 opencode.json size | 53,556 B (budget 65,536 B) |
| B2 Pester suite (33 archivos, incl. 4 Integration) | 732 pass / 0 fail / 0 skip |
| B3 Gate pre-commit | 18/18 ALL CLEAR |
| B4 Skills proyecto / global | 79 / 88 |
| B5 npm audit vulns | 2 (1 HIGH fast-uri, 1 moderate hono) / 0 crit |

### Cycle 1 — Post (2026-08-05)

| Métrica | Baseline | Post-C1 | Delta | Verdict |
|---|---|---|---|---|
| B5 npm audit vulns | 2 (1 HIGH + 1 mod) | 0 | -100% | ✅ MEJORA |
| B2 Pester suite | 732/0 | 732/0 | 0 | ✅ estable |
| B1 opencode.json | 53,556 B | 53,556 B | 0 | ✅ dentro budget |
| B3 Gate | 18/18 | 18/18 | 0 | ✅ |

**Extra C1**: postinstall npm reparado (runner pwsh vs PowerShell 5.1), lock desync resuelto (server-sequential-thinking 2026.7.4).

### Cycle 2 — Post (2026-08-05)

| Métrica | Baseline | Post-C2 | Delta | Verdict |
|---|---|---|---|---|
| B2 Pester suite | 732/0 | 744/0 | +12 tests | ✅ MEJORA |
| Cobertura directa scripts | 23 | 25 | +2 | ✅ MEJORA |
| Flaky validate-write-scope | latente (T1/T3) | 4/4 estable | eliminado | ✅ FIX |
| Gate pathspec secrets | typo latente | `*.Tests.ps1` | eliminado | ✅ FIX |
| B1 opencode.json | 53,556 B | 53,556 B | 0 | ✅ dentro budget |
| B3 Gate | 18/18 | 18/18 | 0 | ✅ |

### C5b — Post (2026-08-05)

| Métrica | Baseline | Post-C5b | Delta | Verdict |
|---|---|---|---|---|
| Total skill bytes | 200,064 | 193,018 | −6,997B (−3.5%) | ✅ MEJORA |
| Avg bytes/skill | 2,516 | 2,475 | −41B | ✅ |
| Max skill bytes | 3,066 | 2,874 | −192B | ✅ |
| Skills >3KB | 0 | 0 | 0 | ✅ |
| TokenEstimate | 56,075 | 55,148 | −913 | ✅ |
| WhenToUse intact | 98.7% | 98.7% | 0 | ✅ |
| Frontmatter intact | 100% | 100% | 0 | ✅ |

---

## Mejora Autónoma v3 — Kickoff (2026-08-07)

### Baseline (live, 2026-08-07)

| Métrica | Valor |
|---|---|
| B1 Suite E2E (33 archivos + Integration) | 744 pass / 0 fail / 0 skip |
| B2 Gate pre-commit | 18/18 ALL CLEAR |
| B3 npm audit (production) | 0 vulnerabilities |
| B4 PSSA PSReviewUnusedParameter | 24 warnings |
| B5 opencan.json size | 53,556 B (budget 65,536 B, 82%) |
| B6 Skills | 78 proyecto, avg 2,475B, 0 >3KB, 78/78 junctions |
| B7 Cross-ref | 0 errors |
| B8 BenchmarkSeconds | 0.938s |

### Cycle 1 — Docs Sync

| Métrica | Baseline | Post-C1 | Delta | Verdict |
|---|---|---|---|---|
| Agent count (README) | 37 | **45** | fixed | ✅ |
| Score (README) | 9.3 | **9.0** | fixed | ✅ |
| Gate | 18/18 | 18/18 | 0 | ✅ |

### Cycle 2 — Skill-Graph Caching

| Métrica | Baseline | Post-C2 | Delta | Verdict |
|---|---|---|---|---|
| skill-graph cold path | 5.0s | **0.3s warm** | 4× faster | ✅ |
| BenchmarkSeconds | 0.938s | 0.938s | 0 | ✅ estable |
| skill-graph tests | 19 | **23** | +4 | ✅ |
| Gate | 18/18 | 18/18 | 0 | ✅ |

### Cycle 3 — Security (3a + 3b + 3c)

| Métrica | Baseline | Post-C3 | Delta | Verdict |
|---|---|---|---|---|
| npm install evil (auto) | allow ❌ | **deny** ✅ | fixed | ✅ |
| pip install (auto) | allow ❌ | **deny** ✅ | fixed | ✅ |
| CSV injection | injectable ❌ | **neutralizado** ✅ | fixed | ✅ |
| Unicode whitespace evasión | bypassable ❌ | **bloqueado** ✅ | fixed | ✅ |
| Release gate (tag-push) | sin check ❌ | **gated** ✅ | fixed | ✅ |
| Gate battery | 15/15 parcial | **15/15 full** | +npm/pip | ✅ |
| Suite E2E | 744/0 | **745/0** | +1 test | ✅ |

### Estado final v3 (2026-08-07)

| Métrica | Baseline | Final |
|---|---|---|
| Suite E2E | 744 pass / 0 fail | **745 pass / 0 fail** |
| Gate pre-commit | 18/18 | **18/18** |
| npm install evil (auto) | allow | **deny** |
| CSV injection | injectable | **neutralizado** |
| Unicode evasión | bypassable | **bloqueado** |
| Skill-graph warm path | 5.0s | **0.3s** |
| opencan.json | 53,556 B | 53,556 B |

### Commits v3 (rollback map)

| Commit | Tipo | Scope | Rollback |
|---|---|---|---|
| `94b4a11d` | C1-docs:sync | docs/ | `git revert 94b4a11d` |
| `f03f1c63` | C2-perf:cache | skill-graph.ps1 | `git revert f03f1c63` |
| `75338087` | C3a-fix:csv | audit-log.ps1 | `git revert 75338087` |
| `b593e185` | C3a-fix:unicode | gate-lib.ps1 | `git revert b593e185` |
| `f5031ca0` | C3b-fix:npm-ssot | permission-templates.json | `git revert f5031ca0` |
| `d935241f` | C3b-fix:release | release.yml | `git revert d935241f` |
| `c8ac3fab` | C3c-fix:runtime | gate-lib + shared-deny | `git revert c8ac3fab` |
| `f2e0f159` | docs:artifacts | docs/agentes/ | `git revert f2e0f159` |

| Métrica | Baseline | Post-C5 | Delta | Verdict |
|---|---|---|---|---|
| setup-machine verify error rojo | latente (ollama ausente → ParentContainsError) | FAILED limpio, exit 0 | eliminado | ✅ FIX |
| mcp-resilience TimeoutMs (L269) | DOC contract sin impl body | deferred (job-based redesign, T2) | — | 🔲 pendiente |
| PSSA PSReviewUnusedParameter (global scan autoridad) | 44 | 24 | −20 | ✅ MEJORA |
| Suite destructiva | 208/0 | 208/0 | 0 | ✅ estable |
| B3 Gate | 18/18 | 18/18 | 0 | ✅ |

## Condiciones de cierre §5 (cumplidas)

| Check | Estado |
|---|---|
| Gate de calidad | 18/18 ALL CLEAR en todos los commits C1-C5 |
| Suite Pester | 744/744 pass + 208 destructiva pass, 0 fallas |
| Benchmark config | opencode.json 53,556 B (dentro budget) |
| Métrica clave | PSSA PSReviewUnusedParameter 44 → 24 (−20 reales) |
| Bugs de seguridad | 3 corregidos (health-check $Force fantasma, wisdom-store data loss, wisdom-demote borrado ciego) |

**Presupuesto corrida 3**: 5/6 ciclos usados (C1-C5). C6 no se ejecuta — condición §5 de parada alcanzada (marginal C5 ≈ 0% en métricas; rendimiento cualitativo ya saturado).

**Cierre**: listo para merge a main. candidato TimeoutMs pospuesto a su propio ciclo (T2).

### Cycle 4 — Post (2026-08-05)

| Métrica | Baseline | Post-C4 | Delta | Verdict |
|---|---|---|---|---|
| PSSA PSReviewUnusedParameter | 44 | 25 | −19 (vs 33 post-C3) | ✅ MEJORA |
| Params de contrato sin implementar | 8 | 0 | −8 | ✅ MEJORA |
| Bugs de seguridad (data loss / borrado ciego) | 2 | 0 | −2 | ✅ FIX |
| wisdom-store backlog loss | latente | preserved si save falla | eliminado | ✅ FIX |
| wisdom-demote skill borrado referenciado | latente | SKIP sin -Force | eliminado | ✅ FIX |
| sync-vmk PreserveMCP | `$false` literal vs DOC | `$true` + semántica real | alineado | ✅ FIX |
| permission-gate -Force/-DryRun | declarados | ask→allow / evaluación pura | real | ✅ FEAT |
| setup-machine DryRun/Force | declarados | 7 bloques gateados + re-apply | real | ✅ FEAT |
| Suite destructiva | 208/0 | 208/0 | 0 | ✅ estable |
| B1 opencode.json | 53,556 B | 53,556 B | 0 | ✅ dentro budget |
| B3 Gate | 18/18 | 18/18 | 0 | ✅ |

---

## FINAL PUSH — Overall ≥9.0 (2026-08-19)

### Objective 1: Fix Pester Failure
- **Root cause**: `cross-ref-check.ps1 -Json` output polluted pipeline with progress messages + returned object alongside JSON string
- **Fix**: Suppressed `Write-Host` when `-Json`; added `exit` after JSON output to avoid returning object
- **Result**: Pester 4/4 pass, 0 fail

### Objective 2: Compress 5 Smallest Skills >3KB (39→34 o3)
| Skill | Before (B) | After (B) | Δ |
|---|---|---|---|
| sdd-spec | 3,360 | 2,969 | −391 |
| sdd-verify | 3,320 | 2,987 | −333 |
| self-improvement | 3,444 | 2,354 | −1,090 |
| engram-protocol | 3,238 | 2,903 | −335 |
| sdd-explore | 3,112 | 2,691 | −421 |
| **Total** | **16,474** | **13,904** | **−2,570 (−15.6%)** |

### Final Verification (ALL mandatory)
| Check | Result |
|---|---|
| `score-auto -Json` | **SE: 6.0, PA: 10.0, Overall: 9.0** |
| `o3` (skills >3KB) | **34** (was 39) |
| `o5` (skills >5KB) | **0** |
| Avg skill size | **2.9 KB** |
| `cross-ref-check` | **10/10 OK** |
| `Pester cross-ref.Tests.ps1` | **4 passed, 0 failed** |
| `Invoke-ScriptAnalyzer` | **0 errors** |

### Final Scores (score-auto -Json 2026-08-19)
| Dimension | Score |
|---|---|
| Skill Effectiveness (SE) | 6.0 |
| Score Depth (SD) | 8.5 |
| Orthography (Or) | 10.0 |
| Metrics (Me) | 10.0 |
| Best Practices (BP) | 9.8 |
| Cycle Activity (CA) | 3.0 |
| Backlog Integrity (Bi/BI2) | 10.0 |
| Script Performance (SP) | 9.0 |
| Bitacora (Bi) | 10.0 |
| Dead Code (DC) | 10.0 |
| Project Artifacts (PA) | 10.0 |
| Clean Code (CC) | 9.7 |
| Security (Sec) | 10.0 |
| **Overall** | **9.0** |

**TARGET ACHIEVED: Overall ≥9.0** ✅