---
name: automejora-analyzer
description: "Cross-project autonomous self-improvement analysis agent (read-only). Escalas de proyecto básico a complejo (T1-T4). Produce gap priority report con ICE + blast radius. NO implementation — analysis only."
triggers: "automejora, auto-mejora, análisis de automejora, self-improvement analysis, !automejora, project audit, improve this repo, código que podría mejorar"
---

## When to Use
Trigger via `!automejora` as first token, OR `!analisis automejora`, OR invoke `skill(name="automejora-analyzer")`.

This is the **analysis gate BEFORE the v3 implementation protocol** (`docs/protocolos/protocolo_mejora_autonoma_v3.md`). It runs in ANY project — from a single script to a monorepo. It **NEVER writes code** — it only produces `docs/mejoras/YYYY-MM-DD-<project>-automejora-analisis.md` (written by the ORCHESTRATOR, see §C). The v3 protocol consumes this report as its evidence source: every gap must anchor to a concrete tool/evidence (§0 — gaps anclados a evidencia, never opinion).

## Section A: Project Complexity Profile (PCI) — the scaling engine

### 5-signal triage
Every project, regardless of size, is scored on the SAME 5 signals. Each signal maps to a level 1-4; overall tier = round-half-up of the mean of the 5 levels. Output is always `T1`..`T4`.

**The 5 signals**: (1) file count, (2) language diversity, (3) test + coverage presence, (4) CI/CD presence, (5) dependency manifest.

| Signal | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| S1 File count | <25 | 25–99 | 100–499 | ≥500 |
| S2 Language diversity | 1 | 2 | 3–4 | ≥5 |
| S3 Tests + coverage | none | tests, no coverage | tests + coverage | tests + coverage + CI |
| S4 CI/CD | none | single indicator (Makefile/Jenkinsfile) | `.github/workflows` or `.gitlab-ci` | 2+ workflows / IaC present |
| S5 Dep manifest | none | 1 | 2 | ≥3 |

### Tier capability matrix — what each tier RUNS vs SKIPS
**SAME output format across tiers — only depth varies.** The §E template is identical; a T1 report just has fewer/simpler rows.

| Tier | Runs | Skips |
|---|---|---|
| **T1 basic scan** | PCI + capability probe + evidence scan (grep, git churn, LOC) + 3 gaps max | tests/lint/audit execution, coverage, cross-service, perf benchmarks |
| **T2 +tests/lint/audit** | T1 + run test runner baseline (min 3 runs) + linter + security audit (if tool present) | cross-service call maps, perf sampling, IaC, adversarial |
| **T3 +cross-service/perf/security/churn** | T2 + cross-service call map + perf sampling + security audit + git churn top-10 | IaC scan, data pipeline audit, adversarial, full 8-dim |
| **T4 +IaC/data/adversarial/8-dim/gap-analysis** | T3 + IaC scan + data audit + adversarial breaker + full 8-dim scoring + gap-analysis project-type templates | nothing |

Helper: `scripts/analyze-automejora.ps1 -Path <root> -Json` computes PCI + capability probe with these exact signals/thresholds (project-relative). If the helper exists, run it first.

## Section B: Capability Probe — adapt to tools available
Probe per capability dimension; **degrade gracefully — SKIPPED if not found**. Each probe result feeds the capability matrix in the output (§E §1).

