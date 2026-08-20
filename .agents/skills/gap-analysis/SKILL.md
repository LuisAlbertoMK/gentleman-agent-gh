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
## Workflow: Intake->Classify->Depth->Map->Score->Auto checks->Root causes->Prioritize->Recommend
**Priority = (10-Score)×Impact×Urgency** | Impact: 1.0/0.7/0.4/0.1 | Urgency: 2.0/1.0/0.5
## Templates: ERP (Func50%/Sec35%) · Ecom (UX40%/Sec30%/Perf30%) · Web (UX40%/Tech30%/Sec25%) · API (Sec40%/Tech35%/Ops25%) · Desktop (UX40%/Func30%/Ops30%) · Mobile (UX45%/Perf35%/Res20%)
## Cross-Ref: project-mapper · security-scanner · code-review-agent · performance-tracker
---

docs/skills/gap-analysis/reference.md
---