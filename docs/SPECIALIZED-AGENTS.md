# Specialized Agents — Manual Review

Total: 22 agents

| Agent | Role | Prompt Source |
|-------|------|---------------|
| gentleman-vMK | Senior Architect mentor - helpful first, challenging when it matters | inline (1 lines) |
| gentleman-deep | Deep reasoning specialist - architecture, complex debugging, multi-file refactors | inline + _core-behavior.md |
| gentleman-quick | Fast executor - quick edits, localized changes, simple tasks | inline + _core-behavior.md |
| gentleman-codex | Code generation specialist - general coding, tool calling, scripts | inline + _core-behavior.md |
| gentleman-security | Security specialist - STRIDE threat model, CVSS scoring, OWASP Top 10, injection/XSS/auth analysis (FREE TIER) | prompts/gentleman-security.md + _analyze-only-protocol.md |
| gentleman-seo | Technical SEO analyst - three-pillar audit (Technical/On-Page/Content), E-E-A-T, GEO readiness, schema validation (FREE TIER) | prompts/gentleman-seo.md + _analyze-only-protocol.md |
| gentleman-infra | Infrastructure specialist - container security, K8s reliability, IaC quality, CI/CD security, dependency graphs (FREE TIER) | prompts/gentleman-infra.md + _analyze-only-protocol.md |
| gentleman-frontend | Frontend auditor - WCAG 2.2 AA (POUR), component architecture, design tokens, performance indicators (FREE TIER) | prompts/gentleman-frontend.md + _analyze-only-protocol.md |
| gentleman-performance | Performance specialist - Amdahl's Law, code complexity, N+1 detection, memory analysis, profiling-driven optimization (FREE TIER) | prompts/gentleman-performance.md + _analyze-only-protocol.md |
| gentleman-datascience | Data science specialist - data quality framework, anti-patterns (apply/iterrows), SQL audit, statistical validity (FREE TIER) | prompts/gentleman-datascience.md + _analyze-only-protocol.md |
| gentleman-docs | Documentation specialist - Diátaxis framework, completeness audit, content quality, cognitive load analysis (FREE TIER) | prompts/gentleman-docs.md + _analyze-only-protocol.md |
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

### Security/Quality (4)
- **gentleman-security**: Security specialist - OWASP Top 10, supply chain integrity, LLM-specific risks, container/API security, attack pattern detection (FREE TIER)
- **auth-hardening**: JWT, OAuth, RBAC, CSRF, session management, password hashing audit
- **container-security**: Dockerfile, docker-compose, K8s manifest security hardening
- **llm-security**: Prompt injection, data exfiltration, RAG poisoning, tool-use privilege escalation

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
- All `gentleman-*` agents (except vMK) now use file-based prompts (`prompts/gentleman-{role}.md`)
- All `gentleman-*` specialist agents (security/seo/infra/frontend/performance/datascience/docs) use `{file:prompts/shared/_analyze-only-protocol.md}` for shared analyze-only behavior, cross-agent handoff format, output budget, and graceful degradation
- gentleman-vMK, gentleman-deep, gentleman-quick, gentleman-codex use `{file:prompts/shared/_core-behavior.md}` for core behavior rules
- gentleman-implementer uses `{file:prompts/gentleman-implementer.md}` + `{file:prompts/shared/_core-behavior.md}`
- All `sdd-*` agents use file-based prompts (`prompts/sdd/*.md`) that redirect to SKILL.md
- All `gentleman-*` agents except vMK have granular bash deny rules (17 commands)
- gentleman-vMK inherits global permissions (orchestrator role)
- All agents have write/edit deny for .env, credentials, secrets, opencode.json, AGENTS.md
- Specialist prompts v3 (Jul 2026): 500-1200 tokens each, model-appropriate, with domain-specific scan protocols, grep patterns, severity tables, and output schemas
- gentleman-frontend and gentleman-seo prompts improved in v3 (2026-07-18)
- gentleman-security prompt expanded v3: 7 phases (OWASP mapping, supply chain, container/API, LLM risks), security-scanner v1.2 with supply chain + API security patterns (2026-07-18)
- New security skills: auth-hardening (JWT/OAuth/RBAC/CSRF), container-security (Dockerfile/K8s), llm-security (prompt injection/RAG/tool privilege) — fills OWASP #1+#7 gap and modern threat surfaces (2026-07-18)