| Capability | Look-for patterns | Action |
|---|---|---|
| test-runner | pytest, Pester (module), jest/vitest/mocha, go test, cargo test, dotnet test; test dirs (`test/ tests/ spec/ __tests__/`) | probe via `Get-Command`/`Get-Module`; if present run min-3-run baseline for time metrics; else SKIPPED (M4 metric SKIPPED) |
| linter | ESLint, flake8/ruff, PSScriptAnalyzer (module), golangci-lint, bandit | run linter if present; else grep-based complexity scan (TODO/FIXME, nested loops, empty catch) |
| security-audit | npm audit, pip-audit, trivy, checkov, bandit, safety | run audit if present; else note absence as a Security gap finding |
| performance | lighthouse, web-vitals, py-spy | run sampler if present; else note absence |
| build | `npm run build`, `go build`, `dotnet build`, `cargo build` | verify build if present; else SKIPPED |
| coverage | `.coverage`, `.lcov`/`lcov.info`, `coverage.xml`, `coverage/`, `htmlcov/` | read coverage if present; else SKIPPED (coverage metrics absent) |
| ci-config | `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `Makefile`, `.circleci/` | presence → Velocity signal; absence → Gx finding (Velocity gap) |

## Section C: Read-Only Enforcement Layer (GIL)
Adapted from `analysis-mode` GATE. This layer is **bulletproof and non-negotiable** — it holds in every mode and every tier.

```
ALLOWED:  Read / Grep / Glob (structure discovery)
ALLOWED:  ctx_execute / ctx_execute_file (sandboxed derivation — no mutation)
ALLOWED:  bash(git status / git log / git diff / git --version) — OBSERVATION ONLY
ALLOWED:  scripts/check-*.ps1 -WhatIf / tool --version / tool --help (dry-run)
ALLOWED:  webfetch / ctx_fetch_and_index (public only)
FORBIDDEN: Write / Edit / new file — log BLOCKED, skip
FORBIDDEN: bash(mutate: git add/commit/push, npm install, build artifacts, docker run -v) — unless --dry-run/--check flag present
```

- **Auto-detect mode**: read nearest `.gentleman-mode` (`auto`/`semi`/`manual`, per `scripts/mode-gate.ps1`); absent → `manual`. Mode NEVER relaxes the GIL — analysis stays read-only in all three modes.
- **Mode-gate**: when delegated, the orchestrator appends the mode suffix (`-auto`/`-semi`) to the agent name per mode-gate.ps1. The analyzer still reports via the 4-field return contract.
- **Output file**: the agent NEVER writes `docs/mejoras/...`. The agent assembles the document and reports it; the ORCHESTRATOR writes the file after receiving the report. (`analysis-mode` persists to `docs/mejoras` — automejora-analyzer enforces that ONLY the analysis document is produced and no source mutation ever happens.)

## Section D: Analysis Pipeline (adapted from protocolo v3 §0 + !analisis)

### Phase 0 — Setup & Baseline (→ v3 §0)
1. PCI (§A) + capability probe (§B) → capability matrix.
2. Baseline: **real numbers only** — min 3 runs for time-based metrics (protocolo §0.7 wants 5-10 runs; helper floor is 3; if time allows, do 5-10). Report **median + IQR**, never a single number.
3. Git churn top-10 (`git log --pretty=format: --name-only | sort | uniq -c | sort -rn` style, 90 days) — reference `docs/mejoras/2026-08-12-gentleman-agent-gh-analisis.md` §1.
4. Metric hierarchy reminder: **correctness > security > performance > size/legibility** — a change that improves a lower metric at the cost of a higher one is REJECTED.

### Phase 1 — Evidence-Gathering (→ v3 §0 fuente de verdad)
Run the available probe tools (from §B). Every evidence source → a row with `source:line` or the exact command. Git churn + LOC. Coverage if available. **Each finding must cite real evidence — never opinion.**

### Phase 2 — Gap Extraction & Scoring (→ v3 §1)
For each gap: description, evidence source, **ICE** (`Impact × Confidence / Effort` per plan-template; Impact 1-10, Confidence 1-10, Effort 1-10 inverse — 10 = minimum effort), **blast radius** (Bajo/Medio/Alto per §1), **business traceability** (ticket/link or explicit business justification).
- Blast radius **Alto** (API contracts, DB schema, core deps, auth/security) → flag **"CHECKPOINT HUMANO OBLIGATORIO"** (protocolo v3 §1 — no auto-approval).
- Use gap-analysis priority formula `(10-Score)×Impact×Urgency` as secondary signal.

### Phase 3 — Synthesis & Prioritization (→ v3 §3)
Build a cycle-priority table (like the 2026-08-12 analysis §2/§4): rank gaps by **ICE desc**, tier-adjust (T1 report → fewer cycles), dependency-aware (Gx blocks Gy → order matters). Output: `C1 → G#` priority recommendation. Note dependencies between gaps.

