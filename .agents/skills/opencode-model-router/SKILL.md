---
name: opencode-model-router
description: "Route tasks by model strength — specialized agents for analysis, implementer for execution"
triggers: "model router, routing, delegate or direct, model decision, specialized agent, implementer"
---

## When to Use
Route tasks by model strength — specialized agents for analy


## ⚠️ SECURITY GATE (always first)
1. Credentials/secrets/PII? → **DIRECT**
2. Recurring task (cron/CI)? → **DIRECT**
3. Context >150K? → **DIRECT**
4. Otherwise → route below.

## 🎯 ROUTING TABLE (FREE TIER)
> Leyenda: ✅ = twin `-sub` existe (delegación real) · ⚠️ = sin twin → DELEGATE cae a fallback `general` (comportamiento esperado hasta crear twin)

| Task | Action | Agent | Model | Fallback |
|------|--------|-------|-------|----------|
| Security/vulnerability ✅ | DELEGATE | `gentleman-security-sub` | Nemotron 3 Ultra Free (1M) | `gentleman-deep-sub` → `general` |
| SEO/content ⚠️ | DELEGATE | `gentleman-seo` | Nemotron 3 Super Free | `general` |
| Infrastructure/K8s/Terraform ⚠️ | DELEGATE | `gentleman-infra` | DeepSeek V4 Flash Free (1M) | `general` |
| Frontend/UI/a11y ⚠️ | DELEGATE | `gentleman-frontend` | Kimi K2.5 Free (262K) | `general` |
| Performance/profiling ⚠️ | DELEGATE | `gentleman-performance` | Nemotron 3 Ultra Free (1M) | `general` |
| Data/SQL/Python ⚠️ | DELEGATE | `gentleman-datascience` | MiMo V2.5 Free | `general` |
| Documentation ⚠️ | DELEGATE | `gentleman-docs` | Big Pickle (always free) | `general` |
| Implement plan ✅ | DELEGATE | `gentleman-implementer-sub` | DeepSeek V4 Flash Free (1M) | `gentleman-quick-sub` → `general` |
| Architecture/code review | DIRECT | `gentleman-vMK` | — | — |
| Quick edit ✅ | DELEGATE | `gentleman-quick-sub` | MiMo V2.5 Free | `general` |
| Script generation | DIRECT | `gentleman-codex` | DeepSeek V4 Flash Free | — |
| Deep debugging/root cause ✅ | DELEGATE | `gentleman-deep-sub` | Nemotron 3 Ultra Free (1M) | `general` |
| Default | DIRECT | `gentleman-vMK` | — | — |

## 🔧 IMPLEMENTER
`gentleman-implementer-sub` (DeepSeek V4 Flash Free) — precise plan execution. No unrequested changes.
**Avoid**: Qwen3.7 Max (re-plans, paid), Nemotron 3 Ultra (over-analyzes).

## ⚠️ RUNTIME REALITY (opencode 1.18.x)
- Los agentes `gentleman-*` (sin sufijo) están declarados `mode: primary` en opencode.json → el Task tool (delegación) NO los expone; solo expone `mode: subagent`.
- Los **twins `-sub`** (`gentleman-implementer-sub`, `gentleman-security-sub`, `gentleman-deep-sub`, `gentleman-quick-sub`) SÍ son delegables: `mode: subagent` + `hidden: true` + habilitados en la whitelist `task` del orchestrator (`permission-templates.json` → template `orchestrator`).
- DELEGATE ✅ = usar el twin. DELEGATE ⚠️ (sin twin) = cae a `general` — NO reportar como falla.
- ✅ **Regenerado**: `opencode.json` está en sync con la SSoT (1643 líneas). Mantenerlo así: `scripts/regenerate-opencode.ps1` (validate por defecto; `-Yes` regenera + verifica fail-closed). El CI `--validate` falla si deriva.

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
execution-mode · delivery-harness · subagent-isolation · skill-graph

## Anti-Patterns
Route sensitive data to subagent · Delegate when context >150K · Skip fallback chain · Route to paid model when free covers it · Forget security gate
