---
name: gap-analysis
description: >
  Complete project intake + gap analysis for any system (SaaS, ERP, web, mobile, API, desktop).
  8-dimension quality framework, project classification, intake checklist (roadmap/PR/PRD),
  and depth levels. Trigger: "gap analysis", "auditar sistema", "identificar gaps",
  "system audit", "software assessment", "project intake".
license: Apache-2.0
metadata: version: "2.0", changelog: "1.1→2.0: project intake + verification commands, 8-dim coverage, 3 new templates (ecom/api/mobile), auto-recommendation engine, priority scoring formula"
---

## Phase 0: Project Intake (NEW — mandatory before scoring)

### 0.1 Classify Project Type
Detect BOTH tech layer AND business type:

**Tech Layer** (how it runs):
| Layer | Detected by | Examples |
|-------|-------------|---------|
| **Frontend** | package.json (react/vue/angular), index.html, .jsx/.tsx | React SPA, Next.js SSG, Vue SPA |
| **Backend** | go.mod, package.json (express/fastify), main.py, *.csproj | REST API, GraphQL, Monolith |
| **Database** | prisma/schema, migrations/, *.sql, docker-compose (db service) | PostgreSQL, MongoDB, Redis |
| **Mobile** | pubspec.yaml, Podfile, build.gradle (android) | Flutter, React Native, SwiftUI |
| **Desktop** | package.json (electron/tauri), *.csproj (WPF), Cargo.toml (tauri) | Electron, Tauri, WPF |
| **Infra** | Dockerfile, terraform/, k8s/, ansible/ | Docker Compose, K8s, IaC |
| **Full-stack** | Frontend + Backend signals together | Next.js, Nuxt, Remix |

**Business Type** (what it does):
| Type | Signals | Keywords in code/docs |
|------|---------|----------------------|
| **SaaS** | Multi-tenant, subscription, API-first | tenant, subscription, plan, billing |
| **ERP** | Inventory, invoices, CRM, logistics | invoice, order, stock, customer, vendor |
| **E-commerce** | Products, cart, checkout, payments | product, cart, checkout, payment, shipping |
| **CMS** | Content, pages, posts, users | content, page, blog, post, article |
| **API** | REST/GraphQL endpoints, no UI | api, endpoint, route, controller |
| **Web** | Public site, marketing, landing | page, landing, blog, seo |
| **Desktop App** | Native UI, offline-first | window, menu, dialog, tray |
| **Mobile App** | Touch UI, push notifications | screen, navigator, gesture |

### 0.2 Intake Verification Commands
Run these BEFORE scoring. Each artifact gets ✅/❌/⚠️ (exists / missing / partial).

```bash
# 📋 Roadmap — check multiple locations
if (Test-Path "ROADMAP.md") { "✅ Roadmap: ROADMAP.md" } `
elseif (Test-Path "docs/roadmap.md") { "✅ Roadmap: docs/roadmap.md" } `
elseif (Test-Path "roadmap/") { "✅ Roadmap: roadmap/ dir exists" } `
else { "❌ Roadmap: not found. Check project board or create ROADMAP.md" }

# 📝 PR — check recent activity
$prs = git log --oneline -10 2>$null; if ($prs) { "✅ PRs: Active ($(git log --oneline -5 | Measure-Object | %{$_.Count}) commits in HEAD)" } `
else { "❌ PRs: No git history found" }

# 📄 PRD — check requirements docs
$found = Get-ChildItem -Recurse -Include "*PRD*","*spec*","*requirements*","*srs*" -Exclude "*node_modules*","*.git*" | Select-Object -First 3
if ($found) { "✅ PRD: Found ($($found.Count) files: $($found[0].Name)...)" } `
else { "❌ PRD: Not found. Check docs/ or specs/ directory" }

