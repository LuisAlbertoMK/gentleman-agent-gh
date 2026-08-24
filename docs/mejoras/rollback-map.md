# Rollback Map — Plan Auto-Mejora v3 (2026-08-13)

Branch: `experimento/mejora-autonoma-2026-08-13`
Base: `main` HEAD `0d88467c`

## Commits on this branch

| Commit | Mensaje | Rollback |
|--------|---------|----------|
| `0d80b1a3` | feat: CI quality gate validates opencode.json schema + ConfigValidator module | `git revert 0d80b1a3` — elimina `.github/workflows/ci.yml`, `scripts/lib/ConfigValidator.psm1`, `scripts/tests/config-validator.Tests.ps1`, revierte `ANTI-PATTERN-CATALOG.md` |
| `f6e7016d` | test(sync): add full-agent sync tests + ADR-029 | `git revert f6e7016d` — elimina `scripts/tests/sync-vmk-full-agents.Tests.ps1`, `adr/ADR-029-sync-vmk-full-agent-sync.md` |
| `a35fb543` | fix(sync): register gentle-orchestrator in config pipeline for full agent sync | `git revert a35fb543` — restaura 49 agents (orch + sdd-* removidos de SSoT) |
| `a378b36d` | fix(scripts): preserve single-element arrays in JSON serialization | `git revert a378b36d` — restaura ConvertTo-Json sin json-utils.ps1, sync-vmk.sin use-gentleman.sin deep-clone bug |
| `2e966e0b` | chore: benchmark baseline mediana/IQR/count=10 | No rollback needed — baseline stats only, no code change |

## Per-cycle rollback (for surgical revert)

### Cycle 1 (G1) — `a378b36d`
- **Revert**: `git revert a378b36d` → elimina `scripts/lib/json-utils.ps1`, revierte `scripts/sync-vmk.ps1` y `scripts/use-gentleman.ps1` a ConvertTo-Json original (con array unwrapping bug)
- **Impact**: tests json-utils fallarán (8 expected failures), pero no afecta a otros cycles
- **No regresión**: el bug de array unwrapping ya existía antes → rollback es seguro

### Cycle 2 (G3) — `a35fb543` + `f6e7016d`
- **Revert**: `git revert f6e7016d a35fb543` (orden: tests primero, luego SSoT)
- **Impact**: elimina `gentle-orchestrator` de opencode-base.json, generate-opencode-config.js, agent-overrides.json, opencode.json; restaura 49 agents
- **No regresión**: la config vuelve a su estado base (39 gentleman agents, sin orch)

### Cycle 3 (G2) — `0d80b1a3`
- **Revert**: `git revert 0d80b1a3`
- **Impact**: elimina `.github/workflows/ci.yml` (nueva), `scripts/lib/ConfigValidator.psm1`, `scripts/tests/config-validator.Tests.ps1`, revierte `ANTI-PATTERN-CATALOG.md`
- **Coexistencia**: `ci.yml` coexiste con `quality-gate.yml` + `release.yml` existentes — revert no afecta workflows preexistentes

## Full rollback to base

```bash
git reset --hard 0d88467c  # main HEAD, base de este experimento
# Confirmar: opencap.json = 37 agents (estado base), 0 cambios en working tree
```

## Scope verification

All 5 commits are on `experimento/mejora-autonoma-2026-08-13` only. `main` is untouched (HEAD = `0d88467c`). To verify:
```bash
git log --oneline 0d88467c..experimento/mejora-autonoma-2026-08-13  # 5 commits
git merge-base --is-ancestor 0d88467c main && echo "main clean"
```

---

## Branch: `experimento/mini-orchestrator-async`

- **Base**: main HEAD `b90458fb`
- **Scope**: async fire-and-forget delegation (BabyAGI pattern foundation)
- **Files**: `scripts/post-delegation-check.ps1` (modify), `scripts/monitor-subagent.ps1` (new), `tests/post-delegation-async.Tests.ps1` (new), `.agents/skills/mini-orchestrator/SKILL.md` (new), `adr/ADR-031-*` (new), `SKILLS-INDEX.md` (count 88→89)

