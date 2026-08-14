# Automejora Analysis — gentleman-agent-gh — 2026-08-13

> **Protocol**: protocolo_mejora_autonoma_v3.md §0-§1 · **Mode**: read-only · **Tier**: T3
> **Scope**: repo-root `D:/gentleman-agent-gh` (branch `experimento/mejora-autonoma-2026-08-13` @ HEAD `153eb322`) · **confidence: high** (tool-backed)

## 0. Project Complexity Profile (PCI)

| Signal | Value | Level |
|---|---|---|
| S1 File count | 483 source files (after exclusions) | 3 (100–499) |
| S2 Language diversity | 8 (JavaScript, JSON, Markdown, Other, PowerShell, Shell, TOML, YAML) | 4 (≥5) |
| S3 Tests + coverage | 50 test files (45 unit + 5 integration), **no coverage** | 2 (tests, no coverage) |
| S4 CI/CD | `.github/workflows` (3 files: ci.yml, quality-gate.yml, release.yml) | 4 (2+ workflows) |
| S5 Dep manifest | 1 (package.json) | 2 |

**Tier**: T3 — runs: PCI + capability probe + evidence scan + test baseline ×3 + linter audit + security audit + cross-service probe + git churn top-10 · skips: IaC scan, data pipeline audit, adversarial breaker, full 8-dim gap-analysis

## 1. Evidence Sources Available (capability matrix)

| Capability | Available | Tool(s) | confidence |
|---|---|---|---|
| test-runner | yes | Pester, pytest, go, dotnet | high |
| linter | no / SKIPPED | degrades to grep-based complexity scan | high |
| security-audit | yes | npm (0 vulnerabilities) | high |
| performance | no / SKIPPED | — | high |
| build | yes | go build, dotnet build (not invoked — no Go/.NET source) | high |
| coverage | yes (Python only) | pytest-cov (no PowerShell coverage tool detected) | high |
| ci-config | yes | ci-config (.github/workflows) | high |

**Probe methods**: `scripts/analyze-automejora.ps1 -Path . -Json` (PCI + capabilities); `npm audit --json` (security); static file scan via `ctx_execute` sandbox (LOC, churn, complexity); `git log --name-only --since` (churn); `fs.statSync` (config sizes); `.project.json` `dimensions_detail` (score state).

## 2. Baseline (§0.7) — real runs only, median/IQR

| Metric | Baseline (median / IQR) | Runs | Source | confidence |
|---|---|---|---|---|
| M1 Pester suite | 669 pass / 7 fail | 1 (documented) | `plan-auto-mejora-v3-2026-08-13.md:42`; mejora-log.md:41 | high |
| M2 npm audit vulnerabilities | 0 (0 low / 0 mod / 0 high / 0 crit) | 1 | `npm audit --json` → `vulnerabilities:{}`, `metadata.vulnerabilities.total:0` | high |
| M3 opencan.json size | 75,577 bytes (115% of 65,536 budget) | 1 | `fs.statSync('opencan.json').size` | high |
| M4 sync-vmk benchmark | 139.7 ms (IQR 40.7) | 10 | `benchmark-baseline.json:stats` (Median=139.7, Q1=122.6, Q3=163.3, IQR=40.7, Count=10) | high |
| M5 avg skill bytes | 2,762 B (89 skills) | 1 | `fs.readdirSync('.agents/skills')` + statSync | high |
| M6 score | 8.7 / 10 (trend: down) | 1 | `.project.json:score.current=8.7, score.trend="down"` | high |

**Pester 3-run baseline limitation**: The Pester suite could not be timed in 3 separate runs — `Invoke-Pester` output contains Unicode progress symbols (✔/✗) that crash the sandboxed `pwsh -EncodedCommand` runner (CLIXML parser error: "term not recognized as a name of a cmdlet"). The documented pass/fail baseline (669 pass / 7 fail, pre-existing in `destructive-scripts.Tests.ps1`) is from `plan-auto-mejora-v3-2026-08-13.md:42` and `mejora-log.md:41`. The benchmark-baseline.json provides timing for `sync-vmk.ps1 -DryRun` (10 runs measured).

