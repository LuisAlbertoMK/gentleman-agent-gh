---
name: gap-analysis
description: Complete gap analysis for any system — 8-dim quality framework, project intake, priority scoring
triggers: "Gap analysis, system audit, identificar gaps, evaluar software, project intake"
license: Apache-2.0
metadata: version: "2.1", changelog: "2.1: compressed 67%"
---

# Gap Analysis

Complete intake + 8-dim quality audit for SaaS/ERP/web/mobile/API/desktop.

## Phase 0: Project Intake

### 0.1 Classify
**Tech Layer**: Frontend (react/vue/angular/.jsx) | Backend (go.mod/express/main.py) | Database (prisma/migrations/.sql) | Mobile (pubspec.yaml/Podfile) | Desktop (electron/tauri/WPF) | Infra (Dockerfile/terraform/k8s) | Full-stack (frontend+backend signals)
**Business Type**: SaaS (tenant/subscription/billing) | ERP (invoice/order/stock) | E-commerce (product/cart/checkout) | CMS (content/page/post) | API (endpoint/route/controller) | Web (landing/page/seo) | Desktop (window/menu) | Mobile (screen/navigator/gesture)

### 0.2 Intake Verification
`Test-Path ROADMAP.md` | `git log --oneline -10` | `Get-ChildItem *PRD*,*spec*,*requirements*` | `Test-Path README.md` | `Get-ChildItem tests,__tests__,spec -Directory` | `Get-ChildItem .github/workflows, Jenkinsfile, .gitlab-ci.yml` | `Get-ChildItem *monitor*,*grafana*,*datadog*`

### 0.3 Artifact Checklist
| Artifact | Why | Check |
|----------|-----|-------|
| Roadmap | Direction, priorities | ROADMAP.md, docs/roadmap/, project board |
| PR/Commits | Active dev, review quality | `gh pr list`, git log |
| PRD/Specs | What and why | PRD.md, spec/, requirements/ |
| README | Entry point, setup | Has setup/arch/stack/how-to-run? |
| Tests | Quality approach | test/, __tests__, coverage config |
| CI/CD | Automation | .github/, Jenkinsfile, .gitlab-ci.yml |
| Monitoring | Observability | Metrics, alerts, dashboards, APM |

### 0.4 8 Quality Dimensions
| # | Dim | Primary | What |
|---|-----|---------|------|
| 1 | UI/UX | UX | Visual design, interaction, flows, a11y |
| 2 | Security | Security | Auth, encryption, vulns, secrets, compliance |
| 3 | Optimization | Technical | Bundle size, code splitting, caching, lazy loading |
| 4 | Performance | Technical | Load time, render time, API latency, DB queries |
| 5 | Resource Usage | Ops | Memory, CPU, storage, network efficiency |
| 6 | Project Velocity | Business | Build time, dev loop, CI/CD speed |
| 7 | Responsive Design | UX | Mobile-first, breakpoints, touch, cross-browser |
| 8 | Infrastructure | Ops | Docker, cloud, scaling, DR, monitoring |

## Depth Levels
**Quick** (5-10min): Intake + 2 dims · **Standard** (30-60min): Intake + 8 dims · **Deep** (2-4hrs): Full intake + verified 8 dims

## Scoring (1-10)
9-10: Industry-leading | 7-8: Minor gaps | 5-6: Needs attention | 3-4: Systemic issues | 1-2: Needs rebuild

## Core Framework (6 Layers + 8 Dims)

### 1. Functional (UI/UX flows + biz logic)
- Core flows mapped vs requirements? Edge cases (empty/error/limit)? Business rules documented? Roadmap alignment?
- **Quick**: walk top 3 journeys. **Deep**: full feature matrix + competitor diff.
- **ISO 25010**: Functional Suitability

### 2. Technical (Optimization + Performance + Resource Usage)
- Modularity? Schema migrations? Bundle size (source-map-explorer)? N+1 queries? API p95? Caching? Memory leaks?
- **Auto**: `go test ./... -cover` | `npx jest --coverage` | `grep -rn "TODO|FIXME|HACK" --include="*.go,*.ts" . | wc -l`
- **ISO 25010**: Performance Efficiency, Maintainability, Reliability

### 3. Security (Security + Infra security)
- MFA/RBAC/rate limiting? Encryption at rest+transit? Secrets in vault? `npm audit` criticals? Input validation?
- **Auto**: `npm audit | grep "critical|high"` | `grep -rn "secret|password|api_key|token" --include="*.go,*.ts" .`
- **Reference**: OWASP ASVS 5.0 L1

### 4. UX (UI/UX + Responsive)
- Task friction points? Loading/empty/error states? Design system? Touch targets >=48px? WCAG 2.2 AA?
- **Quick**: tab through flow (focus visible? skip links?), check contrast, test without mouse.
- **Auto**: `npx lighthouse {url}` | `npx axe {url} | grep Violations`

### 5. Ops (Resource Usage + Infra + Velocity)
- CI/CD + rollback? Docker/k8s? Monitoring/logging/alerts? Build time? Dev loop speed?
- **Quick**: CI status, deploy script, error tracking. **Deep**: DR test, load test.
- **ISO 25010**: Reliability (maturity, availability, fault tolerance)

### 6. Business (Project Velocity)
- Pricing aligned? Feature adoption? Competitor diffs? TCO? Roadmap tracked?
- **Quick**: pricing page, competitor matrix. **Deep**: unit economics, churn, LTV/CAC.

## Workflow
1. INTAKE → classify + verify artifacts + select template
2. DEPTH → Quick/Standard/Deep
3. MAP → project-mapper (structure/deps/arch)
4. SCORE → per layer (1-10) + per dim (1-8) with evidence
5. CHECKS → auto-commands from each layer
6. DOCUMENT → symptom → root cause → impact → fix
7. PRIORITIZE → (10-Score) x Impact x Urgency
8. RECOMMEND → auto-fixes for dims <=6

## Auto-Recommendation
Score 1-3: CRITICAL — stop other work | 4-5: THIS SPRINT | 6-7: NEXT QUARTER | 8-10: Monitor
**Priority** = (10 - Score) x (Impact/10) x Urgency where Impact 1.0(critical)/0.7/0.4/0.1 and Urgency 2.0(now)/1.0(soon)/0.5(later)

## Templates
| Type | Weight Distribution |
|------|-------------------|
| SaaS | Ops 40%, Security 35%, Business 25% |
| ERP | Functional 50%, Security 35% |
| E-commerce | UX 40%, Security 30%, Performance 30% |
| Web | UX 40%, Technical 30%, Security 25% |
| API | Security 40%, Technical 35%, Ops 25% |
| Desktop | UX 40%, Functional 30%, Ops 30% |
| Mobile | UX 45%, Performance 35%, Resource 20% |

## Cross-References
- **project-mapper**: structure + stack detection | **security-scanner**: pre-audit | **code-review-agent**: code-level gaps | **senior-engineer**: trade-off analysis | **performance-tracker**: dedicated perf scoring

## Anti-Patterns
Skip intake · Ignore velocity · Skip responsive for "internal tools" · Infra as afterthought · Score without evidence · One-shot analysis
