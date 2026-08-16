---
name: gap-analysis
description: "Complete gap analysis — 8-dim quality framework, project intake, priority scoring"
triggers: "Gap analysis, system audit, identificar gaps, project intake"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Complete gap analysis — 8-dim quality framework, project int

## Intake: Classify Tech (Frontend|Backend|DB|Mobile|Desktop|Infra|Full-stack) | Biz (SaaS|ERP|E-com|CMS|API|Web|Desktop|Mobile). Verify: ROADMAP.md | git log | PRD/requirements/spec | README | tests/__tests__/spec | CI/CD config | monitoring
## 8 Dims (1-10): 9-10=Leading | 7-8=Minor | 5-6=Needs attention | 3-4=Systemic | 1-2=Rebuild
1. **UI/UX** (Design, flows, a11y) | 2. **Security** (Auth, encryption, vulns, compliance) | 3. **Optimization** (Bundle, code-split, cache, lazy) | 4. **Performance** (Load, API latency, DB) | 5. **Resource** (Mem, CPU, storage, net) | 6. **Velocity** (Build, dev loop, CI/CD) | 7. **Responsive** (Mobile-first, breakpoints, touch) | 8. **Infra** (Docker, cloud, scaling, DR)
## Dimensions Detail
1. **Functional**: Core flows vs reqs | Edge cases | Business rules | Roadmap alignment
2. **Technical**: Modularity | N+1 | API p95 | Caching | Leaks | `test --cover` | grep TODO/FIXME
3. **Security**: MFA/RBAC/rate-limit | Encryption | Secrets vault | npm audit | Input validation
4. **UX**: Friction | Loading/empty/error states | Design system | Touch>=48px | WCAG 2.2 AA
5. **Ops**: CI/CD+rollback | Docker/k8s | Monitoring | Build time | Dev loop
6. **Business**: Pricing | Feature adoption | Competitor diffs | TCO | Roadmap
## Workflow: Intake->Classify->Depth->Map->Score->Auto checks->Root causes->Prioritize->Recommend
**Priority = (10-Score)×Impact×Urgency** | Impact: 1.0/0.7/0.4/0.1 | Urgency: 2.0/1.0/0.5
## Templates: ERP (Func50%/Sec35%) · Ecom (UX40%/Sec30%/Perf30%) · Web (UX40%/Tech30%/Sec25%) · API (Sec40%/Tech35%/Ops25%) · Desktop (UX40%/Func30%/Ops30%) · Mobile (UX45%/Perf35%/Res20%)
## Cross-Ref: project-mapper · security-scanner · code-review-agent · performance-tracker
## Anti-Patterns: Skip intake · Ignore velocity · Skip responsive · Infra afterthought · Score w/o evidence

## Example: Scoring a Web App
For a SaaS web app (UX 40% / Tech 30% / Security 25% / Ops 5%):
- UI/UX: 6 (Needs attention — no loading states)
- Security: 5 (No CSP headers, no rate limiting)
- Optimization: 7 (Code-split ok, no lazy images)
- Performance: 8 (Fast API, good caching)
- Priority = (10-5)×1.0×2.0 = **10.0** → Security fix first
- Next: (10-6)×0.7×1.0 = **2.8** → UI/UX loading states

Output: prioritized list with scores, evidence, and recommended fixes.

## Templates
See [assets/](assets/) for per-project-type intake templates: api, desktop, ecom, erp, mobile, saas, web.

## Refs
project-mapper · security-scanner · code-review-agent · performance-tracker

---

## C28 Depth — Extended Examples, Testing Patterns, Edge Cases, Anti-Patterns

### Examples (5)