### Phase 4 — Persist (→ v3 §7 + engram)
1. **Memorize**: `mem_save` — title `analysis:<project>:<YYYY-MM-DD>`, type `architecture`, `topic_key: analysis/<project>`. Content: What/Why/Where/Key Findings/Learned.
2. **Report the document** (§E template) to the orchestrator — the ORCHESTRATOR appends `docs/mejoras/YYYY-MM-DD-<project>-automejora-analisis.md`.
3. **Cross-reference**: `mem_search("analysis:<project>", topic_key:"analysis/<project>")` → delta (improvements/regressions/new/stale) → **Trend** section. No prior → "No previous analysis — baseline".

## Section E: Output Contract
EXACT template for `docs/mejoras/YYYY-MM-DD-<project>-automejora-analisis.md`. Every claim carries a `confidence:` marker (§F).

```markdown
# Automejora Analysis — {project} — {YYYY-MM-DD}

> **Protocol**: protocolo_mejora_autonoma_v3.md §0-§1 · **Mode**: read-only · **Tier**: {T1-T4}
> **Scope**: {declared scope} · **Branch**: {branch @ head} · **confidence: high** (tool-backed)

## 0. Project Complexity Profile (PCI)
| Signal | Value | Level |
|---|---|---|
| S1 File count | {n} | {1-4} |
| S2 Language diversity | {langs} | {1-4} |
| S3 Tests + coverage | {present/absent} | {1-4} |
| S4 CI/CD | {present/absent} | {1-4} |
| S5 Dep manifest | {manifests} | {1-4} |
**Tier**: {T} — runs: {tier scope} · skips: {tier skips}

## 1. Evidence Sources Available (capability matrix)
| Capability | Available | Tool(s) | confidence |
|---|---|---|---|
| test-runner | yes/no/SKIPPED | {pytest, ...} | high |
| linter | ... | ... | high |
| security-audit | ... | ... | high |
| performance | ... | ... | high |
| build | ... | ... | high |
| coverage | ... | ... | high |
| ci-config | ... | ... | high |

## 2. Baseline (§0.7) — real runs only, median/IQR
| Metric | Baseline (median / IQR) | Runs | Source | confidence |
|---|---|---|---|---|
| M1 {test suite} | {median} ms ({IQR}) | {n≥3} | `{command}` | high |
| M2 {linter warnings} | {n} | 1 | `{command}` | high |
| M3 {coverage %} | {n}% | 1 | `{file:line}` | high |
| M4 {time metric} | {median} ({IQR}) | {n≥3} | `{command}` | high |
| M5 {size metric} | {bytes} | 1 | `{file:line}` | high |
Git churn top-10 (90 days): {table}

## 3. Gaps — ICE + Blast Radius + Business
| # | Gap | Evidence (file:line / command) | I | C | E | ICE | Blast | Business | confidence |
|---|---|---|---|---|---|---|---|---|---|
| G1 | {description} | `{file}:{line}` / `{command}` | {1-10} | {1-10} | {1-10} | {I*C*E} | Bajo/Medio/Alto | {ticket/justification} | high |
| G2 | ... | ... | ... | ... | ... | ... | ... | ... | ... |

> **CHECKPOINT HUMANO OBLIGATORIO** (blast radius Alto, protocolo v3 §1): {G#...} — requiren aprobación humana explícita antes de cualquier implementación.

## 4. Cycle Priority Recommendation (§3)
| Cycle | Gap | ICE | Blast | Depends on | confidence |
|---|---|---|---|---|---|
| C1 | G# | {ICE} | Bajo/Medio/Alto | — | high |
| C2 | G# | ... | ... | G# | high |
| C3 | G# | ... | ... | — | high |

**Recommended order**: C1 → G# (blocks C2) → ... Tier-adjusted: {n} cycles max for tier {T}.

## 5. Trend vs Previous
{delta vs prior analysis — improvements/regressions/new/stale} or "No previous analysis — baseline."

## Analysis Only — NO implementation
This document is analysis-only. **No source file was mutated.** The v3 implementation protocol
consumes this report as evidence input. Gaps with blast radius Alto require a human checkpoint
before any implementation cycle starts.

*Every claim above carries a confidence marker; unmarked claims fail default review.*
```

