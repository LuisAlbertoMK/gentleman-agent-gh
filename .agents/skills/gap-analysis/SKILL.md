---
name: gap-analysis
description: Complete gap analysis for any system — 8-dim quality framework, project intake, priority scoring
triggers: "Gap analysis, system audit, identificar gaps, evaluar software, project intake"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.1"
  changelog: "2.2: trimmed 17%"
---
## Phase 0: Project Intake
**Classify**: Tech: Frontend|Backend|DB|Mobile|Desktop|Infra|Full-stack · Biz: SaaS|ERP|E-com|CMS|API|Web|Desktop|Mobile
**Verify**: ROADMAP.md | git log -10 | PRD*,*spec*,*requirements* | README.md | tests/__tests__/spec | .github/Jenkinsfile/.gitlab-ci.yml | *monitor*,*grafana*,*datadog*
## 8 Quality Dimensions
| # | Dim | Primary | What |
|---|-----|---------|------|
| 1 | UI/UX | UX | Design, interaction, flows, a11y |
| 2 | Security | Security | Auth, encryption, vulns, secrets, compliance |
| 3 | Optimization | Technical | Bundle, code splitting, caching, lazy loading |
| 4 | Performance | Technical | Load/render time, API latency, DB queries |
| 5 | Resource Usage | Ops | Memory, CPU, storage, network |
| 6 | Project Velocity | Business | Build time, dev loop, CI/CD speed |
| 7 | Responsive Design | UX | Mobile-first, breakpoints, touch, cross-browser |
| 8 | Infrastructure | Ops | Docker, cloud, scaling, DR, monitoring |
**Depth**: Quick(5-10min/intake+2dims) | Standard(30-60min/intake+8dims) | Deep(2-4hrs/full)
**Scoring 1-10**: 9-10:Leading | 7-8:Minor gaps | 5-6:Needs attention | 3-4:Systemic | 1-2:Rebuild
## Core Framework
**1. Functional**: Core flows vs reqs? Edge cases? Business rules? Roadmap alignment?
**2. Technical**: Modularity? N+1? API p95? Caching? Leaks? Auto: test --cover | grep TODO/FIXME
**3. Security**: MFA/RBAC/rate-limit? Encryption? Secrets vault? npm audit? Input validation? Auto: npm audit crit | grep secrets
**4. UX**: Friction points? Loading/empty/error states? Design system? Touch≥48px? WCAG 2.2 AA? Auto: axe {url}
**5. Ops**: CI/CD+rollback? Docker/k8s? Monitoring? Build time? Dev loop? Quick: CI status, deploy. Deep: DR test, load test.
**6. Business**: Pricing? Feature adoption? Competitor diffs? TCO? Roadmap? Quick: pricing, matrix. Deep: unit econ, churn, LTV/CAC.
## Workflow
INTAKE→classify | DEPTH→choose | MAP→deps | SCORE→per dim | CHECKS→auto | DOCUMENT→root/fix | PRIORITIZE→(10-Score)×Impact×Urgency | RECOMMEND→fix ≤6
## Priority = (10-Score)×Impact×Urgency | Impact: 1.0/0.7/0.4/0.1 | Urgency: 2.0/1.0/0.5
## Templates: SaaS(Ops40%/Sec35%/Biz25%) | ERP(Func50%/Sec35%) | Ecom(UX40%/Sec30%/Perf30%) | Web(UX40%/Tech30%/Sec25%) | API(Sec40%/Tech35%/Ops25%) | Desktop(UX40%/Func30%/Ops30%) | Mobile(UX45%/Perf35%/Res20%)
## Cross-Refs: project-mapper | security-scanner | code-review-agent | senior-engineer | performance-tracker
## Anti-Patterns: Skip intake | Ignore velocity | Skip responsive | Infra afterthought | Score without evidence | One-shot