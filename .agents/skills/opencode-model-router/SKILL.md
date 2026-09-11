---
name: opencode-model-router
description: "Route tasks by model strength — specialized agents for analysis, implementer for execution"
triggers: "model router, routing, delegate or direct, model decision, specialized agent, implementer"
license: Apache-2.0
metadata:
  tags: [engineering, routing, orchestration, multi-model]
  author: gentleman-vMK
  version: "3.1"
token_budget: 3200
---

## Routing Table (FREE 2026-09-10 → reference.md for Security Gate, Strategy, Laguna notes)

> Full detail → docs/skills/opencode-model-router/reference.md.

| Task | Action | Agent | Model (Free vigente) | Ctx | Fallback |
|------|--------|-------|----------------------|-----|----------|
| Security/vulnerability | DELEGATE | `gentleman-security` | Nemotron 3 Ultra Free | 1M | `gentleman-deep` -> `gentleman-vMK` (Big Pickle) |
| SEO/content | DELEGATE | `gentleman-seo` | Nemotron 3 Ultra Free | 1M | `gentleman-vMK` (Big Pickle) |
| Infrastructure/K8s/Terraform | DELEGATE | `gentleman-infra` | Muse Spark 1.3 Contributor Free (code-gen) — SSoT opencode.json | 200K | `gentleman-deep` -> `gentleman-vMK` (Big Pickle) |
| Frontend/UI/a11y | DELEGATE | `gentleman-frontend` | Big Pickle | 200K | `gentleman-quick` -> `gentleman-vMK` (Big Pickle) |
| Performance/profiling | DELEGATE | `gentleman-performance` | Nemotron 3 Ultra Free | 1M | `gentleman-deep` -> `gentleman-vMK` |
| Data/SQL/Python | DELEGATE | `gentleman-datascience` | Big Pickle | 200K | `gentleman-codex` -> `gentleman-vMK` (Big Pickle) |
| Documentation | DELEGATE | `gentleman-docs` | Big Pickle (always free, reasoning) | 200K | `gentleman-vMK` |
| Implement plan | DELEGATE | `gentleman-implementer` | Muse Spark 1.3 Contributor Free (code-gen) | 200K | `gentleman-vMK` (Big Pickle) |
| Architecture/code review | DIRECT | `gentleman-vMK` | — | — | — |
| Quick edit | DIRECT | `gentleman-quick` | Big Pickle | 200K | `gentleman-codex` |
| Script generation | DIRECT | `gentleman-codex` | Muse Spark 1.3 Contributor Free — alt Big Pickle | 200K | `gentleman-quick` (Big Pickle) |
| Default | DIRECT | `gentleman-vMK` | — | — | — |

## Implementer
`gentleman-implementer` (Muse Spark 1.3 Contributor Free — 200K, code-gen) — precise plan execution. No unrequested changes. Alt: Big Pickle.
Avoid: Qwen3.7 Max (re-plans, paid), Nemotron 3 Ultra (over-analyzes).

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
