# Plan: Auto-Mejora Autónoma v3 — 2026-08-19

**Protocol**: `docs/protocolos/protocolo_mejora_autonoma_v3.md`
**Proyecto**: gentleman-agent-gh · **Stack**: PowerShell 7.6+ (scripts/tests), JavaScript (analysis), OpenCode runtime, Engram MCP
**Base**: `2f961acf` (post-ADR-033) · **Branch**: `experimento/mejora-autonoma-2026-08-19`
**Presupuesto**: 5 ciclos · 25 tool calls/ciclo · modelos free-tier
**Escalado**: correctness > security > performance > size (§0.6)
**Escala ICE**: Impacto 1-10 × Confianza 1-10 × Esfuerzo⁻¹ (10 = mínimo esfuerzo). Prioridad = I×C×E.

### Herramientas del stack
| Función | Comando/herramienta |
|---|---|
| Test runner | `pwsh -NoProfile -File scripts/run-ci-tests.ps1` (Pester 5.5.0 pin) |
| Linter | `pssa-gate.ps1` (PSScriptAnalyzer) |
| Build/compile | N/A (PowerShell + JS scripts, no compiled source) |
| Benchmark | `pwsh scripts/sync-vmk.ps1 -DryRun` ×5, `benchmark-baseline.json` |
| Escaneo de vulnerabilidades | `npm audit`, `check-adversarial.ps1` (pre-commit gate) |

### Baseline estadístico (§0.7) — 10 runs, mediana/IQR
| Métrica | Valor |
|---|---|
| Pester suite | ~136 pass / 6 fail (62 test files total) |
| npm audit | 0 vulnerabilities |
| opencodec.json size | 58,626 B (89.7% of 65,536 B budget) |
| sync-vmk -DryRun | 1263 ms median, IQR 66 ms (Q1 1249, Q3 1314) |
| Composite score | 8.8/10 (trend: up) |
| Skills >3KB | 57 (was 8 on 08-13) |
| Skills >5KB | 21 |
| Avg skill bytes | 3,900+ B (was 2,762 on 08-13) |

### Estado de tests baseline (§3.5)
- **Baseline actual (2f961acf)**: ~136 pass / 6 fail (sampled 4 files) · 62 test files total
- **Root cause de fails preexistentes**: 4 fails en `permission-gate.Tests.ps1` (documented en mejora-log.md), 2 fails en `mode-gate.Integration.Tests.ps1` (documented)
- **DoD target**: 0 NEW failures. Fails preexistentes se verifican como no-regresión vía `git diff` de archivos de test.

### Entorno aislado (§0.9)
Todo ciclo corre en worktree efímero o subagent aislado. Branch `experimento/mejora-autonoma-2026-08-19`. Backup git bundle: `C:/Users/MK/AppData/Local/Temp/opencode/gentleman-backup-20260819-*.bundle` (55MB).

---

## 0. Evidencia de Gaps (10 gaps, §0.4)

Ver `docs/mejoras/2026-08-19-async-delegation-analysis.md` §4 para detalle completo. Resumen:

| Gap | Evidencia | I×C×E | Blast | Business |
|---|---|---|---|---|
| G1 | opencodec.json 58,626B/65,536B (89.7%) — `Get-Item`, ADR-007 | **405** | **Alto** | Config integrity gate; deploy risk |
| G2 | 57 skills >3KB, 21 >5KB, avg 3.9KB (SE=6.0) — `.project.json` | **243** | **Alto** | Token budget; quality gate |
| G3 | cross-ref FALSE (PA=8.0) — `cross-ref-check.ps1:355` | **288** | Medio | Project artifacts integrity |
| G4 | No PS coverage gate — `Coverage.ps1`, gate has no threshold | **135** | Medio | Test completeness unmeasurable |
| G5 | No PSScriptAnalyzer in CI — `pssa-gate.ps1` exists but unused | **216** | Bajo | No code quality auto-enforcement |
| G6 | 14+ scripts no SupportsShouldProcess — Pester WARN output | **192** | Bajo | Safety for destructive scripts |
| G7 | score-dims.ps1 742 lines — complexity scan | **108** | Medio | Single point of failure for scoring |
| G8 | 104 scripts missing [CmdletBinding] — complexity scan | **72** | Bajo | Clean Code; PSSA noise |
| G9 | docs/archivos mover/ unprocessed artifacts — git status | **180** | Bajo | Workflow hygiene |
| G11 | Score 9.3→8.8 regression — `.project.json` | **144** | **Alto** | CYCLE.md target: 9.3→9.5 |

**CHECKPOINT HUMANO OBLIGATORIO (§1.3 — Blast Alto)**: G1, G2, G11. G1 depends on C1+C2 cleanup.

---

## Cycle Priority & Grouping

