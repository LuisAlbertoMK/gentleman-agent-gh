---
name: automejora-analyzer
description: "Cross-project autonomous self-improvement analysis (read-only). T1-T4 scaling. Produces gap priority report with ICE + blast radius. NO implementation."
triggers: "automejora, auto-mejora, self-improvement analysis, !automejora, project audit, improve this repo"
---

## When to Use
Trigger via `!automejora` or `!analisis automejora`. Runs in any project. NEVER writes code — produces `docs/mejoras/YYYY-MM-DD-<project>-automejora-analisis.md` (orchestrator writes). v3 protocol consumes this as evidence.

## PCI — 5 Signals (scored 1-4; tier = round-half-up mean → T1..T4)
S1 Files: T1<25, T2 25-99, T3 100-499, T4≥500 | S2 Langs: T1=1, T2=2, T3=3-4, T4≥5 | S3 Tests+cov: T1=none, T2=tests no cov, T3=tests+cov, T4=tests+cov+CI | S4 CI/CD: T1=none, T2=single, T3=gh/gl workflows, T4=2+ workflows/IaC | S5 Deps: T1=none, T2=1, T3=2, T4≥3
Helper: `scripts/analyze-automejora.ps1 -Path <root> -Json` computes PCI.

## Tier Capability Matrix
T1: PCI+probe+evidence+3 gaps max; skip tests/lint/audit, coverage, cross-service, perf
T2: T1+test baseline (3 runs)+linter+sec audit; skip cross-service, perf, IaC, adversarial
T3: T2+cross-service map+perf+sec audit+churn; skip IaC, data audit, adversarial, 8-dim
T4: T3+IaC+data audit+adversarial+8-dim+gap-analysis; skip nothing

## Capability Probe (degrade gracefully — SKIP if absent)
test-runner: pytest/Pester/jest/vitest/go test/cargo test/dotnet test → probe; run 3× baseline or SKIP
linter: ESLint/flake8/ruff/PSScriptAnalyzer/golangci-lint/bandit → run or grep complexity scan
security-audit: npm audit/pip-audit/trivy/checkov/bandit/safety → run or note Security gap
performance: lighthouse/web-vitals/py-spy → run or note absence
build: npm/go/dotnet/cargo build → verify or SKIP
coverage: .coverage/.lcov/coverage.xml/coverage//htmlcov/ → read or SKIP
ci-config: .github/workflows//.gitlab-ci.yml/Jenkinsfile/Makefile → presence→Velocity signal; absence→Gx gap

## Read-Only Enforcement (GIL)
ALLOWED: Read/Grep/Glob, ctx_execute/ctx_execute_file (no mutation), bash(git status/log/diff), scripts/check-*.ps1 -WhatIf, webfetch/ctx_fetch_and_index (public)
FORBIDDEN: Write/Edit/new file, bash(mutate: git add/commit/push, npm install, build, docker run -v) unless --dry-run
- Auto-detect `.gentleman-mode` (`auto`/`semi`/`manual`); absent → `manual`. Mode NEVER relaxes GIL.
- Orchestrator writes output; agent assembles and reports.

## Analysis Pipeline (4 Phases)
0. Setup: PCI+probe→capability matrix. Baseline: real numbers, min 3 runs, median+IQR. Git churn top-10 (90d). Hierarchy: correctness>security>performance>size.
1. Evidence: Run probes. Every finding cites `source:line` or exact command — never opinion.
2. Gap Scoring: Per gap: description, evidence, ICE (Impact×Confidence/Effort, 1-10), blast (Bajo/Medio/Alto), business traceability. Blast Alto (API/DB/auth/core) → CHECKPOINT HUMANO OBLIGATORIO. Secondary: gap-analysis priority `(10-Score)×Impact×Urgency`.
3. Prioritization: Cycle table ranked by ICE desc, tier-adjusted, dependency-aware (Gx blocks Gy). Output: `C1 → G#`.
4. Persist: `mem_save` (title `analysis:<project>:<date>`, type `architecture`, topic_key `analysis/<project>`). Report to orchestrator. Cross-ref prior via `mem_search` → Trend delta.

## Output Contract
# Automejora Analysis — {project} — {date}
> Protocol: protocolo_mejora_autonoma_v3 §0-1 · Mode: read-only · Tier: {T} | Scope: {scope} · Branch: {branch@head} · confidence: high
Sections: 0.PCI 1.Capability Matrix 2.Baseline (median/IQR, ≥3 runs) 3.Gaps (ICE+Blast+Business) 4.Cycle Priority 5.Trend vs Previous
Analysis only — NO implementation. Every claim has confidence marker.

## Confidence Calibration
high=tool-backed, medium=inferred, low=speculation, unvalidated=novel. Unmarked → Default-FAIL.

## Portability
Output: docs/mejoras/ → .opencode/insights/ → .agents/analysis/ → create docs/mejoras/ | All paths RELATIVE. Degradation: no runner→SKIP M4, no CI→Velocity gap, no linter→grep scan | T4 uses gap-analysis templates (ERP/Ecom/Web/API/Desktop/Mobile/SaaS).

## Anti-Patterns
Skip intake · Baseline w/o runs · Opinion w/o evidence · Mutate during analysis · Ignore blast radius · Mix analysis+implementation

## Refs
protocolo_mejora_autonoma_v3 · analysis-mode · project-mapper · gap-analysis · self-improvement · opencode-model-router · execution-mode · skill-graph · subagent-isolation
