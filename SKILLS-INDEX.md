# SKILLS INDEX

> Full trigger table for all 47 skills. Read on-demand when AGENTS.md compact table doesn't match.
> Located at project root.
>
> **Version**: 1.5 | **Changelog**: 1.5 (gap-analysis v2.1: 3-iteration cycle, intake-verify.ps1, FE/BE/DB templates; project-mapper v1.4: mandatory auto-chain)

## Triggers â†’ Skill

| Trigger keywords | Skill |
|------------------|-------|
| Karpathy, less tokens, context compilation | karpathy-prompt |
| Improve prompt, security, ReAct, multi-agent | prompt-engineering |
| Karpathy loop, optimize prompt, measure tokens | karpathy-loop |
| Compact, less tokens, caveman, /caveman, ultra-lean | lean-context |
| ContinuÃ¡, code memory, multi-session | code-memory |
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
| Resume, "dÃ³nde lo dejamos", "continuÃ¡", git state gate | session-resume |
| SDD init, bootstrap | sdd-init |
| Explore codebase, pre-design | sdd-explore |
| Proposal, intent, approach | sdd-propose |
| Specs, Given/When/Then | sdd-spec |
| Technical design, HOW | sdd-design |
| Task breakdown, implementation plan | sdd-tasks |
| Apply tasks, implement | sdd-apply |
| Validate vs specs, verify | sdd-verify |
| Archive changes, delta to main | sdd-archive |
| Decision capture, trade-off log | decision-capture |
| Execution mode, quick/thorough/draft | execution-mode |
| Skill digestion, compact on load | skill-digestion |
| Subagent isolation, context boundaries | subagent-isolation |
| Command wrapper, error handling, output parsing | command-wrapper |
| Skill refresher, drift detection, auto-heal | skill-refresher |
| Skill improvement, audit skills, refactor skills | skill-improver |
| CI/CD pipeline, GitHub Actions, quality gate | ci-cd |
| Work-unit commits, commit organization | work-unit-commits |
| Immune System, anti-pattern, permanent immunity | immune-system |
| Auto-score, metrics, post-task evaluation | auto-metrics |
| Metricas, before/after, % improvement, tokenization, delta | metricas |
| Code review, CR, revisar cÃ³digo, criticar | code-review-agent |
| Refactor, refactoring, reestructurar, migrate | refactoring-planner |
| Commit, mensaje, commit message, conventional commit | commit-crafter |
| Mapear, project map, estructura, tech stack, arquitectura | project-mapper |
| Security, seguridad, vulnerabilidad, auditar | security-scanner |
| Bitacora, historial, histÃ³rico, quÃ© pedÃ­, request log | bitacora |
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

- **Specialized**: metricas, bitacora, context-watchdog, recovery-protocol

## Load rule
1. `read` this file → find trigger match → get skill name
2. Try `skill` tool with name (only works if in available_skills)
3. If skill tool fails → `read skills/{name}/SKILL.md` directly from disk
4. If skill has assets → `read skills/{name}/assets/` for templates

**Important**: `gap-analysis`, `project-mapper`, and `intake-verify.ps1` are NOT in available_skills (system limitation). Load them by reading directly:
- `read skills/gap-analysis/SKILL.md`
- `read skills/project-mapper/SKILL.md`
- `read scripts/intake-verify.ps1`