# 🏗️ README
if (Test-Path "README.md") { "✅ README: exists ($((Get-Item README.md).Length / 1KB -as [int])KB)" } `
else { "❌ README: missing" }

# 🧪 Test strategy — check multiple patterns
$testDir = Get-ChildItem -Directory -Include "tests","__tests__","spec","test" -ErrorAction SilentlyContinue | Select-Object -First 1
$testScripts = Get-ChildItem -Recurse -Include "*test*","*spec*","*suite*" -File -Exclude "*node_modules*",".git" -ErrorAction SilentlyContinue | Select-Object -First 5
if ($testDir) { "✅ Tests: $($testDir.Name) dir exists" } `
elseif ($testScripts) { "✅ Tests: Found $($testScripts.Count) test files (e.g., $($testScripts[0].Name))" } `
else { "⚠️ Tests: No test files found" }

# 🔧 CI/CD — check multiple CI providers
$ciFiles = @()
$ciFiles += Get-ChildItem -Path ".github/workflows" -Filter "*.yml" -ErrorAction SilentlyContinue
if (-not $ciFiles) { $ciFiles += Get-ChildItem -Name -Filter "Jenkinsfile" -ErrorAction SilentlyContinue }
if (-not $ciFiles) { $ciFiles += Get-ChildItem -Name -Filter ".gitlab-ci.yml" -ErrorAction SilentlyContinue }
if (-not $ciFiles) { $ciFiles += Get-ChildItem -Name -Filter "azure-pipelines.yml" -ErrorAction SilentlyContinue }
if (-not $ciFiles) { $ciFiles += Get-ChildItem -Name -Filter ".circleci/config.yml" -ErrorAction SilentlyContinue }
if (-not $ciFiles) { $ciFiles += Get-ChildItem -Recurse -Name -Filter "Dockerfile" -ErrorAction SilentlyContinue | Select-Object -First 1 }
if ($ciFiles) { "✅ CI/CD: Found $($ciFiles.Count) config(s) (e.g., $($ciFiles[0]))" } `
else { "⚠️ CI/CD: No config found" }

# 📊 Monitoring — check known APM/config files
$monPatterns = @("*sentry*","*datadog*","*newrelic*","*grafana*","*prometheus*","*openTelemetry*","*appinsights*","*bugsnag*")
$mon = $monPatterns | ForEach-Object { Get-ChildItem -Recurse -Include $_ -File -Exclude "*node_modules*",".git" -ErrorAction SilentlyContinue } | Select-Object -First 1
if ($mon) { "✅ Monitoring: $($mon.Name)" } `
else { "⚠️ Monitoring: No APM/tracing config found" }
```

### 0.4 Intake Checklist
BEFORE any layer scoring, verify project artifacts exist:

| Artifact | Why it matters | How to check |
|----------|---------------|--------------|
| **📋 Roadmap** | Defines direction, priorities, milestones | Look for: ROADMAP.md, roadmap.*, docs/roadmap*, project board |
| **📝 PR (Pull Request)** | Shows active development, code review quality | Check recent PRs: `gh pr list`, git log, open PRs |
| **📄 PRD (Product Requirements Doc)** | Documents what and why, not just how | Look for: PRD.md, spec/, requirements/, *.spec.* |
| **🏗️ README** | Project entry point, setup, architecture | README.md exists? Has: setup, arch, tech stack, how to run? |
| **🧪 Test Strategy** | Quality approach documented | Look for: test/, __tests__, testing strategy in docs |
| **🔧 CI/CD Config** | Automation pipeline | Check: .github/, Jenkinsfile, .gitlab-ci.yml, docker-compose.yml |
| **📊 Monitoring** | Observability in place | Look for: metrics, alerts, dashboards, APM config |

Missing artifacts = gaps to document in output. Save missing artifacts to engram for next session.

### 0.5 8 Quality Dimensions (cross-cutting)
The user's 8 dimensions map across the 6 layers:

| # | Dimension | Primary Layer | Secondary | What it evaluates |
|---|-----------|--------------|-----------|-------------------|
| 1 | 🎨 **UI/UX** | UX | Functional | Visual design, interaction, user flows, accessibility |
| 2 | 🔒 **Security** | Security | Technical | Auth, encryption, vulns, secrets, compliance |
| 3 | ⚡ **Optimization** | Technical | Ops | Bundle size, code splitting, caching, lazy loading |
| 4 | 📈 **Performance** | Technical | Ops | Load time, render time, API latency, DB queries |
| 5 | 💾 **Resource Usage** | Ops | Technical | Memory, CPU, storage, network efficiency |
| 6 | 🚀 **Project Velocity** | Business | Ops | Build time, dev loop, CI/CD speed, code generation |
| 7 | 📱 **Responsive Design** | UX | Technical | Mobile-first, breakpoints, touch, print, cross-browser |
| 8 | 🏗️ **Infrastructure** | Ops | Security | Docker, cloud, scaling, DR, monitoring, logging |