### Commits
| Commit | Mensaje | Rollback |
|--------|---------|----------|
| (pending) | feat(mini-orchestrator): async fire-and-forget delegation | `git checkout -- scripts/post-delegation-check.ps1` (reverts mod) + `git rm -f scripts/monitor-subagent.ps1 tests/post-delegation-async.Tests.ps1 .agents/skills/mini-orchestrator/SKILL.md adr/ADR-031-mini-orchestrator-async-delegation.md` + restore SKILLS-INDEX.md to 88 |

### Rollback completo (surgical, no afecta otros branches)
```bash
git checkout -- scripts/post-delegation-check.ps1 SKILLS-INDEX.md
git rm -f scripts/monitor-subagent.ps1 tests/post-delegation-async.Tests.ps1
git rm -f .agents/skills/mini-orchestrator/SKILL.md
git rm -f adr/ADR-031-mini-orchestrator-async-delegation.md
# Remove global junction
rm /d "%USERPROFILE%\.config\opencode\skills\mini-orchestrator"
# Remove async-result.json artifacts
del HEAD.async-result.json
```

---

## Branch: experimento/mini-orchestrator-loop (Phases 2-3)

- **Base**: commit Phase 1 `256d338c` en `experimento/mini-orchestrator-async`
- **Scope**: BabyAGI loop + self-improvement trigger (supercedes Phase 1 branch)
- **Files**: `scripts/babyagi-loop.ps1` (new), `tests/babyagi-loop.Tests.ps1` (new), `scripts/auto-improve.ps1` (new), `tests/auto-improve.Tests.ps1` (new), `SKILL.md` (modified, v1.1->1.2), `mejora-log.md` (Phase 2+3 entries)

### Commits
| Commit | Mensaje | Rollback |
|--------|---------|----------|
| `ae22138c` | feat(mini-orchestrator): async + babyagi loop (Phase 1+2 combined) | `git revert ae22138c` |
| `127eec5b` | feat(auto-improve): self-improvement trigger (Phase 3) | `git revert 127eec5b` |

### Rollback completo
```bash
git reset --hard main  # main is at b90458fb; this branch has 2 commits ahead
# OR surgical:
git revert 127eec5b  # Phase 3 only
git revert ae22138c  # Phase 1+2 only
```

---

*Generated: 2026-08-13 · Protocol: plan-auto-mejora-v3 §4 (rollback map)*

---

## Branch: `experimento/mejora-autonoma-2026-08-18` (CI Quality Hardening, v3)

- **Base**: main HEAD `31134225`
- **Scope**: G1-G3 del plan v3 — robust Pester runner, coverage gate, mutation smoke, adversarial review estructurado (ADR-032)
- **Execution**: commits hechos en worktree aislado `C:\Users\MK\AppData\Local\Temp\opencode\gentleman-exp-2026-08-18` (sesión paralela `agente-aem-migration` en worktree principal — archivos ajenos NO tocados)
- **Gate**: 22/22 ALL CLEAR en cada commit

### Commits

| Commit | Mensaje | Rollback |
|--------|---------|----------|
| `e3bec66b` | feat(ci): robust Pester runner (R3) + fix pre-existing babyagi-loop safety gaps | `git revert e3bec66b` — elimina `scripts/run-ci-tests.ps1`, `scripts/tests/ci-pester.Tests.ps1`; revierte `ci.yml` job tests, `babyagi-loop.ps1`, `benchmark-baseline.json` |
| `c966c4bc` | feat(ci): coverage gate + mutation smoke (R2+R4, G2) | `git revert c966c4bc` — elimina `scripts/tests/Coverage.ps1`, `mutation-smoke.Tests.ps1`, `Coverage.Tests.ps1`; revierte `ci.yml` job coverage |
| `2719837c` | feat(ci): structured adversarial review with severity (R1, G3) | `git revert 2719837c` — elimina `scripts/adversarial-review.ps1`, `scripts/tests/adversarial-review.Tests.ps1` |
| `(HEAD — último commit de la branch, docs)` | docs(mejora): v3 deliverables — ADR-032, mejora-log, benchmarks, rollback-map | `git revert (HEAD — último commit de la branch, docs)` — revierte docs (ADR-032, mejora-log append, benchmarks, este archivo) |