| Cycle | Gap | ICE | Blast | 3 Enfoques |
|---|---|---|---|---|
| **C1** | G3 (Cross-ref) | 288 | Medio | A: Fix broken refs · B: Add xref test · C: SKILLS-INDEX drift |
| **C2** | G2 (Skill bloat) | 243 | Alto | A: Karpathy compress >5KB · B: Externalize refs · C: Split monolithic |
| **C3** | G1 (Config budget) | 405 | **Alto** | A: Remove semi-agents · B: $import externalize · C: Size budget test |
| **C4** | G6+G8 (Cmdlet/Safe) | 264 | Bajo | A: Bulk [CmdletBinding] · B: Bulk ShouldProcess · C: PSSA verify |
| **C5** | G5+G4 (PSSA CI + Cover) | 351 | Medio | A: Install PSSA CI · B: Coverage threshold · C: Publish coverage.xml |

**Order**: C1 → C2 → C3 (checkpoint) → C4 → C5. G7, G9, G11 → follow-up (next session).

---

## C1 — G3: Cross-ref integrity (ICE 288, Blast: Medio)

### Scope Lock
```
IN:  scripts/cross-ref-check.ps1 (fix broken refs)
     scripts/tests/cross-ref.Tests.ps1 (nuevo: Pester test for xref integrity)
     SKILLS-INDEX.md (fix drift vs .agents/skills/)
     .agents/skills/*/SKILL.md (fix broken ## Cross-Refs entries ONLY)
OUT: todo lo demás
```

### 3 Enfoques
| Enfoque | Descripción | Pros | Contras |
|---|---|---|---|
| **A** (Fix broken refs) | Parse cross-ref-check output, fix each broken ref (skill name typos, missing deps) | Directo, measurable | Requires identifying all broken refs |
| **B** (Add xref test) | Pester test que ejecuta cross-ref-check.ps1 -Json y falla si errors > 0 | Preventive, CI gate | New test file + mock data |
| **C** (SKILLS-INDEX drift) | Reconcile SKILLS-INDEX.md con .agents/skills/ real directory | Fixes index accuracy | Index is large, might have many diffs |

### Ganador esperado
**A+B** — fix refs primero (unblocks PA dimension), luego test preventivo (C3 depends on C1).

### DoD
- [ ] cross-ref-check.ps1 -Json returns 0 errors
- [ ] cross-ref.Tests.ps1 3/3 pass (no broken refs, errors=0, warnings tracked)
- [ ] Gate local 22/22
- [ ] PA dimension: cross_ref = true in .project.json
- [ ] Score no regresivo

---

## C2 — G2: Skill bloat compression (ICE 243, Blast: Alto)

### Scope Lock
```
IN:  .agents/skills/*/SKILL.md (largest 21 only, >5KB)
     .agents/skills/*/reference.md (create for externalized content)
     scripts/lib/karpathy-loop.ps1 (compressor pattern)
OUT: scripts/, opencodec.json, AGENTS.md
```