---

## Depth Levels
| Level | When | Time |
|-------|------|------|
| **Quick** (1) | Daily standup, code review pre-check | 5-10 min → Intake only + 2 dims |
| **Standard** (2) | New feature, sprint planning | 30-60 min → Intake + all 8 dims |
| **Deep** (3) | Pre-launch, DD, platform migration | 2-4 hrs → Full intake + all 8 dims verified |

## Quantitative Scoring (1-10)
| Score | Meaning |
|-------|---------|
| 9-10 | Mature — industry-leading |
| 7-8 | Solid — minor gaps, no blockers |
| 5-6 | Functional — gaps exist, need attention |
| 3-4 | Weak — systemic issues |
| 1-2 | Critical — needs rebuild |

## Core Framework (6 Layers) + 8-Dim Coverage

### 1. 🎯 Functional
**Covers dims**: UI/UX (flows), Project Velocity (logic complexity)
- [ ] Core flows mapped vs requirements/competitors?
- [ ] Edge cases: empty, error, limit states documented?
- [ ] Business rules: in code only vs documented?
- [ ] Roadmap alignment: current features match roadmap?
- **Quick**: walk top 3 user journeys. **Deep**: full feature matrix + competitor diff.
- **ISO 25010**: Functional Suitability (completeness, correctness, appropriateness)

### 2. 🏗️ Technical
**Covers dims**: Optimization, Performance, Resource Usage
- [ ] Modularity? Deploy independence? Tech debt visible?
- [ ] Data: schema normalized? migrations safe? backup/restore tested?
- [ ] ⚡ **Optimization**: bundle size? code splitting? tree shaking? lazy loading?
- [ ] 📈 **Performance**: N+1 queries? API latency p95? caching strategy? connection pooling?
- [ ] 💾 **Resource Usage**: memory leaks? CPU hotspots? storage bloat? network calls minimized?
- [ ] Testing: unit+integration+e2e coverage on critical paths?
- **Auto checks**:
  ```bash
  # Coverage
  go test ./... -coverprofile=cover.out && go tool cover -func=cover.out | tail -1
  npx jest --coverage --silent 2>/dev/null | grep "Statements" | tail -1
  # Anti-patterns
  grep -rn "TODO\|FIXME\|HACK\|XXX\|BUG" --include="*.go" --include="*.ts" process . | wc -l
  grep -rn "console.log\|fmt.Print" --include="*.go" --include="*.ts" . | grep -v "_test" | wc -l
  # Bundle size (web)
  npx source-map-explorer build/static/js/*.js 2>/dev/null | head -5
  ```
- **ISO 25010**: Performance Efficiency, Maintainability, Reliability

### 3. 🔒 Security
**Covers dims**: Security, Infrastructure (network security)
- [ ] Auth: MFA? RBAC? rate limiting? session management? OAuth2? SSO?
- [ ] Data: encryption at rest (AES-256) + transit (TLS 1.3)? PII handling?
- [ ] Secrets: hardcoded? vault? rotated? .env in git?
- [ ] Dependencies: known vulns? (`npm audit`, `go mod verify`, `pip audit`)
- [ ] Input validation: ALL user inputs? SQL injection? XSS? CSRF?
- [ ] API security: rate limiting? JWT rotation? CORS configured?
- [ ] 🏗️ **Infrastructure security**: network segmentation? firewall? WAF? DDoS protection?
- **Reference**: OWASP ASVS 5.0 L1 minimum. L2 for fintech/health.
- **Auto checks**:
  ```bash
  security-scanner  # built-in skill
  npm audit 2>/dev/null | grep "critical\|high" | head -5
  go list -json -u all 2>/dev/null | grep "Vulnerability" | head -5
  grep -rn "secret\|password\|api_key\|token\|credential" --include="*.go" --include="*.ts" . --exclude-dir={node_modules,.git,vendor} | head -10
  ```

