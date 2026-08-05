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
