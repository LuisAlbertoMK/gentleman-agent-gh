# SKILLS INDEX

> Full trigger table for all 57 skills. Read on-demand when AGENTS.md compact table doesn't match.
> Located at project root.
>
> **Version**: 1.2 | **Changelog**: 1.2 (merged caveman?lean-context, trimmed project-mapper dupe tables)

## Triggers → Skill

| Trigger keywords | Skill |
|------------------|-------|
| Karpathy, less tokens, context compilation | karpathy-prompt |
| Improve prompt, security, ReAct, multi-agent | prompt-engineering |
| Karpathy loop, optimize prompt, measure tokens | karpathy-loop |
| Compact, less tokens, caveman, /caveman, ultra-lean | lean-context |
| Continuá, code memory, multi-session | code-memory |
| Self-reflection, Hermes, error patterns | self-reflection |
| Test/verify skill, coverage | skill-testing |
| Judgment day, dual review, juzgar | judgment-day |
| Senior architect, trade-offs, system design | senior-engineer |
| Go tests, Bubbletea TUI | go-testing |
| Python async, asyncio | python-async |
| Create AI skill | skill-creator |
| Skill registry, catalog | skill-registry |
| Quality gate, pre-commit | quality-gate |
| Context >100K tokens, context explosion | context-watchdog |
| Recovery, "no es eso", frustration | recovery-protocol |
| Resume, "dónde lo dejamos", "continuá", git state gate | session-resume |
| SDD init, bootstrap | sdd-init |
| Explore codebase, pre-design | sdd-explore |
| Proposal, intent, approach | sdd-propose |
| Specs, Given/When/Then | sdd-spec |
| Technical design, HOW | sdd-design |
| Task breakdown, implementation plan | sdd-tasks |
| Apply tasks, implement | sdd-apply |
| Validate vs specs, verify | sdd-verify |
| Archive changes, delta to main | sdd-archive |
| Guided SDD walkthrough | sdd-onboard |
| PR creation, issue-first | branch-pr |
| PR with SDD evidence | pr-evidence |
| Issue creation | issue-creation |
| Decision capture, trade-off log | decision-capture |
| Execution mode, quick/thorough/draft | execution-mode |
| Chained PRs, >400 lines, review slices | chained-pr |
| Cognitive load, docs for reviewers | cognitive-doc-design |
| PR comments, issue replies, feedback | comment-writer |
| SDD phase contracts, artifact dependencies | sdd-contracts |
| Skill digestion, compact on load | skill-digestion |
| Delivery harness, review workload | delivery-harness |
| Subagent isolation, context boundaries | subagent-isolation |
| Command wrapper, error handling, output parsing | command-wrapper |
| Skill refresher, drift detection, auto-heal | skill-refresher |
| Skill improvement, audit skills, refactor skills | skill-improver |
| CI/CD pipeline, GitHub Actions, quality gate | ci-cd |
| Work-unit commits, commit organization | work-unit-commits |
| Immune System, anti-pattern, permanent immunity | immune-system |
| Auto-score, metrics, post-task evaluation | auto-metrics |
| Metricas, before/after, % improvement, tokenization, delta | metricas |
| Code review, CR, revisar código, criticar | code-review-agent |
| Refactor, refactoring, reestructurar, migrate | refactoring-planner |
| Commit, mensaje, commit message, conventional commit | commit-crafter |
| Mapear, project map, estructura, tech stack, arquitectura | project-mapper |
| Security, seguridad, vulnerabilidad, auditar | security-scanner |
| Doc sync, documentación, readme, sincronizar docs | doc-sync |
| Bitacora, historial, histórico, qué pedí, request log | bitacora |
| Dreaming, cross-session patterns, memory curation | dreaming |
| Performance score, mobile perf, desktop perf, rendimiento, app score, lighthouse, benchmark | performance-tracker |
| Gap analysis, system audit, identificar gaps, evaluar software | gap-analysis |

## Quick groups
- **Compression/style**: karpathy-prompt, karpathy-loop, lean-context
- **Quality**: quality-gate, auto-metrics, immune-system, code-review-agent, performance-tracker
- **Memory**: session-resume, code-memory, dreaming
- **Skills meta**: skill-creator, skill-registry, skill-improver, skill-digestion
- **Code ops**: commit-crafter, refactoring-planner, project-mapper, security-scanner
- **SDD**: sdd-{init,explore,propose,spec,design,tasks,apply,verify,archive}
- **PR/Issues**: branch-pr, pr-evidence, issue-creation, comment-writer
- **Specialized**: metricas, doc-sync, bitacora, context-watchdog, recovery-protocol

## Load rule
1. `read` this file
2. Find match
3. `skill` tool with name
