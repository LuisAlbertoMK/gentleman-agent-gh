# SKILLS INDEX (Compact)

> Top-20 daily-use skills. Full table: 93 skills — use `skill` tool or read this file for complete list.
>
> **Version**: 5.0 | **Changelog**: 5.0 (compact top-20 table for token reduction); 4.7 (+1 new: adversarial-breaker; count 92→93); 4.6 (count corrected 80→92 per filesystem audit)

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

## Quick Groups

| Group | Skills |
|-------|--------|
| Quality | quality-gate, code-review-agent, triple-verify, auto-metrics, external-auditor, immune-system, testing-strategy |
| Code | commit-crafter, code-generation, quick-executor, refactoring-planner |
| Security | security-scanner, auth-hardening, container-security, llm-security |
| SDD | sdd (unified pipeline), sdd-quick, sdd-apply |
| Coordination | delivery-harness, branch-pr, issue-creation, command-wrapper |
| Analysis | analysis-mode, deep-debugging |
| Memory | session-resume, engram-protocol, dreaming, bitacora |
| Skills meta | opencode-skill-creator, skill-registry, skill-graph |
| Engineering | plan-execution, infra-audit, perf-profiling |
| UI/Docs | baseline-ui, ui-engine, accessibility, seo, docs-audit |
| Testing | visual-testing, e2e-testing, api-testing, image-pipeline, pdf-utils |
| Communication | comment-writer, cognitive-doc-design |
| Specialized | karpathy-loop, context-watchdog, recovery-protocol, metricas, workflow-optimizer |

## Load Rule

1. `skill` tool with name (skills.paths registered in opencode.json — 93 skills globally discoverable)
2. Fallback: `read skills/{name}/SKILL.md` directly from disk
3. Assets: `read skills/{name}/references/` or `skills/{name}/assets/` for templates

**Validation**: `scripts/skill-validate.ps1` | **Scripts**: ensure-tools, token-count, skill-graph, pull-upstream