### Rollback completo (full)
```bash
git reset --hard 31134225  # main HEAD, base del experimento
```

### Rollback quirúrgico por ciclo
```bash
git revert (HEAD — último commit de la branch, docs)        # docs only (opcional — sin código)
git revert 2719837c        # Ciclo 3 (adversarial review)
git revert c966c4bc        # Ciclo 2 (coverage gate + mutation)
git revert e3bec66b        # Ciclo 1 (Pester runner)
```

### Scope verification
```bash
git log --oneline 31134225..experimento/mejora-autonoma-2026-08-18  # 4 commits
git merge-base --is-ancestor 31134225 main && echo "main clean"
```

---

# Rollback Map - Plan Auto-Mejora v3 (2026-08-20)

Branch: `experimento/mejora-autonoma-2026-08-20` · Base: `main` HEAD `33425647`

| Commit | Mensaje | Rollback |
|--------|---------|----------|
| `37c4573a` | fix(validation): discard git stderr in check-subagent-output | `git revert 37c4573a` - restaura filtro 2>&1 (reintroduce bug silent-failure) y tests no-hermeticos |
| `e1ab1b27` | feat(gate): add docs/mejoras index freshness check | `git revert e1ab1b27` - elimina scripts/mejoras-index-check.ps1, tests/mejoras-index-check.Tests.ps1, revierte README.md y docs/mejoras/README.md |
| `5f65013e` | fix(validation): treat git diff failure as fatal | `git revert 5f65013e` - elimina check $LASTEXITCODE y T5 (BaseRef invalido vuelve a OK silencioso) |

### Per-cycle rollback
- **Ciclo 1 (G1)**: `git revert 5f65013e 37c4573a` (orden: fatal-check primero, luego stderr) - valida que T1 vuelva a fallar como en baseline
- **Ciclo 2 (G2)**: `git revert e1ab1b27` - autocontenido, no afecta Ciclo 1

---

# Rollback Map - Ciclo 30 (2026-08-20)

Branch: `experimento/mejora-autonoma-2026-08-20-c30` | Base: `main` HEAD `85176d54`

| Commit | Mensaje | Rollback |
|--------|---------|----------|
| `bd707b76` | fix(gate): strip GIT_* env before running staged Pester suites | `git revert bd707b76` - reintroduce vector de corrupcion (fixtures bajo gate tocan repo real) |
| `ea617cde` | feat(validation): add -AgentOutputFile to check-subagent-output | `git revert ea617cde` - elimina transporte por archivo y hardening de fixtures (tests vuelven a ser fragiles bajo gate) |
| `e8121588` | feat(monitor): wire C4d contract validation into async delegation | `git revert e8121588` - async-result.json pierde contract_*; T6-T8 fallan |
| `013e4577` | feat(monitor): expose contract_ran in async-result.json | `git revert 013e4577` - consumidores pierden senal explicita not-evaluated |

### Per-cycle rollback
- **Ciclo 30 completo**: `git revert 013e4577 e8121588 ea617cde bd707b76` (orden inverso) - vuelve al comportamiento pre-C4d del monitor; docs/mejoras/2026-08-15 deja de estar implementado en async

---

# Rollback Map - Ciclo 2026-08-24

Branch: `experimento/mejora-autonoma-2026-08-24` | Base: `main` HEAD `da90e1b0`

| Commit | Mensaje | Rollback |
|--------|---------|----------|
| `66d14670` | docs(mejoras): rename analyses with domain keywords + fix stale cross-references | `git revert 66d14670` - restaura filenames homogeneos y stale refs; los 9 archivos vuelven a su nombre YYYY-MM-DD-gentleman-agent-gh-analisis.md |
| `d0f5b0a4` | fix(monitor): scope-filter stability signal + resilience tests for async gaps | `git revert d0f5b0a4` - convergencia vuelve a resetearse con commits externos fuera de scope; async-resilience.Tests.ps1 eliminado |

### Per-cycle rollback
- **Ciclo completo**: `git revert d0f5b0a4 66d14670` (orden inverso). Ciclos independientes: docs (Ciclo 1) y code+tests (Ciclo 2) no se solapan.
