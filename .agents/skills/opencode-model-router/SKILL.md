---
name: opencode-model-router
description: "Route tasks by model strength — specialized agents for analysis, implementer for execution"
triggers: "model router, routing, delegate or direct, model decision, specialized agent, implementer"
license: Apache-2.0
metadata:
  tags: [engineering, routing, orchestration, multi-model]
  author: gentleman-vMK
  version: "3.0"
  changelog: "3.0: initial tracked version"
---

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
`gentleman-implementer` (DeepSeek V4 Flash Free) — precise plan execution. No unrequested changes.
**Avoid**: Qwen3.7 Max (re-plans, paid), Nemotron 3 Ultra (over-analyzes).

## 📏 CONTEXT → ACTION
| Context | Action |
|---------|--------|
| <50K | Normal routing |
| 50K-100K | Prefer fast models |
| >150K | Direct forced |

## 💡 STRATEGY (FREE)
- **100% Free**: All Zen free models, no subscription
- **1M context**: Nemotron 3 Ultra Free, DeepSeek V4 Flash Free
- **Vision**: Kimi K2.5 Free, MiMo V2.5 Free
- **Fallback**: Big Pickle (docs, SEO, general)

## Refs
execution-mode · delivery-harness · subagent-isolation · skill-graph · senior-engineer

## Anti-Patterns
Route sensitive data to subagent · Delegate when context >150K · Skip fallback chain · Route to paid model when free covers it · Forget security gate
