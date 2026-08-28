---
name: opencode-model-router
description: "Route tasks by model strength — specialized agents for analysis, implementer for execution"
triggers: "model router, routing, delegate or direct, model decision, specialized agent, implementer"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1908
---
## ⚠️ SECURITY GATE (always first)
1. Credentials/PII? → **DIRECT** 2. Recurring (cron/CI)? → **DIRECT** 3. Context >150K? → **DIRECT** 4. Else → route below.
## 🎯 ROUTING TABLE (FREE TIER)
> ✅ = twin `-sub` delegable · ⚠️ = sin twin → `general`
| Task | Action | Agent | Model | Fallback |
|------|--------|-------|-------|----------|
| Security/vulnerability ✅ | DELEGATE | `gentleman-security-sub` | Nemotron Ultra (1M) | `gentleman-deep-sub` → `general` |
| SEO/content ✅ | DELEGATE | `gentleman-seo-sub` | Nemotron Super | `gentleman-deep-sub` → `general` |
| Infrastructure/K8s/Terraform ✅ | DELEGATE | `gentleman-infra-sub` | DeepSeek V4 (1M) | `general` |
| Frontend/UI/a11y ✅ | DELEGATE | `gentleman-frontend-sub` | Kimi K2.5 (262K) | `general` |
| Performance/profiling ✅ | DELEGATE | `gentleman-performance-sub` | Nemotron Ultra (1M) | `general` |
| Data/SQL/Python ✅ | DELEGATE | `gentleman-datascience-sub` | MiMo V2.5 | `general` |
| Documentation ✅ | DELEGATE | `gentleman-docs-sub` | Big Pickle | `general` |
| Implement plan ✅ | DELEGATE | `gentleman-implementer-sub` | DeepSeek V4 (1M) | `gentleman-quick-sub` → `general` |
| Architecture/code review | DIRECT | `gentleman-vMK` | — | — |
| Quick edit ✅ | DELEGATE | `gentleman-quick-sub` | MiMo V2.5 | `general` |
| Script generation | DIRECT | `gentleman-codex` | DeepSeek V4 | — |
| Deep debugging/root cause ✅ | DELEGATE | `gentleman-deep-sub` | Nemotron Ultra (1M) | `general` |
| Default | DIRECT | `gentleman-vMK` | — | — |
## Reference
> docs/skills/opencode-model-router/reference.md
## Refs
Cross-Refs: skill-graph | skill-registry