## Section F: Confidence Calibration
Every claim in the output carries `confidence: high|medium|low|unvalidated`:
- `high` — backed by tool output (grep/Read/glob/run command)
- `medium` — reasonable inference from evidence, not directly verified
- `low` — speculation, no direct tool output
- `unvalidated` — novel suggestion not yet analyzed

**NO claim without a marker** — unmarked claims are subject to Default-FAIL.

## Section G: Cross-Project Portability
- **Output path**: `docs/mejoras/` is this-repo convention → generalize: look for `.opencode/insights/` fallback, else `.agents/analysis/`, else create `docs/mejoras/` (may need `mkdir` — the agent CANNOT mkdir; the ORCHESTRATOR does it). Reference `analysis-mode` §P4.
- **Path handling**: all paths in evidence must be **RELATIVE** (plan v3 note: "nada de rutas absolutas específicas de un OS") — never `D:\...`, never `/home/...`.
- **Tool degradation**: no test runner → M4 metric SKIPPED; no CI → note absence as Gx finding (Velocity gap); no linter → grep-based complexity scan.
- **Templates**: use gap-analysis project-type templates (ERP/Ecom/Web/API/Desktop/Mobile/SaaS) for dimension weighting when scoring 8 dims at T4.

## Section H: Anti-Patterns
Skip intake · Baseline without real runs · Opinion without evidence · Mutate during analysis · Ignore blast radius · Mix analysis+implementation

## Section I: Refs
protocolo_mejora_autonoma_v3 · analysis-mode · project-mapper · gap-analysis · self-improvement · opencode-model-router · execution-mode · skill-graph · subagent-isolation

## Section J: Example invocation
Full flow for a mid-size Python API (`widget-api`, 60 files):
1. `!automejora` → PCI detects: files=60→2, langs=1→1, tests=present + no coverage→2, CI=none→1, deps=1→2 → mean 1.6 → **T2**.
2. Capability probe → pytest ✅, flake8 ✅, no CI → matrix: test-runner=pytest, linter=flake8, securityAudit=SKIPPED, perf=SKIPPED, build=SKIPPED, coverage=SKIPPED, ci-config=absent (→ Velocity gap).
3. Baseline → `pytest` ×3 with `--durations=5`, median+IQR per §0.7. Git churn top-10.
4. Gaps extracted with evidence:
   - G1 no CI (Velocity) — evidence: no `.github/workflows`, no `Makefile` — ICE 9×8×7=504, Blast **Bajo**
   - G2 flake8 F401 in `auth.py:12` — ICE 7×9×8=504, Blast **Bajo**
   - G3 no coverage gate — evidence: no `.coverage`, no `coverage/`, `pytest --cov` not configured — ICE 6×9×4=216, Blast **Medio**
5. Output → `docs/mejoras/2026-08-13-widget-api-automejora-analisis.md` (written by the ORCHESTRATOR after the agent reports) + `mem_save` with `topic_key:"analysis/widget-api"` + trend cross-ref via `mem_search("analysis:widget-api")`.
6. Handoff → the v3 implementation protocol consumes the report as §0 evidence: C1 → G1, C2 → G2, C3 → G3. No blast radius Alto → no mandatory human checkpoint.