**Example 1: E-commerce Platform (High UX + Security)**
```
Project: E-com checkout flow
Intake: Tech=Full-stack (React/Node/Postgres) | Biz=E-com
Dims scored:
  - UI/UX: 5 — No skeleton loaders, cart persists but no guest checkout
  - Security: 4 — No PCI DSS scope reduction, secrets in .env checked in
  - Optimization: 6 — Bundle 420KB, lazy routes ok
  - Performance: 5 — API p95=850ms on /checkout, N+1 on order items
  - Resource: 7 — Memory stable, DB connections pooled
  - Velocity: 4 — CI 18min, no preview deploys
  - Responsive: 8 — Mobile-first, touch targets 52px
  - Infra: 6 — Docker ok, no DR plan

Template weights: UX 40% / Security 30% / Perf 30%
Priority calc:
  Security: (10-4)×1.0×2.0 = 12.0  ← CRITICAL (secrets + PCI)
  UI/UX:    (10-5)×0.7×1.0 = 3.5
  Perf:     (10-5)×0.7×1.0 = 3.5
  Velocity: (10-4)×0.4×0.5 = 1.2
```

**Example 2: Internal ERP Module (Functional + Security Heavy)**
```
Project: Inventory management module
Intake: Tech=Backend (Go/Postgres) | Biz=ERP
Dims scored:
  - Functional: 3 — Core flow works but edge cases missing (negative stock, partial shipments)
  - Technical: 6 — Modularity ok, some N+1 on warehouse queries
  - Security: 5 — RBAC exists but no MFA, audit logs incomplete
  - UX: N/A (internal tool)
  - Ops: 4 — Manual deploy, no rollback, build 12min

Template weights: Func 50% / Sec 35% / Ops 15%
Priority:
  Functional: (10-3)×1.0×2.0 = 14.0  ← REBUILD tier
  Security:   (10-5)×0.7×2.0 = 7.0
  Ops:        (10-4)×0.4×1.0 = 2.4
```

**Example 3: Public API Service (Security + Ops Focus)**
```
Project: REST API for partners
Intake: Tech=API (FastAPI/Redis) | Biz=API
Dims scored:
  - Security: 3 — No rate limiting, JWT no refresh, CORS wildcard
  - Technical: 7 — Clean architecture, p95=120ms, good caching
  - Optimization: 8 — Response compression, conditional requests
  - Performance: 8 — Load tested 5k RPS
  - Resource: 6 — Redis memory growth under load
  - Velocity: 5 — CI 8min, flaky integration tests
  - Infra: 4 — Single AZ, no auto-scaling rules

Template weights: Sec 40% / Tech 35% / Ops 25%
Priority:
  Security: (10-3)×1.0×2.0 = 14.0  ← CRITICAL
  Infra:    (10-4)×0.4×1.0 = 2.4
  Velocity: (10-5)×0.1×0.5 = 0.25
```

**Example 4: Mobile App (UX + Performance Heavy)**
```
Project: Consumer fitness app
Intake: Tech=Mobile (React Native) | Biz=Mobile
Dims scored:
  - UI/UX: 4 — Onboarding drop-off 40%, no offline queue
  - Performance: 5 — Cold start 3.2s, JS bridge jank on charts
  - Responsive: N/A (native)
  - Security: 6 — Biometric ok, but analytics PII leak
  - Optimization: 5 — Bundle 45MB, Hermes not enabled
  - Resource: 4 — Memory spikes on camera, battery drain
  - Velocity: 6 — Fastlane ok, E2E flaky
  - Infra: 7 — CodePush, staged rollouts

Template weights: UX 45% / Perf 35% / Res 20%
Priority:
  UI/UX:     (10-4)×1.0×2.0 = 12.0
  Performance: (10-5)×0.7×1.0 = 3.5
  Resource:   (10-4)×0.4×1.0 = 2.4
  Security:   (10-6)×0.1×0.5 = 0.2
```

**Example 5: Legacy Desktop App Modernization**
```
Project: WPF .NET Framework 4.8 → .NET 8
Intake: Tech=Desktop (WPF) | Biz=Desktop
Dims scored:
  - Functional: 7 — Feature parity ok, some COM interop gaps
  - Technical: 3 — Tight coupling, no DI, 2.3k TODO/FIXME
  - Security: 4 — ClickOnce, no cert pinning, config in registry
  - UX: 5 — DPI issues, no touch, dated chrome
  - Ops: 2 — Manual MSI build, no telemetry, no crash reporting
  - Velocity: 3 — Build 22min, no unit tests
  - Infra: 3 — On-prem only, no containerization

Template weights: UX 40% / Func 30% / Ops 30%
Priority:
  Technical: (10-3)×1.0×2.0 = 14.0  ← REBUILD
  Ops:       (10-2)×0.7×1.0 = 5.6
  Security:  (10-4)×0.4×1.0 = 2.4
  Velocity:  (10-3)×0.1×0.5 = 0.35
```

