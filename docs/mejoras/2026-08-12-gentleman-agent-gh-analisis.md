# Análisis v3 — gentleman-agent-gh (Actualización 2026-08-12)

> **Protocolo**: Mejora Autónoma Iterativa v3 (`docs/protocolos/protocolo_mejora_autonoma_v3.md`)
> **Fecha**: 2026-08-12
> **Branch**: `experimento/mejora-autonoma-v3-2026-08-12` (base: main @ d0ab0137)
> **Modo**: auto (subagentes delegados con sufijo `-auto`)
> **Scope**: Project-wide (scripts/, .githooks/, .github/, opencode.json, skills/, docs/)

## 0. Setup (§0 v3)

- **Branch**: `experimento/mejora-autonoma-v3-2026-08-12` desde main @ 7868ec4a
- **Fuente de verdad de gaps**: PSSA (Invoke-ScriptAnalyzer), npm audit, git churn + LOC, cross-ref-check, score-auto, pre-commit gate, docs stale (TODOs/ADRs/BITACORA/README)
- **Jerarquía de métricas**: correctness > seguridad > performance > tamaño/legibilidad
- **Presupuesto**: máx 4 ciclos, ≤45 min por ciclo, umbral de parada: mejora marginal < 10% vs ciclo anterior
- **Entorno aislado**: Tests en Pester sandbox / pre-commit hook efímero

## 1. Baseline (§0)

Recolectado via evidence gate + scans frescos en 5 runs donde aplica:

| Métrica (M) | Baseline | Target | Fuente | Estado |
|---|---|---|---|---|
| **M1** Gate pre-commit | 22/22 ALL CLEAR | 22/22 | `.githooks/pre-commit-gate.ps1` | ✅ OK |
| **M2** npm audit (production) | 0 vulnerabilities | 0 | `npm audit --omit=dev` | ✅ OK |
| **M3** opencode.json size | 73,754 B (75%) | ≤98,304 B | `(Get-Item).Length` | ✅ OK |
| **M4** E2E Suite (Pester) | 81 tests (gate OK) | 100% pass | pre-commit [12/22] | ✅ OK |
| **M5** Skills >3KB | **7** (todas sdd-*) | 0 | skill size scan | ❌ GAP |
| **M6** Token budget (avg) | **2,631 B** | ≤2,000 B | gate [19/22] | ❌ GAP |
| **M7** Cross-ref junctions | **88 missing** (WARN) | 0 | `cross-ref-check.ps1:4` | ⚠️ |
| **M8** Score (overall) | **8.8/10** | ≥9.5 | `score-auto.ps1` | ⚠️ |
| **M13** Agent count | **49** (README said 45) | 49 | `opencode.json` | ❌ GAP (stale in README L5/L68) |
| **M9** Score Depth (SD) | 7.7/10 | ≥9.5 | `score-auto.ps1` | ⚠️ |
| **M10** Cycle Activity (CA) | 3.0/10 | improve | `score-auto.ps1` | ❌ |
| **M11** SSoT freshness | .project.json 1 day | ≤1 day | `git log` | ✅ OK |
| **M12** PSSA warnings | ~921 total | <50 | `score-auto.ps1` data | ⚠️ |

### Git churn (90 days, top 10)

```
66  BITACORA.md
57  opencode.json
39  .project.json
37  .github/workflows/quality-gate.yml
36  mejora-log.md
36  AGENTS.md
34  README.md
32  CYCLE.md
28  scripts/setup-machine.ps1
22  docs/mejoras/mejora-log.md (cumulative)
```

### Skill sizes (top 7 >3KB)

```
4366 B  - sdd-spec       (sdd-spec)
4362 B  - sdd-archive      (sdd-archive)
4259 B  - sdd-tasks        (sdd-tasks)
4234 B  - sdd-propose      (sdd-propose)
4050 B  - sdd-apply        (sdd-apply)
3918 B  - sdd-init         (sdd-init)
3578 B  - sdd-verify       (sdd-verify)
```

### Score dimensions (score-auto)

| Dim | Score | Detail |
|---|---|---|
| SG (Script Performance) | 10 | avg ≤10KB ✅ |
| Sec (Security) | 8 | some warnings |
| Or (Orchestrator) | 10 | — |
| Me (Metrics) | 10 | — |
| BI2 (Backlog Integrity) | 10 | — |
| SD (Score Depth) | 7.7 | 42 sub-dims |
| PA (?) | 8 | — |
| CC (Clean Code) | 9.9 | — |
| SE (Security detailed) | 7 | — |
| SP (Script Perf detailed) | 9 | — |
| DC (Dead Code) | 10 | 0 orphans, 0 dead junctions |
| CA (Cycle Activity) | **3** | VERY LOW |
| Bi (Bitacora) | 10 | — |
| BP (Best Practices) | 10 | — |

