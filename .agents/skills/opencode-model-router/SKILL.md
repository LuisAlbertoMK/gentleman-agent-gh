---
name: opencode-model-router
description: "Route tasks by model strength — specialized agents for analysis, implementer for execution"
triggers: "model router, routing, delegate or direct, model decision, specialized agent, implementer"
license: Apache-2.0
metadata:
  tags: [engineering, routing, orchestration, multi-model]
  author: gentle-MK
  version: "3.3"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 4400
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

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "I know the best model, skip the table" | Routing by gut feeling, no table row cited | Every DELEGATE/DIRECT cites its Routing Table row (`Task → Agent → Model`) |
| "Small security task, handle it DIRECT" | Security/vuln task handled DIRECT | SSoT rule: security/infra/data/SQL always DELEGATE per table — no size exception |
| "Fallbacks are optional overhead" | DELEGATE with no fallback when primary fails | Fallback column executed on failure; unresolved → escalate to `gentle-MK` |

## Red Flags
- Security/vuln task routed DIRECT instead of DELEGATE → STOP, re-route via Routing Table
- Model assignment diverging from opencode.json SSoT with no fallback → escalate to gentle-MK

## Verification
- Routing decision cites the table row (`Task → Agent → Model`) matching `opencode.json` SSoT
- `Select-String -Path opencode.json -Pattern '<agent>'` confirms the model assignment before DELEGATE
- Fallback executed per row on failure; unresolved → escalate to `gentle-MK`

---
## Reference Materials
Security Gate, Strategy, catálogo → docs/skills/opencode-model-router/reference.md (ADR-048)
Security Gate, Strategy, notas catálogo y detalle extendido -> docs/skills/opencode-model-router/reference.md (ADR-048, cycle32-p2)
---
## Refs
Cross-Refs: delivery-harness | opencode-model-router