### 3 Enfoques
| Enfoque | Descripción | Pros | Contras |
|---|---|---|---|
| **A** (Karpathy compress >5KB) | Progressive token compression: cut → measure → cut again | Largest impact first (21 skills) | May lose detail |
| **B** (Externalize refs) | Move examples/references to docs/skills/*/reference.md (ADR-007 pattern) | Preserves content, reduces skill size | New files, cross-ref risk |
| **C** (Split monolithic) | Split skills with >5KB into focused sub-skills | Modular, maintainable | Architecture change, cross-file |

### Ganador esperado
**A** — karpathy compress >5KB skills first (biggest bang), then **B** for >3KB.

### DoD
- [ ] 0 skills >5KB (was 21)
- [ ] ≤10 skills >3KB (was 57)
- [ ] SE dimension ≥ 7.5
- [ ] cross-ref-check still 0 errors (C1 result maintained)
- [ ] Pester 0 NEW failures

---

## C3 — G1: Config budget (ICE 405, Blast: **Alto**) — CHECKPOINT HUMANO

### Scope Lock
```
IN:  opencodec.json (user-applied; agent can suggest edits to scripts/lib/opencodec-base.json)
     scripts/lib/opencodec-base.json (template SSoT)
     scripts/opencode-config/semi-agents.json (remove semi entries)
     scripts/tests/opencode.json-size.Tests.ps1 (add size assertion)
OUT: opencodec.json direct edits (REQUIRES USER APPLY — see ADR-033)
```

### 3 Enfoques
| Enfoque | Descripción | Pros | Contras |
|---|---|---|---|
| **A** (Remove semi-agents) | Delete 6 `-semi` agent entries + permission blocks from template | -600 lines, ADR-033 | Requires user apply to global opencodec.json |
| **B** ($import externalize) | Use $import in opencodec.json for repeated permission blocks | DRY, future-proof | Requires expand-config.ps1 support |
| **C** (Size budget test) | Pester test asserting opencodec.json ≤ 65,536 B | Prevents future regressions | Testing-only, doesn't fix current state |

### Ganador esperado
**A+C** — remove semi-agents (ADR-033 follow-up) + add budget test. **CHECKPOINT HUMANO** required before user applies changes to opencodec.json.

### DoD
- [ ] Scripts/opencodec-base.json: ≤ 60,000 B
- [ ] opencodec.json-size.Tests.ps1: enforces 65,536 B limit
- [ ] ADR-034 written (config budget follow-up to ADR-033)
- [ ] User approval documented (checkpoint humano)
- [ ] Score no regresivo

---

## C4 — G6+G8: CmdletBinding + ShouldProcess (ICE 264, Blast: Bajo)

### Scope Lock
```
IN:  scripts/*.ps1 (top 20 by churn: BITACORA.md, AGENTS.md, .project.json, CYCLE.md, SKILLS-INDEX.md, opencodec.json, README.md, skill-graph.ps1, score-auto.ps1, quality-gate.yml)
     scripts/lib/*.ps1 (high-churn library files)
OUT: .agents/skills/, docs/, tests/
```

### 3 Enfoques
| Enfoque | Descripción | Pros | Contras |
|---|---|---|---|
| **A** (Bulk CmdletBinding) | Script that adds [CmdletBinding()] to 104 scripts missing it | Systematic, one-time | Risk of syntax issues in existing scripts |
| **B** (Bulk ShouldProcess) | Add [CmdletBinding(SupportsShouldProcess)] to 14 destructive scripts | Safety improvement | Changes behavior (prompts) |
| **C** (PSSA verify) | Run PSSA after changes, fix violations | Ensures quality | Additional iteration |

### Ganador esperado
**A** — add [CmdletBinding()] to all 104 scripts via generator script, then **B** for destructive scripts.

### DoD
- [ ] 0 scripts with param() missing [CmdletBinding]
- [ ] 0 scripts with destructive ops missing SupportsShouldProcess
- [ ] PSSA: PSReviewUnusedParameter 44→0 (or tracked)
- [ ] Pester: 0 NEW failures

---

## C5 — G5+G4: PSScriptAnalyzer CI + Coverage (ICE 351, Blast: Medio)

### Scope Lock
```
IN:  .github/workflows/quality-gate.yml (add PSSA + coverage steps)
     scripts/pssa-gate.ps1 (wire into pre-commit)
     scripts/tests/Coverage.ps1 (add threshold gate)
OUT: .agents/skills/, scripts/lib/score-dims.ps1
```

### 3 Enfoques
| Enfoque | Descripción | Pros | Contras |
|---|---|---|---|
| **A** (Install PSSA in CI) | Add PSScriptAnalyzer to quality-gate.yml workflow | Enforces code quality | CI time + config |
| **B** (Coverage threshold) | Add -CodeCoverage + MinimumCoverage 20 to Coverage.ps1 | Prevents coverage regressions | PowerShell coverage is partial |
| **C** (Publish coverage.xml) | Publish JaCoCo coverage.xml as CI artifact | Visibility + trend tracking | Artifact storage |

### Ganador esperado
**A+B+C** — install PSSA, add coverage threshold, publish results. Combined maximum enforcement.

### DoD
- [ ] quality-gate.yml: PSSA step passing
- [ ] Coverage.ps1: -MinimumCoverage 20 enforced
- [ ] coverage.xml published as artifact
- [ ] Pester: 0 NEW failures

---

## Verificación Final & DoD Global (§3.8)

| Check | Method | Status |
|-------|--------|--------|
| Tests: 0 NEW failures | Pester before/after diff | Pendiente |
| Benchmark no regresivo | sync-vmk ×5 mediana/IQR vs 1263ms/IQR66 | Pendiente |
| 0 new critical/high vulns | npm audit + check-adversarial | Pendiente |
| ADRs escritos | adr/ADR-034..ADR-038 | Pendiente |
| Commits dentro de scope | validate-write-scope.ps1 | Pendiente |
| Rollback map con hashes | docs/mejoras/rollback-map.md | Pendiente |
| Score ≥ 9.0 | score-auto.ps1 | Pendiente |

## Deliverables
```
docs/mejoras/2026-08-19-async-delegation-analysis.md  ← ✅ DONE (this analysis)
docs/mejoras/plan-auto-mejora-v3-2026-08-19.md          ← THIS FILE
docs/mejoras/mejora-log.md                              ← append C1-C5
docs/mejoras/benchmarks.md                              ← baseline vs final table
docs/mejoras/rollback-map-v3-2026-08-19.md              ← commit ↔ ciclo
adr/ADR-034-cross-ref-integrity.md                      ← C1
adr/ADR-035-skill-bloat-compression.md                ← C2
adr/ADR-036-config-budget.md                          ← C3 (checkpoint humano)
adr/ADR-037-cmdletbinding-shouldprocess.md            ← C4
adr/ADR-038-pssa-ci-coverage.md                       ← C5
```

## Rollback Map
```
# Cada ciclo commiteado por separado → revertible vía git revert --no-commit
C1: refactor(tools): fix cross-ref integrity → revert C1
C2: chore(skills): karpathy compress skills >5KB → revert C2
C3: chore(config): remove semi-agents + budget test → revert C3 (checkpoint humano)
C4: chore(scripts): add CmdletBinding + ShouldProcess → revert C4
C5: feat(ci): add PSSA + coverage gate → revert C5
```

---
*Protocolo: docs/protocolos/protocolo_mejora_autonoma_v3.md · Fecha: 2026-08-19*