## 2. Findings — Gaps with ICE + Blast Radius

Cada gap originado en herramienta/evidencia concreta, con trazabilidad a negocio, blast radius y ICE score.

Fórmula ICE: Impacto(1-10) × Confianza(1-10) / Esfuerzo(1-10). Mayor = prioridad.

| # | Gap | Evidence | Impact | Conf | Effort | ICE | Blast | Business |
|---|---|---|---|---|---|---|---|---|
| **G1** | README/docs stale: skill count 78→88, score 9.0→8.8, scripts 91→102 | README.md L5/L18/L21 vs live scan | 9 | 10 | 7 | 12.9 | **Bajo** | Public KPI trust, adoption |
| **G2** | 7 sdd-* skills >3KB (3,578–4,366 B) | skill size scan, gate [5/22] | 6 | 9 | 4 | 13.5 | **Bajo** | Token overhead, gate warnings |
| **G3** | Token budget exceeded: avg 2,631 B > 2,000 B | gate [19/22] warning | 5 | 9 | 3 | 15 | **Bajo** | Session token footprint |
| **G4** | PSSA 921 total warnings | score-auto data | 3 | 9 | 5 | 5.4 | **Bajo** | Code quality, gate noise |
| **G5** | 88 skills missing global junctions | cross-ref-check WARN | 4 | 9 | 3 | 12 | **Medio** | Global mode resolution |
| **G6** | Score Depth 7.7 < 9.5 target | score-auto SD dim | 4 | 9 | 4 | 9 | **Medio** | Score granularity |

> **⚠️ Blast Radius Alto (checkpoint obligatorio)**: 7 gaps del análisis 2026-08-07 (CSV injection, npm/pip deny, permission redundancy, dual resolution, etc.) — requiren checkpoint humano. NO se implementan sin aprobación.

### Prioridad de ciclos (sin checkpoint)

| Ciclo | Gap | ICE | Blast | Plan |
|---|---|---|---|---|
| **C1** | G1: Docs sync (README/stale counts) | 12.9 | Bajo | Sync counts + score in README/SKILLS-INDEX |
| **C2** | G2: Skill size compression (7 sdd-*) | 13.5 | Bajo | Compress sdd-* SKILL.md to <3KB |
| **C3** | G3: Token budget enforcement | 15 | Bajo | Make gate fail on >2,000B avg |
| **C4** | G4: PSSA warning reduction | 5.4 | Bajo | Fix top PSSA warnings |

Gaps G5/G6 (Medium blast) deferred to post-checkpoint cycles.

## 3. Cross-reference con análisis previo (2026-08-07)

El análisis del 2026-08-07 (`docs/mejoras/2026-08-07-gentleman-agent-gh-analisis.md`) identificó 34 gaps. Los gaps DX (docs stale) del análisis previo se confirman en el baseline fresco:

- **README agent count**: 2026-08-07 decía "37 vs 45 real" → README actual dice "45" ✅ (actualizado en Ciclo 10 v2)
- **README skill count**: 2026-08-07 decía "78 skills" → sigue "78" pero real es 88 ❌ (NO actualizado)
- **README score**: 2026-08-07 decía "9.0 vs .project.json 9.0" → README dice 9.0, .project.json dice 8.8 ❌
- **README scripts**: 2026-08-07 no mencionaba scripts → README dice "91", real es 102 ❌

El gap de docs stale (G1) es **confirmado y actualizado** con nuevas discrepancias adicionales.

## 4. Engagement / Ciclos v3

| Ciclo | Gap | Estado | Resultado |
|---|---|---|---|
| 1 | G1: Docs sync | 🔴 Pending | Sync README/SKILLS-INDEX counts + score |
| 2 | G2: Skill compression | 🔴 Pending | Compress 7 sdd-* skills >3KB |
| 3 | G3: Token budget | 🔴 Pending | Enforce avg ≤2,000B in gate |
| 4 | G4: PSSA warnings | 🔴 Pending | Reduce PSSA warnings |

**Engram Persistence**: `analysis/gentleman-agent-gh/v3-2026-08-12` · confidence: high

