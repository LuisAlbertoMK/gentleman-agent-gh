# Specialized Agents

> Agent definitions live in `opencode.json`. This file contains only deployment notes.

## Notes
- All `gentleman-*` agents (except vMK) now use file-based prompts (`prompts/gentleman-{role}.md`)
- All `gentleman-*` specialist agents (security/seo/infra/frontend/performance/datascience/docs) use `{file:prompts/shared/_analyze-only-protocol.md}` for shared analyze-only behavior, cross-agent handoff format, output budget, and graceful degradation
- gentleman-vMK, gentleman-deep, gentleman-quick, gentleman-codex use `{file:prompts/shared/_core-behavior-gp.md}` (GP-specific: tool constraints, return format, no unachievable orchestration rules)
- gentleman-implementer uses `{file:prompts/gentleman-implementer.md}` + `{file:prompts/shared/_core-behavior.md}`
- All `sdd-*` agents use file-based prompts (`prompts/sdd/*.md`) that redirect to SKILL.md
- All `gentleman-*` agents except vMK have granular bash deny rules (17 commands)
- gentleman-vMK inherits global permissions (orchestrator role)
- All agents have write/edit deny for .env, credentials, secrets, opencode.json, AGENTS.md
- Specialist prompts v3 (Jul 2026): 500-1200 tokens each, model-appropriate, with domain-specific scan protocols, grep patterns, severity tables, and output schemas
- gentleman-frontend and gentleman-seo prompts improved in v3 (2026-07-18)
- gentleman-security prompt expanded v3: 7 phases (OWASP mapping, supply chain, container/API, LLM risks), security-scanner v1.2 with supply chain + API security patterns (2026-07-18)
- New security skills: auth-hardening (JWT/OAuth/RBAC/CSRF), container-security (Dockerfile/K8s), llm-security (prompt injection/RAG/tool privilege) — fills OWASP #1+#7 gap and modern threat surfaces (2026-07-18)
- 8 new General Purpose skills: deep-debugging, quick-executor, code-generation, infra-audit, perf-profiling, data-quality, docs-audit, plan-execution — extracts GP agent expertise into reusable skills with !breaker verification (2026-07-18)