### 4. 🧭 UX
**Covers dims**: UI/UX, Responsive Design
- [ ] 🎨 **UI/UX**: primary task friction points? steps to complete? feedback on actions?
- [ ] Loading/empty/error states for EVERY state?
- [ ] 🎨 **UI/UX**: visual design consistent? design system? component library?
- [ ] 📱 **Responsive Design**: mobile-first? breakpoints defined? touch targets ≥48px?
- [ ] 📱 **Responsive Design**: tested on real devices? print styles? cross-browser?
- [ ] Accessibility: WCAG 2.2 AA? Keyboard nav? Focus visible? Screen reader?
- **Reference**: WCAG 2.2 AA (86 criteria, 4 principles: POUR)
- **Quick**: tab through entire flow (focus visible? skip links?), check contrast, test without mouse.
- **Auto checks**:
  ```bash
  # If web app
  npx lighthouse {url} --view 2>/dev/null | grep -E "accessibility|Accessibility|performance|Performance" | head -5
  npx axe {url} 2>/dev/null | grep "Violations" | head -3
  ```

### 5. 🚀 Ops
**Covers dims**: Resource Usage, Infrastructure, Project Velocity
- [ ] Deploy: CI/CD? rollback? blue/green? feature flags? zero-downtime?
- [ ] 🏗️ **Infrastructure**: Docker? orchestration? cloud provider? auto-scaling?
- [ ] 🏗️ **Infrastructure**: monitoring? logging? metrics? alerts? dashboards? SLAs/SLOs?
- [ ] 💾 **Resource Usage**: cost monitoring? reserved instances? right-sizing?
- [ ] 🚀 **Project Velocity**: build time? CI pipeline speed? dev loop? hot reload?
- [ ] Documentation: API docs? runbooks? architecture diagrams current?
- **Quick**: check CI status, deploy script, error tracking. **Deep**: DR test, load test, restore test.
- **ISO 25010**: Reliability (maturity, availability, fault tolerance, recoverability)

### 6. 💰 Business
**Covers dims**: Project Velocity
- [ ] Pricing aligned with value? Feature adoption data?
- [ ] Competitor comparison: what they have that you don't?
- [ ] 🚀 **Project Velocity**: Time-to-market? Release cadence? Feature throughput?
- [ ] TCO: dev hours? infra? maintenance burden?
- [ ] Roadmap: defined and tracked? Stakeholder buy-in?
- **Quick**: pricing page, competitor matrix. **Deep**: unit economics, churn, LTV/CAC.

---

## Workflow (8 steps)

```
0. INTAKE
   ├─ Classify: tech layer + business type (project-mapper)
   ├─ Verify artifacts: roadmap? PR? PRD? README? Tests? CI/CD? Monitoring?
   └─ Select template matching type
   
1. DEPTH → Quick (5-10min) / Standard (30-60min) / Deep (2-4hrs)
2. MAP → project-mapper (structure, stack, deps, arch)
3. SCORE → per layer (1-10) + per dim (1-8) with evidence
4. CHECKS → run auto-commands from each layer section
5. DOCUMENT → per gap: symptom → root cause → impact → fix
6. PRIORITIZE → Formula: (10 - Score) × Impact × Urgency
7. RECOMMEND → Auto-generate fixes per dim scored ≤6
8. TRACK → engram for recurring gaps + anti-pattern catalog
```

## Auto-Recommendation Engine
After scoring, auto-generate recommendations based on scores and project type:

| Score | Label | Auto-recommendation |
|-------|-------|---------------------|
| 1-3 | Critical | 🔴 IMMEDIATE: Blocking issue. Stop other work. |
| 4-5 | Weak | 🟠 This sprint: Plan fix in current/next sprint. |
| 6-7 | Fair | 🟡 Next quarter: Schedule improvement. |
| 8-10 | Mature | ✅ Monitor: Maintain, check in next review. |

**Priority Score Formula**: `Priority = (10 - Score) × (Impact Weight / 10) × Urgency Multiplier`

Where:
- **Impact Weight**: 1.0 (Critical path) · 0.7 (Important) · 0.4 (Nice to have) · 0.1 (Minor)
- **Urgency Multiplier**: 2.0 (Now) · 1.0 (Soon) · 0.5 (Later)

**Auto-output** (for each dim scored ≤6):
```
## Recommendation: {dim}
**Current Score**: X/10 | **Target**: 7/10
**Priority**: {CRITICAL|HIGH|MEDIUM|LOW} (score: {formula result})
**Why**: {evidence from checks}
**Fix**: {concrete next step}
**Effort Estimate**: {hours/days}
**Depends On**: {other gaps to fix first}
```

