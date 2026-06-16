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
  changelog: "2.1: compressed 67%"
---
## Phase 0: Project Intake
**Classify**: Tech Layer: Frontend|Backend|Database|Mobile|Desktop|Infra|Full-stack · Business: SaaS|ERP|E-commerce|CMS|API|Web|Desktop|Mobile
**Verify**: `Test-Path ROADMAP.md` | `git log --oneline -10` | `Get-ChildItem *PRD*,*spec*,*requirements*` | `Test-Path README.md` | `Get-ChildItem tests,__tests__,spec -Directory` | `Get-ChildItem .github/workflows, Jenkinsfile, .gitlab-ci.yml` | `Get-ChildItem *monitor*,*grafana*,*datadog*`
**Artifacts**: Roadmap→ROADMAP.md/docs/roadmap/board · PR/Commits→`gh pr list`, git log · PRD/Specs→PRD.md/spec/requirements/ · README→setup/arch/stack/how-to-run? · Tests→test/__tests__/coverage · CI/CD→.github/Jenkinsfile/.gitlab-ci.yml · Monitoring→Metrics/alerts/dashboards/APM
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
**2. Technical**: Modularity? Migrations? Bundle size? N+1? API p95? Caching? Leaks? Auto: `go test ./... -cover` | `npx jest --coverage` | `grep -rn "TODO|FIXME|HACK"`
**3. Security**: MFA/RBAC/rate-limit? Encryption? Secrets vault? npm audit criticals? Input validation? Auto: `npm audit | grep "critical|high"` | `grep -rn "secret|password|api_key|token"`
**4. UX**: Friction points? Loading/empty/error states? Design system? Touch >=48px? WCAG 2.2 AA? Auto: `npx lighthouse {url}` | `npx axe {url}` | `grep Violations`
**5. Ops**: CI/CD+rollback? Docker/k8s? Monitoring? Build time? Dev loop? Quick: CI status, deploy. Deep: DR test, load test.
**6. Business**: Pricing? Feature adoption? Competitor diffs? TCO? Roadmap? Quick: pricing, matrix. Deep: unit econ, churn, LTV/CAC.
## Workflow
INTAKE -> classify/verify/template | DEPTH -> choose level | MAP -> structure/deps | SCORE -> per layer+dim | CHECKS -> auto-commands | DOCUMENT -> symptom/root/impact/fix | PRIORITIZE -> (10-Score) x Impact x Urgency | RECOMMEND -> auto-fixes for <=6
## Priority = (10-Score) x (Impact/10) x Urgency | Impact: 1.0/0.7/0.4/0.1 | Urgency: 2.0(now)/1.0(soon)/0.5(later)
## Templates by Type: SaaS(Ops40%/Sec35%/Biz25%) | ERP(Func50%/Sec35%) | Ecom(UX40%/Sec30%/Perf30%) | Web(UX40%/Tech30%/Sec25%) | API(Sec40%/Tech35%/Ops25%) | Desktop(UX40%/Func30%/Ops30%) | Mobile(UX45%/Perf35%/Res20%)
## Cross-Refs: project-mapper | security-scanner | code-review-agent | senior-engineer | performance-tracker
## Anti-Patterns: Skip intake | Ignore velocity | Skip responsive | Infra afterthought | Score without evidence | One-shot