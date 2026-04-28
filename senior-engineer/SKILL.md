---
name: senior-engineer
description: >
  Habilidades y competencias de senior software engineer.
  Trigger: Cuando usuario pregunta qué hace un senior engineer,
  necesita arquitectura, decisiones de diseño, o delegar tareas.
  También: "trade-offs", "system thinking", "delegation".
license: Apache-2.0
metadata:
  author: mk
  version: "1.0"
---

## Las 15 Competencias del Staff+ Engineer (2026)

Según SkillsBench y research 2026, Estas son **no-reemplazables por AI**:

### Técnicas (5)

| # | Competencia | Descripción | AI Replaceable |
|---|------------|-------------|----------------|
| 1 | **System Design** | Sistemas que duran 5+ años, 100+ contribuidores | ❌ |
| 2 | **Trade-off Analysis** | Decisiones con constraints conocidos | ❌ |
| 3 | **Production Ownership** | SLAs, costo de outage 2am | ❌ |
| 4 | **Security Judgment** | Security decisions escalables | ❌ |
| 5 | **Technical Debt Strategy** | Velocity vs debt balance | ⚠️ Parcial |

### Blandas (5)

| # | Competencia | Descripción |
|---|------------|-------------|
| 6 | **Mentoring** | Multiplicar impacto enseñando |
| 7 | **Cross-Team Communication** | Más allá del equipo |
| 8 | **Stakeholder Management** | Expectativas definidas |
| 9 | **Technical Writing** | RFCs, docs, postmortems |
| 10 | **Delegation** | Qué delegar, qué retener |

### Estratégicas (5)

| # | Competencia | Descripción |
|---|------------|-------------|
| 11 | **Prioritization** | Qué importa más |
| 12 | **Decision-Making** | Decisiones técnicas con evidencia |
| 13 | **Project Leadership** | Fin a fin |
| 14 | **Architectural Judgment** | Qué construir vs qué no |
| 15 | **AI Orchestration** | Coordinar agentes AI |

---

## El Shift Mid → Senior

| Mid-Level Piensa | Senior Piensa |
|----------------|----------------|
| "Cómo implemento esto?" | "Qué problema resuelve?" |
| Features y componentes | Sistemas y trade-offs |
| Código correcto | Código mantenible |
| Mi tarea | Impacto en otros |
| Ejecutar | Hacer ejecutar a otros |

---

## Sistema de Delegación (2026)

### Qué DELEGAR (Buenos Candidatos)

| Tipo | Ejemplo | Pourquoi |
|------|---------|-----------|
| First-draft implementations | Tickets bien scoped | AI rápido |
| Test case generation | coverage tests | AI efectivo |
| Documentación | README, APIs docs | AI genera bien |
| Boilerplate | New services | Estructura conocida |
| Refactoring aislado | Módulos small | Bajo riesgo |

###Qué NO Delegar (Malos Candidatos)

| Tipo | Pourquoi |
|------|----------|
| Security-critical paths | Sin spec ajustada |
| Cross-system integration | Acoplamiento complejo |
| Requisitos ambiguos | AI no puedeask right questions |
| Architectural decisions | Juicio de negocio |
| Emergency response | Contexto de producción |

### El Modelo Delegate-Review-Own

```
1. DELEGATE → Task bien scoped + constraints claros
               ↓
2. REVIEW → Auto-validation de outputs
               ↓
3. OWN → Decision final humana + accountability
```

---

## Agent Lanes ( Guardrails)

```markdown
## Lane 1: GREEN (puede operar libre)
- Refactoring
- Tests
- Documentación
- Bug fixes simples

## Lane 2: YELLOW (propone, espera decisión)
- Nuevas funcionalidades
- Cambios de API
- Integraciones internas

## Lane 3: RED (requiere approval)
- Security
- Datos sensibles
- Breaking changes
- Deployments
```

---

## Architectural Judgment

### Preguntas que Solo Senior Responde

```
1. "¿Qué hace esto a los failure modes del sistema?"
2. "¿Qué nuevo acoplamiento introduce?"
3. "¿Cómo se ve operar esto a las 3am?"
4. "¿Nos acerca o aleja del target en 2 años?"
5. "¿Cuál es el trade-off técnico vs negocio?"
```

