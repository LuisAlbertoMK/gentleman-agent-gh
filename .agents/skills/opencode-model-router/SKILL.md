---
name: opencode-model-router
description: "Route tasks by model strength — specialized agents for analysis, implementer for execution"
triggers: "model router, routing, delegate or direct, model decision, specialized agent, implementer"
changelog: docs/ciclos/cycle28-20260815.md
---

## ⚠️ SECURITY GATE (always first)
1. Credentials/secrets/PII? → **DIRECT**
2. Recurring task (cron/CI)? → **DIRECT**
3. Context >150K? → **DIRECT**
4. Otherwise → route below.

## 🎯 ROUTING TABLE (FREE TIER)
> ✅ = twin `-sub` delegable · ⚠️ = sin twin → `general`

| Task | Action | Agent | Model | Fallback |
|------|--------|-------|-------|----------|
| Security/vulnerability ✅ | DELEGATE | `gentleman-security-sub` | Nemotron 3 Ultra Free (1M) | `gentleman-deep-sub` → `general` |
| SEO/content ✅ | DELEGATE | `gentleman-seo-sub` | Nemotron 3 Super Free | `gentleman-deep-sub` → `general` |
| Infrastructure/K8s/Terraform ✅ | DELEGATE | `gentleman-infra-sub` | DeepSeek V4 Flash Free (1M) | `general` |
| Frontend/UI/a11y ✅ | DELEGATE | `gentleman-frontend-sub` | Kimi K2.5 Free (262K) | `general` |
| Performance/profiling ✅ | DELEGATE | `gentleman-performance-sub` | Nemotron 3 Ultra Free (1M) | `general` |
| Data/SQL/Python ✅ | DELEGATE | `gentleman-datascience-sub` | MiMo V2.5 Free | `general` |
| Documentation ✅ | DELEGATE | `gentleman-docs-sub` | Big Pickle (always free) | `general` |
| Implement plan ✅ | DELEGATE | `gentleman-implementer-sub` | DeepSeek V4 Flash Free (1M) | `gentleman-quick-sub` → `general` |
| Architecture/code review | DIRECT | `gentleman-vMK` | — | — |
| Quick edit ✅ | DELEGATE | `gentleman-quick-sub` | MiMo V2.5 Free | `general` |
| Script generation | DIRECT | `gentleman-codex` | DeepSeek V4 Flash Free | — |
| Deep debugging/root cause ✅ | DELEGATE | `gentleman-deep-sub` | Nemotron 3 Ultra Free (1M) | `general` |
| Default | DIRECT | `gentleman-vMK` | — | — |

## 🔧 IMPLEMENTER
`gentleman-implementer-sub` (DeepSeek V4 Flash Free) — precise execution. No unrequested changes.
**Avoid**: Qwen3.7 Max (re-plans, paid), Nemotron 3 Ultra (over-analyzes).

## ⚠️ RUNTIME REALITY (opencode 1.18.x)
- `gentleman-*` sin sufijo = `mode: primary` → Task tool NO los expone.
- Twins `-sub` (implementer/security/deep/quick) SÍ: `subagent` + `hidden` + whitelist `task` (template `orchestrator`).
- DELEGATE ✅ = twin. DELEGATE ⚠️ = `general` — NO reportar falla.
- `opencode.json` sync SSoT: `scripts/regenerate-opencode.ps1` (`-Yes` regenera; CI falla si deriva).

## 📏 CONTEXT → ACTION
| Context | Action |
|---------|--------|
| <50K | Normal routing |
| 50K-100K | Prefer fast models |
| >150K | Direct forced |

---

> See [reference.md](docs/skills/opencode-model-router/reference.md) for extended details, examples, and detailed patterns.