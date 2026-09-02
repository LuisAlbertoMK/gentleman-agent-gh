# SKILLS INDEX (Compact)

> Top-20 daily-use skills. Full table: all 94 skills — use `skill` tool or read this file for complete list.
>
> **Version**: 5.6 | **Changelog**: 5.6 (2026-09-02 — +state-reconcile +ps-compat (skill expansion); count 93→94 (excl. _shared per cross-ref Get-SkillDir)); 5.5 (2026-08-16: C28 auto-improvement cycle added depth to 90 skills; +2 new skills image-pipeline, customize-opencodec; count 89→90); 5.5.1 (2026-08-18: +1 new skill gentleman-aem; count 90→91); 5.4 (2026-08-13: count 87→88 per new automejora-analyzer skill); 5.3 (2026-08-12: count 78→87 per filesystem audit; README.md synced to current counts) 5.2 (archived 3 dead: cognitive-doc-design, prompt-engineering, senior-engineer → .archive/skills; count 81→78 per cross-ref-check; global discoverable 93→165 per FS scan: 78 project + 87 global, excl. _shared); 5.1 (sync count 93→81 per filesystem audit); 5.0 (compact top-20 table for token reduction); 4.7 (+1 new: adversarial-breaker; count 92→93); 4.6 (count corrected 80→92 per filesystem audit)

## Top 20 Daily-Use Skills

| Trigger keywords | Skill |
|------------------|-------|
| deep debug, root cause, hypothesis, RCA | deep-debugging |
| security, audit, vulnerability | security-scanner |
| quality gate, pre-commit | quality-gate |
| commit, conventional commit | commit-crafter |
| create issue, bug report, feature request | issue-creation |
| branch PR, create PR, open pull request | branch-pr |
| code review, CR | code-review-agent |
| quick edit, single file, fast fix | quick-executor |
| new file, new function, script, scaffold | code-generation |
| analysis mode, multi-agent analysis | analysis-mode |
| delivery harness, orchestrate, multi-agent | delivery-harness |
| execute plan, step-by-step, task execution | plan-execution |
| SDD quick, fast path, low risk | sdd-quick |
| SDD apply, implement SDD tasks | sdd-apply |
| skill creator, create skill, evaluate | opencode-skill-creator |
| triple verify, !ship, !fast, !draft | triple-verify |
| session resume, continue, git state gate | session-resume |
| engram, memory, recall, mem_save | engram-protocol |
| Karpathy, less tokens, measure tokens | karpathy-loop |
| state reconcile, plan sync, plan stale, backlog verify, que falta, pendiente, status claim, what's missing, plan drift | state-reconcile |
| powershell 5.1, ps5, ps7, ps compatibility, encoding, CRLF, BOM, PSSA, Join-Path, cmatch, requires, bash-safe, script authoring | ps-compat |

## Quick Groups

| Group | Skills |
|-------|--------|
| Quality | quality-gate, code-review-agent, triple-verify, auto-metrics, external-auditor, immune-system, testing-strategy |
| Code | commit-crafter, code-generation, quick-executor, refactoring-planner |
| Security | security-scanner, auth-hardening, container-security, llm-security |
| SDD | sdd (unified pipeline), sdd-quick, sdd-propose, sdd-design, sdd-apply, sdd-verify |
| Coordination | delivery-harness, branch-pr, issue-creation, command-wrapper |
| Analysis | analysis-mode, deep-debugging |
| Memory | session-resume, engram-protocol, dreaming, bitacora |
| Skills meta | opencode-skill-creator, skill-registry, skill-graph |
| Engineering | plan-execution, infra-audit, perf-profiling, customize-opencode |
| UI/Docs | baseline-ui, ui-engine, accessibility, seo, docs-audit |
| Testing | visual-testing, e2e-testing, api-testing, image-pipeline, pdf-utils |
| Communication | comment-writer |
| Specialized | karpathy-loop, context-watchdog, recovery-protocol, metricas, workflow-optimizer , trial-verify |

## Load Rule

1. `skill` tool with name (skills.paths registered in opencode.json — 165 skills globally discoverable: 78 project + 87 global)
2. Fallback: `read skills/{name}/SKILL.md` directly from disk
3. Assets: `read skills/{name}/references/` or `skills/{name}/assets/` for templates

**Validation**: `scripts/skill-validate.ps1` | **Scripts**: ensure-tools, token-count, skill-graph, pull-upstream
