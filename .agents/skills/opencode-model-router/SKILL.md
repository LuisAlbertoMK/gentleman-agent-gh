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

## 🎯 ROUTING TABLE (FREE TIER)

| Task | Action | Agent | Model | Fallback |
|------|--------|-------|-------|----------|
| Security/vulnerability | DELEGATE | `gentleman-security` | Nemotron 3 Ultra Free (1M) | `gentleman-deep` → `gentleman-vMK` |
| SEO/content | DELEGATE | `gentleman-seo` | Nemotron 3 Super Free | `gentleman-vMK` |
| Infrastructure/K8s/Terraform | DELEGATE | `gentleman-infra` | DeepSeek V4 Flash Free (1M) | `gentleman-deep` → `gentleman-vMK` |
| Frontend/UI/a11y | DELEGATE | `gentleman-frontend` | Kimi K2.5 Free (262K) | `gentleman-quick` → `gentleman-vMK` |
| Performance/profiling | DELEGATE | `gentleman-performance` | Nemotron 3 Ultra Free (1M) | `gentleman-deep` → `gentleman-vMK` |
| Data/SQL/Python | DELEGATE | `gentleman-datascience` | MiMo V2.5 Free | `gentleman-codex` → `gentleman-vMK` |
| Documentation | DELEGATE | `gentleman-docs` | Big Pickle (always free) | `gentleman-vMK` |
| Implement plan | DELEGATE | `gentleman-implementer` | DeepSeek V4 Flash Free (1M) | `gentleman-vMK` |
| Architecture/code review | DIRECT | `gentleman-vMK` | — | — |
| Quick edit | DIRECT | `gentleman-quick` | MiMo V2.5 Free | `gentleman-codex` |
| Script generation | DIRECT | `gentleman-codex` | DeepSeek V4 Flash Free | `gentleman-quick` |
| Default | DIRECT | `gentleman-vMK` | — | — |

## 🔧 IMPLEMENTER

`gentleman-implementer` (DeepSeek V4 Flash Free) — executes plans precisely. Does NOT "improve" things not asked.

**DO NOT use**: Qwen3.7 Max (re-plans, paid), Nemotron 3 Ultra (over-analyzes for execution).

## 📏 CONTEXT → ACTION

| Context | Action |
|---------|--------|
| <50K | Normal routing |
| 50K-100K | Prefer fast models |
| >150K | Direct forced |

## 💡 STRATEGY (FREE)

- **100% Free**: All agents use Zen free models — no subscription needed
- **1M context**: Nemotron 3 Ultra Free, DeepSeek V4 Flash Free
- **Vision**: Kimi K2.5 Free, MiMo V2.5 Free
- **Always free fallback**: Big Pickle (docs, SEO, general)

`ponytail:` v4 routing. All free. Specialized analyze, implementer executes. No mid-task changes.
