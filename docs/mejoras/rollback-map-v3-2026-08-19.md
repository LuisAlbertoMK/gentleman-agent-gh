# Rollback Map — v3 Automejora (2026-08-19)

> Mapeo commit↔ciclo↔gap para rollback quirúrgico (v3 §4.1)
> Rama: `experimento/mejora-autonoma-2026-08-19`

## Commits

| Commit | Cycle | Descripción | Blast | Archivos clave |
|--------|-------|-------------|-------|----------------|
| 2f961acf | ADR-033 | Semi mode deprecated (auto fallback in switch-mode + permission-gate) | Low | AGENTS.md, opencode.json, scripts/lib/permission-gate-lib.ps1 |
| ac018d2e | C1b | PS5.1/PS7 dual compatibility (lower #requires, gentleman-vmk.bat, ps5-compat tests) | Low | 9 scripts + gentleman-vmk.bat + 12 ps5-compat tests + ADR-039 |
| be68af5f | C1 | Cross-ref integrity + test suite + ADR-034 | Low | ADR-034, cross-ref.Tests.ps1, .gitignore, analysis + plan docs |
| dea1b340 | C1-fix | .gitignore exclusions for C1 artifacts | Trivial | .gitignore |
| 6ac91d70 | C2 | 22 skills >5KB → <5KB via karpathy-loop + reference.md + ADR-035 | Alto | 22 SKILL.md + 22 reference.md + ADR-035 + benchmarks + mejora-log |
| 2a6e3cc1 | C3 | Config budget: opencodec.json 89.7%→63.6% + ADR-036 | Alto | opencode.json, ADR-036, benchmarks, mejora-log |
| 3b74f791 | C4+C5 | CmdletBinding/ShouldProcess + PSSA CI + coverage gate + ADR-037/038 | Med | 5 scripts, PSScriptAnalyzerSettings.psd1, ci.yml, ADR-037/038, benchmarks, mejora-log |
| b4400ff3 | - | .project.json metrics update post-verification | Trivial | .project.json |

## Full rollback (reverse order of application)

```bash
git revert --no-edit b4400ff3 3b74f791 2a6e3cc1 6ac91d70 dea1b340 be68af5f ac018d2e 2f961acf
```

## Notas de rollback por ciclo

### C2 (6ac91d70) — Skill bloat compression
- Revierte 22 SKILL.md a estado original (>5KB)
- Elimina 22 `docs/skills/<skill>/reference.md` creados
- SE vuelve de 7.0 → 6.0
- ADR-035 puede conservarse como documentación histórica

### C3 (2a6e3cc1) — Config budget trim
- Revierte opencode.json: restaura 6 semi agents + 2 MCP servers (headroom, chrome-devtools-mcp) + tools disables
- Requiere reiniciar junction de aem-migration si fue afectada
- ADR-036 conserva el análisis

### C4+C5 (3b74f791) — PowerShell quality
- Remueve [CmdletBinding(SupportsShouldProcess)] de 5 scripts
- Elimina PSScriptAnalyzerSettings.psd1
- Revierte CI: remueve coverage-gate job, restaura pssa-lint job original
- ADR-037/038 conservan el análisis

### C1b (ac018d2e) — PS5.1/PS7 compat
- Revierte #requires de PS7 a PS5.1/7 dual en 9 scripts
- Elimina gentleman-vmk.bat
- Elimina scripts/tests/ps5-compat.Tests.ps1

## Score history

| Estado | SE | PA | Overall | Fuente |
|--------|----|----|---------|--------|
| Baseline | 6.0 | 8.0 | 7.0 | score-auto baseline |
| +C2 | 7.0 | 8.0 | ~8.0 | 22 skills comprimidos, o5: 22→0 |
| +C3 | 7.0 | 8.0 | ~8.0 | Config 89.7%→63.6% |
| +C4+C5 | 7.0 | 8.5 | 8.9 | PA+0.5, Overall+0.9 (según mejora-log) |
