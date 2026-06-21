# SKILLS INDEX

> Full trigger table for all 69 skills. Read on-demand when AGENTS.md compact table doesn't match.
> Located at project root.
>
> **Version**: 3.1 | **Changelog**: 3.1 (+3 skills: caveman, doc-sync, sdd-onboard); 3.0 (-3 skills post-audit: karpathy-prompt→karpathy-loop, core-web-vitals→performance, skill-refresher→skill-improver)

## Triggers → Skill

| Trigger keywords | Skill |
|------------------|-------|
| Karpathy, less tokens, context compilation | karpathy-loop |
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
| SDD init, bootstrap | sdd (phase 00-init) |
| Explore codebase, pre-design | sdd (phase 01-explore) |
| Proposal, intent, approach | sdd (phase 02-propose) |
| Technical design, HOW | sdd (phase 03-design) |
| Specs, Given/When/Then | sdd (phase 04-spec) |
| Task breakdown, implementation plan | sdd (phase 05-tasks) |
| Apply tasks, implement | sdd (phase 06-apply) |
| Validate vs specs, verify | sdd (phase 07-verify) |
| Archive changes, delta to main | sdd (phase 08-archive) |
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
| Skill refresher, drift detection, auto-heal | skill-improver (merged) |
| Skill improvement, audit skills, refactor skills | skill-improver |
| CI/CD pipeline, GitHub Actions, quality gate | ci-cd |
| Work-unit commits, commit organization | work-unit-commits |
| Immune System, anti-pattern, permanent immunity | immune-system |
| Auto-score, metrics, post-task evaluation | auto-metrics |
| External audit, blind review, second opinion, verificá mi auto-score, contralor externo | external-auditor |
| Metricas, before/after, % improvement, tokenization, delta | metricas |
| Code review, CR, revisar código, criticar | code-review-agent |
| Refactor, refactoring, reestructurar, migrate | refactoring-planner |
| Commit, mensaje, commit message, conventional commit | commit-crafter |
| Mapear, project map, estructura, tech stack, arquitectura | project-mapper |
| Security, seguridad, vulnerabilidad, auditar | security-scanner |
| Bitacora, historial, histórico, qué pedí, request log | bitacora |
| Dreaming, cross-session patterns, memory curation | dreaming |
| Performance score, mobile perf, desktop perf, rendimiento, app score, lighthouse, benchmark | performance-tracker |
| Accessibility, a11y, WCAG, screen reader, keyboard nav, make accessible | accessibility |
| Web performance, speed up, reduce load time, page speed, performance audit | performance |
| SEO, search engine, meta tags, structured data, sitemap, search optimization | seo |
| Core Web Vitals, LCP, INP, CLS, layout shift, page experience | performance (merged) |
| Best practices, security audit, modernize code, code quality review | best-practices |
| Web quality audit, lighthouse audit, review web quality, check page quality | web-quality-audit |
| UI cleanup, polish interface, fix layout, ui slop, generic ui, design review | baseline-ui |
| Performance mode, dev mode, modo desarrollo, resource priority, high performance | development-mode |
| Gap analysis, system audit, identificar gaps, evaluar software | gap-analysis |
| Sparse loading, skill resolution, relevant skills, which skill, resolver skill, minimo skills | skill-graph |
| Research, technical investigation, investigar, learn tech, compare solutions, evaluate options | research |
| Review pipeline, skill stacking, full review, preparar commit, ready to ship, listo para commit | review-pipeline |
| Triple verify, triangulate, 3 enfoques, verificación profunda, !ship, !listo, !fast, !draft | triple-verify |
| Self-improvement, improvement cycle, auto-mejora, ciclo de mejora, comienza ciclo | self-improvement |
| Model router, routing, qué modelo, delegate or direct, qué hacer con esta tarea, trial risk, security gate | opencode-model-router |
| Caveman, ultra-lean, compression, minimal context, emergency mode | caveman |
| Doc sync, documentation sync, sync docs, propagate docs | doc-sync |
| SDD onboarding, guided walkthrough, SDD cycle, teach SDD | sdd-onboard |

## Quick groups
- **Compression/style**: karpathy-loop (merged karpathy-prompt), lean-context
- **Quality**: quality-gate, auto-metrics, external-auditor, immune-system, code-review-agent, performance-tracker, triple-verify, self-improvement
- **Memory**: session-resume, code-memory, dreaming
- **Skills meta**: skill-creator, skill-registry, skill-improver, skill-digestion, skill-graph
- **Coordination**: delivery-harness, chained-pr, branch-pr, issue-creation, subagent-isolation, command-wrapper, opencode-model-router
- **Code ops**: commit-crafter, refactoring-planner, project-mapper, security-scanner
- **SDD**: sdd (SKILL.md) + phases/ (00-init → 08-archive) + sdd-onboard — wrappers at sdd-* for backward compat
- **UI/Design**: baseline-ui, accessibility, performance, seo, web-quality-audit

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