## Per-Type Priority Matrix
Weights vary by business type (see templates for full weights).
Default weights when type unknown:
| Layer | Weight | Maps to dims |
|-------|--------|--------------|
| Functional | 20% | UI/UX (flows) |
| Technical | 25% | Optimization, Performance |
| Security | 20% | Security, Infrastructure |
| UX | 15% | UI/UX, Responsive Design |
| Ops | 10% | Resource Usage, Infrastructure |
| Business | 10% | Project Velocity |

## Prioritization Matrix
| Impact ↓ \ Urgency → | Now | Soon | Later |
|----------------------|-----|------|-------|
| **Critical** | 🔴 DO NOW | 🟠 Plan sprint | 🟡 Backlog |
| **High** | 🟠 Sprint | 🟡 Next sprint | ⚪ Icebox |
| **Medium** | 🟡 This month | ⚪ Next quarter | ⚪ Watch |
| **Low** | ⚪ When possible | ⚪ If overlaps | ⚪ Ignore |

## Output Format
```
## Project Intake Report
- **Project**: {name}
- **Tech Layer**: {frontend|backend|db|mobile|desktop|full-stack|infra}
- **Business Type**: {saas|erp|ecom|cms|api|web|desktop|mobile}
- **Template**: {saas|erp|ecom|web|api|mobile|desktop}-template.md
- **Depth Level**: {Quick|Standard|Deep}
- **Artifacts Found**:
  ├─ 📋 Roadmap: ✅/❌/⚠️ {path if found}
  ├─ 📝 PR/Commits: ✅ ({N} recent commits)
  ├─ 📄 PRD/Specs: ✅/❌ ({N} files)
  ├─ 🏗️ README: ✅ ({size})
  ├─ 🧪 Tests: ✅/⚠️/❌ ({details})
  ├─ 🔧 CI/CD: ✅/⚠️/❌ ({provider})
  └─ 📊 Monitoring: ✅/⚠️/❌ ({tool})

## 8-Dimension Summary
| Dim | Score | Key Gap |
|-----|-------|---------|
| 🎨 UI/UX | X/10 | {one-liner} |
| 🔒 Security | X/10 | {one-liner} |
| ⚡ Optimization | X/10 | {one-liner} |
| 📈 Performance | X/10 | {one-liner} |
| 💾 Resource Usage | X/10 | {one-liner} |
| 🚀 Project Velocity | X/10 | {one-liner} |
| 📱 Responsive Design | X/10 | {one-liner} |
| 🏗️ Infrastructure | X/10 | {one-liner} |

## Gap Details
**Gap**: {one-liner}
**Layer**: {1-6} | **Dim**: {1-8} | **Score**: {X/10}
**Symptom**: {evidence}
**Root cause**: {why exists}
**Fix**: {how to solve} | **Effort**: {S/M/L/XL}
**Priority**: {color}

## Auto-Recommendations
| Dim | Score | Priority | Fix |
|-----|-------|----------|-----|
| {dim} | {X/10} | {CRITICAL/HIGH/MEDIUM/LOW} | {one-liner fix} |

## Next Steps
1. {immediate action} — Priority: {P1/P2/P3}
2. {short-term action} — Priority: {P1/P2/P3}
3. {medium-term action} — Priority: {P1/P2/P3}
```

## Templates
Per-type weighted checklists → `assets/{type}-template.md`

| Type | Template | Priority Weight |
|------|----------|----------------|
| SaaS | saas-template | Ops 40%, Security 35%, Business 25% |
| ERP | erp-template | Functional 50%, Security 35% |
| E-commerce | ecom-template | UX 40%, Security 30%, Performance 30% |
| Web | web-template | UX 40%, Technical 30%, Security 25% |
| API | api-template | Security 40%, Technical 35%, Ops 25% |
| Desktop | desktop-template | UX 40%, Functional 30%, Ops 30% |
| Mobile | mobile-template | UX 45%, Performance 35%, Resource 20% |

## Cross-References
- **project-mapper**: structure + stack + type detection
- **security-scanner**: pre-audit security
- **code-review-agent**: code-level gap detection
- **senior-engineer**: trade-off analysis, fix prioritization

## Anti-Patterns
❌ Skip intake phase — classification prevents wrong template
❌ Ignore project velocity — slow dev loop kills productivity regardless of code quality
❌ Skip responsive design for "internal tools" — mobile-first is default in 2026
❌ Infrastructure as afterthought — non-functional reqs need proactive design
❌ Score without evidence — Default-FAIL applies
❌ One-shot analysis — gaps need tracking; use engram
