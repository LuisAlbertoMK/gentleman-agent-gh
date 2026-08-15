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

*Generated: 2026-08-13 · Protocol: plan-auto-mejora-v3 §4 (rollback map)*
