# Specialized Agents — Manual Review

Total: 22 agents

| Agent | Role | Prompt Source |
|-------|------|---------------|
| gentleman-vMK | Senior Architect mentor - helpful first, challenging when it matters | inline (1 lines) |
| gentleman-deep | Deep reasoning specialist - architecture, complex debugging, multi-file refactors | inline (3 lines) |
| gentleman-quick | Fast executor - quick edits, localized changes, simple tasks | inline (3 lines) |
| gentleman-codex | Code generation specialist - general coding, tool calling, scripts | inline (3 lines) |
| gentleman-security | Security specialist - vulnerability analysis, secure code review, attack pattern detection (FREE TIER) | inline (3 lines) |
| gentleman-seo | Technical SEO analyst - crawlability, structured data validation, on-page audit, CWV, GEO readiness (FREE TIER) | inline (3 lines) |
| gentleman-infra | Infrastructure specialist - IaC, Kubernetes, Terraform, CI/CD pipelines, cloud architecture (FREE TIER) | inline (3 lines) |
| gentleman-frontend | Frontend architecture analyst - component patterns, design system audit, CSS architecture, accessibility compliance (FREE TIER) | inline (3 lines) |
| gentleman-performance | Performance specialist - code optimization, query tuning, load testing, bottleneck analysis (FREE TIER) | inline (3 lines) |
| gentleman-datascience | Data science specialist - Python (Pandas, Polars), SQL, data visualization, statistical analysis (FREE TIER) | inline (3 lines) |
| gentleman-docs | Documentation specialist - technical writing, API docs, READMEs, ADRs, clean structured output (FREE TIER) | inline (3 lines) |
| gentleman-implementer | Plan executor specialist — implements plans from specialized agents, no deviations (FREE TIER) | prompts/gentleman-implementer.md |
| sdd-apply | Implement code changes from task definitions | prompts/sdd/sdd-apply.md |
| sdd-archive | Archive completed change artifacts | prompts/sdd/sdd-archive.md |
| sdd-design | Create technical design from proposals | prompts/sdd/sdd-design.md |
| sdd-explore | Investigate codebase and think through ideas | prompts/sdd/sdd-explore.md |
| sdd-init | Bootstrap SDD context and project configuration | prompts/sdd/sdd-init.md |
| sdd-orchestrator | SDD Orchestrator - coordinates sub-agents, never does work inline | prompts/sdd/sdd-orchestrator.md |
| sdd-propose | Create change proposals from explorations | prompts/sdd/sdd-propose.md |
| sdd-spec | Write detailed specifications from proposals | prompts/sdd/sdd-spec.md |
| sdd-tasks | Break down specs and designs into implementation tasks | prompts/sdd/sdd-tasks.md |
| sdd-verify | Validate implementation against specs | prompts/sdd/sdd-verify.md |

## Categories

### Orchestrator (1)
- **sdd-orchestrator**: SDD Orchestrator - coordinates sub-agents, never does work inline

### SDD Pipeline (9)
- **sdd-apply**: Implement code changes from task definitions
- **sdd-archive**: Archive completed change artifacts
- **sdd-design**: Create technical design from proposals
- **sdd-explore**: Investigate codebase and think through ideas
- **sdd-init**: Bootstrap SDD context and project configuration
- **sdd-propose**: Create change proposals from explorations
- **sdd-spec**: Write detailed specifications from proposals
- **sdd-tasks**: Break down specs and designs into implementation tasks
- **sdd-verify**: Validate implementation against specs

### Security/Quality (1)
- **gentleman-security**: Security specialist - vulnerability analysis, secure code review, attack pattern detection (FREE TIER)

### UI/UX/Design (2)
- **gentleman-seo**: Technical SEO analyst - crawlability, structured data validation, on-page audit, CWV, GEO readiness (FREE TIER)
- **gentleman-frontend**: Frontend architecture analyst - component patterns, design system audit, CSS architecture, accessibility compliance (FREE TIER)

### General Purpose (9)
- **gentleman-vMK**: Senior Architect mentor - helpful first, challenging when it matters
- **gentleman-deep**: Deep reasoning specialist - architecture, complex debugging, multi-file refactors
- **gentleman-quick**: Fast executor - quick edits, localized changes, simple tasks
- **gentleman-codex**: Code generation specialist - general coding, tool calling, scripts
- **gentleman-infra**: Infrastructure specialist - IaC, Kubernetes, Terraform, CI/CD pipelines, cloud architecture (FREE TIER)
- **gentleman-performance**: Performance specialist - code optimization, query tuning, load testing, bottleneck analysis (FREE TIER)
- **gentleman-datascience**: Data science specialist - Python (Pandas, Polars), SQL, data visualization, statistical analysis (FREE TIER)
- **gentleman-docs**: Documentation specialist - technical writing, API docs, READMEs, ADRs, clean structured output (FREE TIER)
- **gentleman-implementer**: Plan executor specialist — implements plans from specialized agents, no deviations (FREE TIER)

## Notes
- All `gentleman-*` agents (except vMK) have 3-line inline prompts
- All `sdd-*` agents use file-based prompts (prompts/sdd/*.md)
- All `gentleman-*` agents except vMK have granular bash deny rules (17 commands)
- gentleman-vMK inherits global permissions (orchestrator role)
- All agents have write/edit deny for .env, credentials, secrets, opencode.json, AGENTS.md
- gentleman-frontend and gentleman-seo prompts improved in v3 (2026-07-18)