### Decision Framework

```
                    ┌─────────────────────┐
                    │   PROBLEM SPACE    │
                    └────────┬──────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼             ▼             ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │ Build   │  │ Buy    │  │ Defer   │
        └────┬───┘  └────────┘  └────────┘
             │
      ┌──────┼──────┐
      ▼            ▼
┌─────────┐  ┌─────────┐
│Now      │  │Never   │
│(scope)  │  │(spike)  │
└─────────┘  └─────────┘
```

---

## Cross-Domain Technical Literacy

### Áreas que Senior Debe Entender

| Dominio | Level Necesario | Para Qué |
|--------|-----------------|----------|
| **Database** | Competent | Joins vs denormalize vs cache |
| **Networking** | Competent | Latencia, gRPC vs REST |
| **Security** | Competent | Data layer vs API vs network |
| **Frontend** | Competent | Rendering, performance |
| **Cloud** | Competent | Cost, scaling |
| **AI/ML** | Competent | RAG, prompts, MCP |

**Cómo desarrollar**: 1 área nueva cada 6 meses, a competency (no mastery).

---

## Code Review: Mid vs Senior

| Mid-Level Revisa | Senior Revisa |
|------------------|--------------|
| Correctitud | Mantenibilidad |
| Tests passing | Claridad |
| Errores obvios | Impacto en otros |
| Style guide | Debt acumulado |
| | Patrones arquitectónicos |

---

## Technical Writing Stack

| Tipo | audiencia | Propósito |
|------|------------|-----------|
| **RFC** | Equipo | Decisions de arquitectura |
| **Design Doc** | Desarrolladores | Implementación |
| **ADR** | Todos | Decisiones aceptadas |
| **Postmortem** | Organización | Learning de incidentes |
| **API Doc** | Consumidores | Contratos |
| **Runbook** | Ops | Operaciones |

---

## Communication: Technical vs Non-Technical

### Technical → Developers
- Precisión
- Diagrams
- Code examples
- Trade-offs explícitos

### Non-Technical → Stakeholders
- Impact framing
- Risk en términos de negocio
- Costo-beneficio
- Timeline реальный

---

## AI Output Validation (Crítico)

### El Problema
> 66% de developers frustrados con AI: "solutions that are almost right, but not quite"

### Validación Checklist
```
□ AI produce output que compila?
□ Cover edge cases reales?
□ Mantiene backward compatibility?
□ No introduce new failure modes?
□ El test coverage es real?
□ El código es mantenible?
□ Follows los patterns del proyecto?
```

### Expectativa Shopify (Farhan Thawar)
> Engineers deben ser "90-95% reliant on AI" pero capaces de identificar single-line errors.

---

## Senior Engineer Persona

```
## Cómo me debería comportar

### Antes de responder
□ ¿Entendí el problema real?
□ ¿Hay ambigüedades que debo clarify?
□ ¿Este cambio tiene side effects?
□ ¿Cómo impacta a otros sistemas?

### Al delegar
□ ¿Scope está claro?
□ ¿Constraints están definidos?
□ ¿Qué Lane es (GREEN/YELLOW/RED)?
□ ¿Qué necesita review?

### Al decidir
□ Tengo evidencia?
□ Conozco los trade-offs?
□ Puedo explicar a non-technical?
□ Estoy dispuesto a own la decisión?

### Al revisar código de AI
□ Compila y corre?
□ Edge cases cubiertos?
□ Tests reales, no fake?
□ Mantenible por otros?
□ Sigue patrones del codebase?
```

---

## Skills de Senior Engineer para Agent

| Skill |Aplicación |
|-------|-----------|
| system_design | Antes de proposal, ask constraints |
| trade_off_analysis | Siempre presentar options |
| delegation | Definir scope + constraints |
| agent_lanes | Clasificar tareas por riesgo |
| code_review | Validate AI outputs real |
| technical_writing | Docs cuando es relevante |
| communication | Adaptar audiencia |

---

## Recursos

- RFC Template: [assets/rfc-template.md](assets/rfc-template.md)
- Decision Matrix: [assets/decision-matrix.md](assets/decision-matrix.md)
- Agent Lanes: [assets/agent-lanes.md](assets/agent-lanes.md)