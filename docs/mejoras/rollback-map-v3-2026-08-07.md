# Rollback Map — v3 Kickoff (2026-08-07)

> Mapeo commit↔ciclo↔gap para rollback quirúrgico (v3 §4.1)
> Cada ciclo puede revertirse de forma aislada via `git revert <commit-range>`

## Ciclo 1 — Docs Sync (Blast: Bajo)

| Gap | Commit | Archivos | `git revert` |
|---|---|---|---|
| README stale (37→45 agents, score 9.3→9.0) | `94b4a11d` | README.md, QUICKSTART.md, PROTOCOL.md, docs/ARCHITECTURE.md, docs/CHANGELOG.md, docs/CONTRIBUTING.md, .archive/docs/plan-v3-2026-08-07.md, docs/mejoras/2026-08-07-v3-baseline-34-gaps.md | `git revert 94b4a11d` |

## Ciclo 2 — Skill-Graph Caching (Blast: Alto-impact)

| Gap | Commit | Archivos | `git revert` |
|---|---|---|---|
| No caching (5s cold) | `f03f1c63` | scripts/skill-graph.ps1, scripts/tests/skill-graph.Tests.ps1 | `git revert f03f1c63` |

## Ciclo 3a — CSV Injection + Unicode Whitespace (Alto)

| Gap | Commit | Archivos | `git revert` |
|---|---|---|---|
| CSV Formula Injection (CWE-1236) | `75338087` | scripts/audit-log.ps1, scripts/tests/audit-log.Tests.ps1 | `git revert 75338087` |
| Unicode Whitespace Evasion (CWE-1389) | `b593e185` | scripts/lib/permission-gate-lib.ps1, scripts/tests/permission-gate.Tests.ps1 | `git revert b593e185` |

## Ciclo 3b — SSoT npm/pip Deny + Release Gate (Alto)

| Gap | Commit | Archivos | `git revert` |
|---|---|---|---|
| npm/pip deny floor (SSoT) | `f5031ca0` | scripts/lib/permission-templates.json, opencan.json | `git revert f5031ca0` |
| Release bypass (tag-push sin gate) | `d935241f` | .github/workflows/release.yml | `git revert d935241f` |

## Ciclo 3c — Runtime Gate + shared-deny-rules (Alto)

| Gap | Commit | Archivos | `git revert` |
|---|---|---|---|
| Runtime gate npm/pip deny | `c8ac3fab` | scripts/lib/permission-gate-lib.ps1, scripts/opencode-config/shared-deny-rules.json, scripts/tests/permission-gate.Tests.ps1 | `git revert c8ac3fab` |

## Ciclo 3d — Execution Artifacts

| Commit | Archivos | `git revert` |
|---|---|---|
| `f2e0f159` | docs/agentes/docs-v3-kickoff/, docs/agentes/security-c3a/, docs/agentes/security-C3b/ | `git revert f2e0f159` |

## Cycle #3 v3 — Gap D: Benchmark Fixture (Blast: Bajo)

| Gap | Commit | Archivos | `git revert` |
|---|---|---|---|
| Gap D: benchmark context mismatch (orchestrator vs subagent) → false +97.4% regression | `1b7a2c92` | `scripts/tests/fixtures/generate-config-latency-baseline.json`, `scripts/tests/generate-config.Tests.ps1` (R9 test) | `git revert 1b7a2c92` |

> **Gap D fix**: Created machine-readable fixture with pinned median+IQR baseline. The R9 Pester test measures both baseline AND comparison in the SAME execution context (test process), 5 runs, median — eliminates the cross-context mismatch that caused false positives in Cycle #1.

## Cycle #4 v3 — PSSA Clean Code (Blast: Bajo)

| Gap | Commit | Archivos | `git revert` |
|---|---|---|---|
| PSSA PSAvoidDefaultValueSwitchParameter — 5 `[switch]$Json = $true` defaults | `d1496bfe` | `scripts/auto-pattern-detector.ps1`, `scripts/learning-stats.ps1`, `scripts/pattern-guard.ps1`, `scripts/wisdom-loader.ps1`, `scripts/wisdom-stats.ps1`, `scripts/lib/score-dims.ps1` | `git revert d1496bfe` |

> **Fix**: Changed `[switch]$Json = $true` → `[bool]$Json = $true` in 5 scripts (JSON output stays default-true, now PSSA-clean). Updated `score-dims.ps1` Tool-Hygiene regex to also match `[bool]$Json`. PSSA 5→0. Score tests 36/36.

## Full rollback (all v3)

```bash
git revert 1b7a2c92 f2e0f159 c8ac3fab f03f1c63 94b4a11d d935241f f5031ca0 b593e185 75338087
# (reverse order of application for cleanest state)
# v3 cycles: 1b7a2c92=C3 Gap D fixture · d1496bfe=C4 PSSA 5 → 0 · 4519466f=C2 H2 fix
```
