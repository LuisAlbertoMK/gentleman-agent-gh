---
name: opencode-model-router
description: "Route tasks by model strength — specialized agents for analysis, implementer for execution"
triggers: "model router, routing, delegate or direct, model decision, specialized agent, implementer"
license: Apache-2.0
metadata:
  tags: [engineering, routing, orchestration, multi-model]
  author: gentle-MK
  version: "3.3"
token_budget: 3200
---

## Routing Table (SSoT opencode.json 2026-09-18 → reference.md for Security Gate, Strategy, Catalog)

> ⚠️ **Skill is NOT SSoT** — opencode.json is the source of truth. This table reflects actual model assignments.
> Full detail → docs/skills/opencode-model-router/reference.md.

| Task | Action | Agent | Model (SSoT opencode.json) | Ctx | Fallback |
|------|--------|-------|----------------------------|-----|----------|
| Security/vulnerability | DELEGATE | `gentleman-security` | DeepSeek V4 Flash (`opencode-go/deepseek-v4-flash`) | — | `gentleman-deep` -> `gentle-MK` |
| SEO/content | DELEGATE | `gentleman-seo` | DeepSeek V4 Flash (`opencode-go/deepseek-v4-flash`) | — | `gentle-MK` |
| Infrastructure/K8s/Terraform | DELEGATE | `gentleman-infra` | MiMo V2.5 (`opencode-go/mimo-v2.5`) | — | `gentleman-deep` -> `gentle-MK` |
| Frontend/UI/a11y | DELEGATE | `gentleman-frontend` | Muse Spark 1.3 Contributor (`opencode-go/muse-spark-1.3-contributor`) | — | `gentleman-quick` -> `gentle-MK` |
| Performance/profiling | DELEGATE | `gentleman-performance` | DeepSeek V4 Flash (`opencode-go/deepseek-v4-flash`) | — | `gentleman-deep` -> `gentle-MK` |
| Data/SQL/Python | DELEGATE | `gentleman-datascience` | Muse Spark 1.3 Contributor (`opencode-go/muse-spark-1.3-contributor`) | — | `gentleman-codex` -> `gentle-MK` |
| Documentation | DELEGATE | `gentleman-docs` | Muse Spark 1.3 Contributor (`opencode-go/muse-spark-1.3-contributor`) | — | `gentle-MK` |
| Implement plan | DELEGATE | `gentleman-implementer` | MiMo V2.5 (`opencode-go/mimo-v2.5`) | — | `gentle-MK` |
| Architecture/code review | DIRECT | `gentle-MK` | Muse Spark 1.3 Contributor (`opencode-go/muse-spark-1.3-contributor`) | — | — |
| Quick edit | DIRECT | `gentleman-quick` | Muse Spark 1.3 Contributor (`opencode-go/muse-spark-1.3-contributor`) | — | `gentleman-codex` |
| Script generation | DIRECT | `gentleman-codex` | MiMo V2.5 (`opencode-go/mimo-v2.5`) | — | `gentleman-quick` |
| Default | DIRECT | `gentle-MK` | Muse Spark 1.3 Contributor (`opencode-go/muse-spark-1.3-contributor`) | — | — |

## Implementer
`gentleman-implementer` (MiMo V2.5 — `opencode-go/mimo-v2.5`) — precise plan execution. No unrequested changes.
Avoid: Qwen 3.7 Plus (`opencode-go/qwen3.7-plus`, re-plans), DeepSeek V4 Flash (over-analyzes).

## Context -> Action
| Context | Action |
|---------|--------|
| <50K | Normal routing |
| 50K-100K | Prefer fast models |
| >150K | Direct forced |

---
## Reference Materials
Security Gate, Strategy, catálogo → docs/skills/opencode-model-router/reference.md (ADR-048)
Security Gate, Strategy, notas catálogo y detalle extendido -> docs/skills/opencode-model-router/reference.md (ADR-048, cycle32-p2)
---
## Refs
Cross-Refs: delivery-harness | opencode-model-router
