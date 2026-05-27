# Gentle-AI + Engram → SR Engineer & Startup completo

## Ecosistema actual (full-gentleman)

| Componente | Qué hace |
|---|---|
| **Engram** | Memoria cross-session (Go + SQLite + FTS5 + MCP) |
| **SDD** | Spec-Driven Development (9 fases) |
| **Skills** | 14 foundation + Gentleman-Skills (Angular, React 19, TS, Tailwind…) |
| **Context7** | MCP server para docs en tiempo real |
| **GGA** | AI provider switcher |
| **Persona + Permissions** | Modo mentoring + seguridad base |

---

## Gaps identificados

### → Como SR Engineer

| Gap | Por qué importa |
|---|---|
| CI/CD integration real | Solo corre local; sin pipeline |
| TDD con evidencia verificable | "Strict TDD" mencionado, sin enforcement real |
| Observabilidad producción | Sin logs, métricas, alertas |
| Seguridad / secretos | No maneja .env, vaults, IAM |
| Code review automatizado | Sin linting gate + type-check bloqueante |
| Dominio específico | El agente no sabe de tu negocio sin contexto manual |

### → Como Startup completo

| Gap | Por qué importa |
|---|---|
| Multi-tenancy | Engram es single-user local |
| Auth + billing | Zero soporte |
| Infra cloud reproducible | Sin IaC (Terraform/Pulumi) |
| Data pipeline | Sin analytics ni observabilidad de producto |
| Compliance | Sin audit trail, GDPR, SOC2 |
| Onboarding de clientes | Setup sigue siendo CLI-heavy |

---

## Cómo llenar los gaps

### SR Engineer

| Gap | Solución | Cómo |
|---|---|---|
| CI/CD real | GitHub Actions gate | Skill de GHA con linting/typecheck bloqueante pre-merge |
| TDD verificable | Pre-commit hook con evidencia | GGA hook → test run → falla = no commit |
| Observabilidad | Sentry MCP | Skill que el agente llama al detectar errores runtime |
| Secretos | `.env` + Vault skill | Skill que audita que ningún secret toca Engram |
| Code review | PR skill con checklist SDD | Branch → SDD verify → PR con evidencia adjunta |

### Startup

| Gap | Solución | Por qué esa |
|---|---|---|
| Auth | Clerk o Supabase Auth | SaaS, cero infra propia |
| Billing | Stripe + MCP tool | Ya existe MCP de Stripe |
| Multi-tenancy | Schema-per-tenant en DB | Aislamiento sin complejidad de app |
| IaC | Pulumi (TypeScript) | Skill nativo + mismo lenguaje del stack |
| Analytics producto | PostHog self-hosted | Open source, sin vendor lock |
| Onboarding | Web wizard → genera config | Reemplaza el CLI TUI para clientes |
| Audit/Compliance | Engram Cloud como audit trail | Ya persiste decisiones, extenderlo |

---

## Arquitectura objetivo

```
Cliente → Web wizard (onboarding)
         ↓
    Auth (Clerk) + Billing (Stripe)
         ↓
    Tu producto (Gentle-AI as SaaS)
         ↓
    Engram Cloud (memoria compartida multi-tenant)
         ↓
    Pulumi (infra reproducible)
         ↓
    PostHog + Sentry (analytics + observabilidad)
```

---

## Orden de construcción

1. **Auth** — sin auth no hay producto
2. **Billing** — sin billing no hay negocio
3. **IaC** — sin infra reproducible no hay escala
4. **Engram multi-tenant** — núcleo del producto
5. **Onboarding web** — sin esto solo llegan devs
6. **Analytics** — sin datos no hay decisiones
7. **Compliance** — sin esto no hay enterprise

---

## Skills a crear (Gentle-AI extension)

| Skill | Función |
|---|---|
| `ci-github-actions` | Pipeline con lint + test + type-check gate |
| `pre-commit-tdd` | Hook que bloquea commit sin test evidence |
| `sentry-mcp` | Observabilidad runtime desde el agente |
| `vault-audit` | Detecta secrets antes de que lleguen a Engram |
| `pr-sdd-checklist` | PR con evidencia SDD adjunta automática |
| `pulumi-infra` | IaC en TypeScript con el mismo stack |
| `stripe-billing` | Billing events desde el agente |
| `posthog-analytics` | Eventos de producto desde el agente |

---

*Análisis basado en Gentleman-Programming/gentle-ai + Gentleman-Programming/engram — Mayo 2026*
