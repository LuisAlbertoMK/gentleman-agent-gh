---
name: opencode-model-router
description: "Route tasks by model strength — specialized agents for analysis, implementer for execution"
triggers: "model router, routing, delegate or direct, model decision, specialized agent, implementer"
license: Apache-2.0
metadata:
  tags: [engineering, routing, orchestration, multi-model]
  author: gentleman-vMK
  version: "3.0"
---

# opencode-model-router v3

Delegate vs direct based on task type and model strength.

## ⚠️ SECURITY GATE (always first)
1. Credentials/secrets/PII? → **DIRECT**
2. Recurring task (cron/CI)? → **DIRECT**
3. Context >150K? → **DIRECT**
4. Otherwise → route below.

## 🎯 ROUTING TABLE

| Task | Action | Agent | Model | Fallback |
|------|--------|-------|-------|----------|
| Security/vulnerability | DELEGATE | `gentleman-security` | Qwen3.7 Max | `gentleman-deep` → `gentleman-vMK` |
| SEO/content | DELEGATE | `gentleman-seo` | Qwen3.7 Plus | `gentleman-vMK` |
| Infrastructure/K8s/Terraform | DELEGATE | `gentleman-infra` | GLM-5.2 | `gentleman-deep` → `gentleman-vMK` |
| Frontend/UI/a11y | DELEGATE | `gentleman-frontend` | Kimi K2.6 | `gentleman-quick` → `gentleman-vMK` |
| Performance/profiling | DELEGATE | `gentleman-performance` | Qwen3.7 Max | `gentleman-deep` → `gentleman-vMK` |
| Data/SQL/Python | DELEGATE | `gentleman-datascience` | GLM-5.1 | `gentleman-codex` → `gentleman-vMK` |
| Documentation | DELEGATE | `gentleman-docs` | MiMo V2.5 Pro | `gentleman-vMK` |
| Implement plan | DELEGATE | `gentleman-implementer` | MiMo V2.5 Pro | `gentleman-vMK` |
| Architecture/code review | DIRECT | `gentleman-vMK` | — | — |
| Quick edit | DIRECT | `gentleman-quick` | MiMo V2.5 | `gentleman-codex` |
| Script generation | DIRECT | `gentleman-codex` | DeepSeek V4 Flash | `gentleman-quick` |
| Default | DIRECT | `gentleman-vMK` | — | — |

## 🔧 IMPLEMENTER

`gentleman-implementer` (MiMo V2.5 Pro) — executes plans precisely. Does NOT "improve" things not asked.

**DO NOT use**: Qwen3.7 Max (re-plans), Nemotron 3 Ultra (over-analyzes).

## 📏 CONTEXT → ACTION

| Context | Action |
|---------|--------|
| <50K | Normal routing |
| 50K-100K | Prefer fast models |
| >150K | Direct forced |

## 💡 STRATEGY

- **90%**: Cheap models (Qwen3.7 Plus, DeepSeek V4 Flash, MiMo V2.5)
- **10%**: Expensive (Qwen3.7 Max, GLM-5.2) for critical analysis only
- **Long context**: Kimi K2.6 or Qwen3.7 Plus (1M tokens)

`ponytail:` v3 routing. Specialized analyze, implementer executes. No mid-task changes.