Git churn top-10 (since 2026-06-01, all files):

| # | File | Commits |
|---|---|---|
| 1 | BITACORA.md | 135 |
| 2 | AGENTS.md | 115 |
| 3 | .project.json | 81 |
| 4 | CYCLE.md | 77 |
| 5 | SKILLS-INDEX.md | 72 |
| 6 | opencan.json | 68 |
| 7 | README.md | 55 |
| 8 | scripts/skill-graph.ps1 | 53 |
| 9 | scripts/score-auto.ps1 | 50 |
| 10 | .github/workflows/quality-gate.yml | 43 |

## 3. Gaps — ICE + Blast Radius + Business

ICE = I × C × E (E = inverse effort: 10 = minimum effort). Higher = higher priority.

| # | Gap | Evidence (file:line / command) | I | C | E | ICE | Blast | Business | confidence |
|---|---|---|---|---|---|---|---|---|---|
| G1 | opencan.json over size budget (75,577 B > 65,536 B, 115%) | `fs.statSync('opencan.json').size=75,577`; `benchmark-baseline.json:StatsCount=83 scripts`; `scripts/tests/opencan.json-size.Tests.ps1` exists but didn't catch growth | 9 | 9 | 5 | 405 | **Alto** | config integrity gate ADR-007; deploy pipeline risk | high |
| G2 | 8 skills over 3KB (regressed from 0 at benchmark baseline) | `.project.json:dimensions_detail/SE.e.o3=8`, `SE.e.total=88`, `SE.e.avg=2.7`; `benchmark-baseline.json:SkillsOver3kb=0` | 7 | 9 | 6 | 378 | Medio | Skill Effectiveness dim 7.0 → score recovery target (CYCLE.md Cycle 28) | high |
| G3 | Cross-reference check failing (PA.dimension at 8.0, cross_ref=false) | `.project.json:dimensions_detail/PA.e.cross_ref=false`; `scripts/cross-ref-check.ps1` exists (git churn: 36 commits) | 8 | 9 | 5 | 360 | Medio | Project Artifacts dim blocked at 8.0; quality gate [3/18] | high |
| G5 | No PSScriptAnalyzer linter in environment / CI | `analyze-automejora.ps1:capabilities.linter.available=false`; `capabilities.linter.tools=[]`; `pssa-gate.ps1` exists (churn: 23 commits) but module not installed | 6 | 9 | 4 | 216 | Bajo | No automated code quality enforcement; 104 scripts lack [CmdletBinding] (G8) | high |
| G6 | 14+ scripts missing SupportsShouldProcessing (PSSA warnings) | Pester test run output: "WARNING: INFO: backup.ps1 lacks SupportsShouldProcessing..." (14+ scripts: backup, clean-repo, close-session, engram-compact, ensure-tools, forge-rollback, +) | 3 | 8 | 8 | 192 | Bajo | PSSA gate regression (mejora-log C4: "4 regresiones vs gate baseline") | medium |
| G9 | Unprocessed artifacts in `docs/archivos mover/` | `git status: ?? docs/archivos mover/gaps-log.md (Go proj analysis) + plan-mejora-autonoma.skill (binary)` | 2 | 9 | 10 | 180 | Bajo | Workflow hygiene; gaps-log.md is a sample/template for §E output | high |
| G4 | No PowerShell test coverage measurement | `analyze-automejora.ps1:tests.hasCoverage=false`; `tests.coverageFiles=0`; capability `coverage.tools=[]` (pytest-cov is Python-only, not PS) | 5 | 9 | 3 | 135 | Medio | CI quality gate has no coverage gate; test completeness unmeasurable | high |
| G11 | Score regression 9.3 → 8.7 (trend: down) | `.project.json:score.current=8.7, score.trend="down"`; CYCLE.md:28 "Target: 9.3→9.5" | 8 | 9 | 2 | 144 | **Alto** | CYCLE.md Cycle 28 objective; overall quality signal | high |
| G7 | score-dims.ps1 (742 lines) — highest complexity file | complexity scan: `scripts/lib/score-dims.ps1:742 lines` (largest .ps1); git churn: score-auto.ps1 50 commits | 6 | 9 | 2 | 108 | Medio | Core scoring logic for all 13 dimensions; single point of failure | high |
| G10 | 104 scripts with param() but missing [CmdletBinding] | complexity scan: "Scripts with param() but missing [CmdletBinding]: 104" (out of 206 .ps1 tracked) | 4 | 9 | 2 | 72 | Bajo | Clean Code dimension (current: 9.8); PSSA PSReviewUnusedParameter noise | high |

