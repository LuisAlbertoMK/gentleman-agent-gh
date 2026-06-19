# SKILLS INDEX

> Full trigger table for all 66 skills. Read on-demand when AGENTS.md compact table doesn't match.
> Located at project root.
>
> **Version**: 2.6 | **Changelog**: 2.6 (Added baseline-ui skill, session-miner.ps1, Ponytail lazy dev ladder, enriched web-quality skills)

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
| Execution mode, resource-adaptive zones, quick/thorough/draft | execution-mode |
| Skill digestion, compact on load | skill-digestion |
| Subagent isolation, context boundaries | subagent-isolation |
| Delivery harness, orchestrate, multi-agent, delegate work | delivery-harness |
| Chained PR, stacked PR, sequential branches, PR chain | chained-pr |
| Command wrapper, error handling, output parsing | command-wrapper |
| Branch PR, branch naming, PR creation, open PR, create pull request | branch-pr |
| Cognitive doc design, doc design, documentation patterns, reduce cognitive load, progressive disclosure | cognitive-doc-design |
| Comment writer, PR feedback, review comment, GitHub comment, write feedback | comment-writer |
| Issue creation, create issue, GitHub issue, bug report, feature request | issue-creation |
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
| Accessibility, a11y, WCAG, screen reader, keyboard nav, make accessible | accessibility |
| Web performance, speed up, reduce load time, page speed, performance audit | performance |
| SEO, search engine, meta tags, structured data, sitemap, search optimization | seo |
| Core Web Vitals, LCP, INP, CLS, layout shift, page experience | core-web-vitals |
| Best practices, security audit, modernize code, code quality review | best-practices |
| Web quality audit, lighthouse audit, review web quality, check page quality | web-quality-audit |
| UI cleanup, polish interface, fix layout, ui slop, generic ui, design review | baseline-ui |
| Performance mode, dev mode, modo desarrollo, resource priority, high performance | development-mode |
| Gap analysis, system audit, identificar gaps, evaluar software | gap-analysis |
| Gap analysis, system audit, identificar gaps, evaluar software | gap-analysis |
| Sparse loading, skill resolution, relevant skills, which skill, resolver skill, minimo skills | skill-graph |
| Research, technical investigation, investigar, learn tech, compare solutions, evaluate options | research |
| Review pipeline, skill stacking, full review, preparar commit, ready to ship, listo para commit | review-pipeline |
| Triple verify, triangulate, 3 enfoques, verificación profunda, !ship, !listo, !fast, !draft | triple-verify |
| Self-improvement, improvement cycle, auto-mejora, ciclo de mejora, comienza ciclo | self-improvement |

## Quick groups
- **Compression/style**: karpathy-prompt, karpathy-loop, lean-context
- **Quality**: quality-gate, auto-metrics, immune-system, code-review-agent, performance-tracker, triple-verify, self-improvement
- **Memory**: session-resume, code-memory, dreaming
- **Skills meta**: skill-creator, skill-registry, skill-improver, skill-digestion, skill-graph
- **Coordination**: delivery-harness, chained-pr, branch-pr, issue-creation, subagent-isolation, command-wrapper
- **Code ops**: commit-crafter, refactoring-planner, project-mapper, security-scanner
- **SDD**: sdd-{init,explore,propose,spec,design,tasks,apply,verify,archive}
- **UI/Design**: baseline-ui, accessibility, performance, seo, core-web-vitals, web-quality-audit

- **Communication**: comment-writer, cognitive-doc-design

- **Specialized**: metricas, bitacora, context-watchdog, recovery-protocol

## Load rule
1. `read` this file → find trigger match → get skill name
2. `skill` tool with name (skills.paths now registered in opencode.json — 55 skills globally discoverable)
3. If `skill` tool fails → `read skills/{name}/SKILL.md` directly from disk
4. If skill has assets → `read skills/{name}/references/` or `read skills/{name}/assets/` for templates

**Skill validation**: use `scripts/skill-validate.ps1` for 3-trial benchmark on any skill change

**Utility scripts**:
- `scripts/ensure-tools.ps1` — verify rg/sg/gh are in PATH
- `scripts/token-count.ps1` — count ~tokens in files (4 chars/token)
- `scripts/bench-file-io.ps1` — benchmark 3 file I/O methods × N runs
- `scripts/skill-graph.ps1` — sparse loading resolver: find relevant skills + deps for any task
- `scripts/pull-upstream.ps1` — sync new/modified skills & scripts from upstream (gentleman-vMK) via git merge. 3 modes: `Check` (drift report), `Apply-New` (safe auto-merge), `Apply-File` (checkout individual file)

**Web-quality skills** mirror: `.agents/skills/{name}/` ←→ `skills/{name}/` (synced via junction)