---

### Testing Patterns (3)

**Pattern 1: Intake Completeness Verification**
```bash
# Verify all intake sources exist and are current
test -f ROADMAP.md && echo "ROADMAP: $(head -5 ROADMAP.md)"
test -f PRD.md -o -f requirements.md -o -f SPEC.md && echo "Requirements: present"
git log --oneline -10 --since="30 days ago" | wc -l  # Recent activity?
ls tests/__tests__/spec 2>/dev/null | wc -l          # Test coverage?
grep -r "monitoring\|observability\|datadog\|prometheus" . --include="*.md" --include="*.yml" | head -3
# PASS: All 5 sources present and updated within 30 days
```

**Pattern 2: Dimension Evidence Audit**
```bash
# For each dimension, require ≥2 pieces of evidence
# Security example:
grep -r "rate.limit\|throttle\|helmet\|csp" . --include="*.ts" --include="*.js" | wc -l  # ≥2
grep -r "secret\|vault\|keyvault\|sealed" . --include="*.yml" --include="*.yaml" | wc -l  # ≥2
npm audit --json | jq '.metadata.vulnerabilities.high + .metadata.vulnerabilities.critical'  # =0
# FAIL if any dimension has <2 evidence sources
```

**Pattern 3: Priority Formula Regression Test**
```bash
# Known inputs → expected priority outputs
# Score=5, Impact=1.0, Urgency=2.0 → 10.0
# Score=8, Impact=0.7, Urgency=1.0 → 1.4
# Score=3, Impact=0.4, Urgency=2.0 → 5.6
python3 -c "
cases = [(5,1.0,2.0,10.0),(8,0.7,1.0,1.4),(3,0.4,2.0,5.6)]
for s,i,u,exp in cases:
    got = round((10-s)*i*u, 2)
    assert got == exp, f'{s},{i},{u} → {got} != {exp}'
print('All priority calculations correct')
"
```

---

### Edge Cases (4)

**Edge Case 1: New Project (No Historical Data)**
- No git history, no ROADMAP, no tests yet
- **Handling**: Score all dims at 5 (baseline "Needs attention"), weight by template only, flag as "greenfield — establish baseline first"
- **Priority**: All dims equal priority → use template weights to break ties

**Edge Case 2: Dimension Not Applicable (N/A)**
- e.g., Responsive for backend API, UX for headless service
- **Handling**: Exclude from scoring, redistribute its template weight proportionally across remaining dims
- **Formula**: `adjusted_weight = original_weight / (1 - na_weight)`

**Edge Case 3: Conflicting Evidence Within Dimension**
- Security: Has MFA (good) but secrets in repo (critical)
- **Handling**: Score = MIN(evidence_scores) — a single critical gap caps the dimension
- **Rationale**: Security/ops are only as strong as weakest link

**Edge Case 4: Template Mismatch (Hybrid Project)**
- Project spans multiple biz types (e.g., SaaS + API + E-com)
- **Handling**: Run gap analysis per bounded context, then aggregate with context-weighting
- **Weighting**: `final_priority = Σ(context_priority × context_revenue_share)`

---

### Anti-Patterns (2 Additional)

**Anti-Pattern 6: Scoring Without Evidence Traceability**
- Assigning scores based on "feel" or assumptions without linking to grep/test/doc evidence
- **Fix**: Every score must cite `file:line` or command output. Use Evidence Gate: "Show me the evidence for Security=5"

**Anti-Pattern 7: Priority Inflation via Urgency Override**
- Artificially setting Urgency=2.0 (Critical) for everything to force attention
- **Fix**: Urgency=2.0 only for: production outage, active exploit, regulatory deadline, data loss risk. Default=1.0.