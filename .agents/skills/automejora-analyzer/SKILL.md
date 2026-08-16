---
name: automejora-analyzer
description: "Cross-project autonomous self-improvement analysis (read-only). T1-T4 scaling. Gap priority report with ICE + blast radius. NO implementation."
triggers: "automejora, auto-mejora, self-improvement analysis, !automejora, project audit, improve this repo"
changelog: docs/ciclos/cycle28-20260815.md
---

Trigger `!automejora` or `!analisis automejora` in any project. NEVER writes code — output to `docs/mejoras/YYYY-MM-DD-<project>-automejora-analisis.md`. v3 protocol consumes as evidence.

**PCI** (90d): S1 Files T1<25/T2 25-99/T3 100-499/T4≥500 | S2 Langs T1=1/T2=2/T3=3-4/T4≥5 | S3 Tests T1=none/T2=no-cov/T3=cov/T4=cov+CI | S4 CI T1=none/T2=1wf/T3=gh,gl/T4=2+wf | S5 Deps T1=none/T2=1/T3=2/T4≥3. Helper: `scripts/analyze-automejora.ps1 -Path <root> -Json` computes PCI.

**Capability probe** (run 3x or SKIP): test-runner(pytest/Pester/jest/go/cargo/dotnet), linter(ESLint/flake8/ruff/PSSA), security-audit(npm/pip/trivy/bandit), perf(lighthouse/py-spy), build(npm/go/cargo), coverage(.lcov/.coverage), ci-config(.github/workflows/).

**Allowed**: Read/Grep/Glob, ctx_execute(no mutation), bash(git status/log/diff), scripts/check-*.ps1 -WhatIf, webfetch(public). **Forbidden**: Write/Edit, bash(git add/commit/push/npm install/build/docker run). Detect `.gentleman-mode`(absent→manual); NEVER relaxes GIL.

**Pipeline** (4 phases, §A-§E):
0. Setup: PCI+probe→matrix. Baseline: 3 runs, median+IQR. Churn top-10. Priority: correctness>security>perf>size.
1. Evidence: cite source:line/exact cmd. No opinions.
2. Gap Scoring: desc, evidence, ICE(I×C/E,1-10), blast(B/M/A), biz-trace. Blast Alto→**HUMAN CHECKPOINT**.
3. Prioritization: ICE desc, tier-adjusted, dep-aware. Output: `C1→G#`.
4. Persist: `mem_save`(type:architecture, key:`analysis/<project>`). Cross-ref via `mem_search`. Report: orchestrator writes `docs/mejoras/YYYY-MM-DD-<project>-automejora-analisis.md` with §E template.