> **CHECKPOINT HUMANO OBLIGATORIO** (blast radius Alto, protocolo v3 §1): G1 (opencan.json budget) and G11 (score regression) — requieren aprobación humana explícita antes de cualquier implementación. G11 es síntoma de G1/G2/G3/G5/G6; su checkpoint se cumplirá tras C1-C3 (ver §4).

**Not fixed**: G4 (coverage) and G5 (linter) are tooling gaps — no source code bugs, but CI/tooling limitations that degrade long-term quality enforcement.

## 4. Cycle Priority Recommendation (§3)

| Cycle | Gap | ICE | Blast | Depends on | confidence |
|---|---|---|---|---|---|
| C1 | G3 (Cross-ref FALSE) | 360 | Medio | — | high |
| C2 | G2 (8 skills >3KB) | 378 | Medio | — | high |
| C3 | G5 (No linter in CI) | 216 | Bajo | G3 (cross-ref clean first) | high |
| C4 | G1 (opencan.json budget) | 405 | **Alto** | G3+C2 (config must be clean) | high |

**Recommended order**: C1 → G3 (establishes cross-ref integrity, unblocks config validation) → C2 → G2 (compresses skills, reduces config size, restores Skill Effectiveness) → C3 → G5 (install PSScriptAnalyzer in CI, enables G6/G8 follow-up) → C4 → G1 (opencan.json budget enforcement; **checkpoint humano** — depends on C1+C2 cleanup).

**Tier-adjusted**: T3 → 3-4 cycles max (protocolo v3 §0 presupuesto). G6, G7, G8, G9, G10, G11 are candidates for a follow-up run (N+1) after C1-C4.

## 5. Trend vs Previous

**Previous analysis**: `docs/mejoras/2026-08-12-gentleman-agent-gh-analisis.md` (T2, referenced in mejora-log.md:586 as evidence source for v3 baseline).

**Delta**:
- **improvements**: npm audit 2 vulns → 0 (resolved in v3 C1, mejora-log C1 corrida 3); CI quality gate 18/18 → 22/22 (added ConfigValidator, mejora-log C3 v3); PSSA PSReviewUnusedParameter 44 → 24 (mejora-log C6 v3)
- **regressions**: score 9.3 → 8.7 (down); opencan.json 53,556 B → 75,577 B (+41%, over budget); skills >3KB 0 → 8; Skill Effectiveness 9.x → 7.0; cross_ref true → false; avg skill bytes 2,516 → 2,762
- **new**: `automejora-analyzer` skill + `analyze-automejora.ps1` PCI scanner (Cycle 4 tooling); 89 skills (was 78 at benchmark-baseline); `docs/archivos mover/` unprocessed artifacts

**Root cause of regressions**: v3 cycles (C1-C3) added tooling (ConfigValidator, CI workflow, sync-vmk full agent sync, agent twins) which increased opencan.json size and added 11 new skills (78→89), some exceeding 3KB. The `cross-ref-check.ps1` was not re-validated after the agent sync (G3). Score dropped because Skill Effectiveness (7.0) and Project Artifacts (8.0, cross-ref) dimensions degraded.

## Analysis Only — NO implementation

This document is analysis-only. **No source file was mutated.** (The test run auto-updated `.project.json` via score-auto; this was reverted via `git checkout -- .project.json`.) The v3 implementation protocol (`protocolo_mejora_autonoma_v3.md`) consumes this report as §0 evidence: C1 → G3, C2 → G2, C3 → G5, C4 → G1 (checkpoint humano).

*Every claim above carries a confidence marker; unmarked claims fail default review.*
