# SKILLS INDEX (Compact)

> Top-20 daily-use skills (all 96 skills — full list via `skill` tool).
>
> **Version**: 5.9 | **Changelog**: 5.9 retired 4 dup/dead skills; history: `git log SKILLS-INDEX.md`.

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

## Quick Groups (heads only; `+N more` → complete via `skill` tool)

| Group | Skills |
|-------|--------|
| Quality | quality-gate, code-review-agent, triple-verify (+8 more) |
| Code | commit-crafter, code-generation, quick-executor (+2 more) |
| Security | security-scanner, auth-hardening, container-security (+5 more) |
| SDD | sdd-quick, sdd-apply, sdd-verify (+8 more) |
| Coordination | delivery-harness, branch-pr, issue-creation (+9 more) |
| Analysis | analysis-mode, deep-debugging, gap-analysis, research, project-mapper |
| Memory | session-resume, engram-protocol, dreaming, bitacora |
| Skills meta | opencode-skill-creator, skill-registry, skill-graph (+5 more) |
| Engineering | plan-execution, perf-profiling, ci-cd (+8 more) |
| UI/Docs | baseline-ui, ui-engine, accessibility (+3 more) |
| Testing | visual-testing, e2e-testing, api-testing (+3 more) |
| Communication | comment-writer, help |
| Specialized | karpathy-loop, context-watchdog, recovery-protocol (+4 more) |

## Load Rule

1. `skill` tool with name (registered in opencode.json) — fallback: `read skills/{name}/SKILL.md`
2. Assets: `skills/{name}/references/` or `assets/` — validate: `scripts/skill-validate.ps1`
