---
name: gap-analysis
description: >
  Systematic gap analysis for any software system (SaaS, ERP, web, desktop).
  6-layer framework with quantitative scoring, depth levels, and industry standards
  (ISO 25010, OWASP ASVS 5.0, WCAG 2.2). Trigger: "gap analysis", "auditar sistema",
  "identificar gaps", "system audit", "software assessment".
license: Apache-2.0
metadata: version: "1.1"
---

## When
Before building a new feature · evaluating a codebase · onboarding a project ·
comparing vs competitors · pre-acquisition · post-mortem · pre-PR for critical paths.

## Depth Levels
| Level | When | Time |
|-------|------|------|
| **Quick** (1) | Daily standup, code review pre-check, small PR | 5-10 min |
| **Standard** (2) | New feature, module eval, sprint planning | 30-60 min |
| **Deep** (3) | Pre-launch, acquisition DD, platform migration | 2-4 hrs |

## Quantitative Scoring (per layer)
Evaluate each layer 1-10. Weighted by system type → final score.

| Score | Meaning |
|-------|---------|
| 9-10 | Mature — industry-leading |
| 7-8 | Solid — minor gaps, no blockers |
| 5-6 | Functional — gaps exist, need attention |
| 3-4 | Weak — systemic issues |
| 1-2 | Critical — needs rebuild |

## Core Framework (6 Layers)

Assess EVERY system across all 6. Weight varies by type (see `assets/` templates).

### 1. 🎯 Functional
- Core flows mapped vs requirements/competitors?
- Edge cases documented? (empty, error, limits)
- Business rules: in code only vs documented?
- **Quick**: walk top 3 user journeys. **Deep**: full feature matrix + competitor diff.
- **ISO 25010**: Functional Suitability (completeness, correctness, appropriateness)

### 2. 🏗️ Technical
- Modularity? Deploy independence? Tech debt visible?
- Data: schema normalised? migrations safe? backup/restore?
- Performance: N+1? lazy loading? caching? bundle?
- Testing: unit+integration+e2e coverage on critical paths?
- **Auto checks**:
  ```bash
  # Test coverage
  go test ./... -coverprofile=cover.out && go tool cover -func=cover.out | tail -1
  npx jest --coverage --silent 2>/dev/null | grep "Statements" | tail -1
  
  # Known anti-patterns
  grep -rn "TODO\|FIXME\|HACK\|XXX\|BUG" --include="*.go" --include="*.ts" --include="*.py" . | wc -l
  grep -rn "console.log\|fmt.Print\|print(" --include="*.go" --include="*.ts" . | grep -v "_test\|spec\|\.log" | wc -l
  
  # Bundle size (if web)
  npx source-map-explorer build/static/js/*.js 2>/dev/null | head -5
  ```
- **ISO 25010**: Performance Efficiency, Maintainability, Reliability

### 3. 🔒 Security
- Auth: MFA? RBAC? rate limiting? session management?
- Data: encryption (rest+transit)? PII handling?
- Secrets: hardcoded? vault? rotated?
- Dependencies: known vulns? (`npm audit`, `go mod verify`, `pip audit`)
- **Reference standard**: OWASP ASVS 5.0 (350 reqs, 3 levels). At minimum pass L1.
- **Auto checks**:
  ```bash
  security-scanner  # built-in skill
  npm audit 2>/dev/null | grep "critical\|high" | head -5
  go list -json -u all 2>/dev/null | grep "Vulnerability" | head -5
  grep -rn "secret\|password\|api_key\|token\|credential" --include="*.go" --include="*.ts" --include="*.py" --include="*.env*" . | grep -v "_test\|\.git\|node_modules\|vendor" | head -10
  ```

### 4. 🧭 UX
- Primary task: friction points? steps to complete?
- Feedback: loading? errors? empty states? optimistic UI?
- Accessibility: WCAG 2.2 AA? Keyboard nav? Screen reader?
- **Reference standard**: WCAG 2.2 AA (86 criteria, 4 principles: Perceivable, Operable, Understandable, Robust)
- **Quick**: tab through entire flow (focus visible? skip links?), check contrast, test without mouse.
- **Auto checks**:
  ```bash
  # If web app
  npx lighthouse {url} --view 2>/dev/null | grep -E "accessibility|Accessibility" | head -3
  npx axe {url} 2>/dev/null | grep "Violations" | head -3
  ```

### 5. 🚀 Ops
- Deploy: CI/CD? rollback? blue/green? feature flags?
- Monitoring: logs? metrics? alerts? dashboards? SLAs?
- Documentation: API docs? runbooks? arch diagrams current?
- **Quick**: check CI status, deploy script, error tracking. **Deep**: DR test, load test, backup restore test.
- **ISO 25010**: Reliability (maturity, availability, fault tolerance, recoverability)

### 6. 💰 Business
- Pricing aligned with value? Feature adoption data?
- Competitor comparison: what they have that you don't?
- TCO: dev hours? infra? maintenance burden?
- **Quick**: pricing page, competitor feature matrix. **Deep**: unit economics, churn analysis, LTV/CAC.

## Workflow

```
1. DEPTH SELECT → Quick / Standard / Deep
2. MAP → project-mapper (structure, stack, deps)
3. SCORE → per layer (1-10) with evidence
4. DOCUMENT → per gap: symptom → root cause → impact → fix
5. PRIORITIZE → impact × urgency matrix
6. TRACK → engram for recurring gaps + anti-pattern catalog
```

## Prioritization Matrix

| Impact ↓ \ Urgency → | Now | Soon | Later |
|----------------------|-----|------|-------|
| **Critical** | 🔴 DO NOW | 🟠 Plan sprint | 🟡 Backlog |
| **High** | 🟠 Sprint | 🟡 Next sprint | ⚪ Icebox |
| **Medium** | 🟡 This month | ⚪ Next quarter | ⚪ Watch |
| **Low** | ⚪ When possible | ⚪ If overlaps | ⚪ Ignore |

## Gap Document Format

```markdown
**Gap**: {one-liner}
**Layer**: {1-6} | **Score**: {X/10} | **Depth**: {Quick|Standard|Deep}
**Symptom**: {what you see}
**Root cause**: {why it exists}
**Impact**: {users? revenue? risk?}
**Fix**: {how to solve} | **Effort**: {S/M/L/XL}
**Priority**: {color from matrix}
```

## Output (end of analysis)
```
## Summary
- **Overall Score**: {weighted avg}/10
- **Layer Scores**: F:{X} T:{X} S:{X} U:{X} O:{X} B:{X}
- **Critical Gaps**: {N}
- **High Gaps**: {N}
- **Quick Wins**: {N}
```

## Industry Standards Reference
Detailed tables for each standard → `_shared/assets/standards-reference.md`

| Layer | Standard | Level | When to use |
|-------|----------|-------|-------------|
| Security | OWASP ASVS 5.0 (350 reqs, 17 chapters) | L1=basic, L2=standard, L3=advanced | All web/API apps. L1 minimum. |
| UX/Accessibility | WCAG 2.2 (86 criteria, 4 principles) | A/AA/AAA | Public web apps. AA is legal baseline. |
| Quality (all) | ISO/IEC 25010:2023 (9 characteristics) | Reference model | Architecture docs, vendor eval |
| SaaS Maturity | 4 levels: Ad-Hoc→Reactive→Proactive→Strategic | — | SaaS product governance |

## Cross-References
- **project-mapper**: structure + stack detection
- **security-scanner**: pre-audit security (secrets, vulns)
- **code-review-agent**: code-level gap detection
- **senior-engineer**: trade-off analysis, fix prioritization

## Anti-Patterns
❌ Skip layers because "not relevant" — ALL 6 apply, weight differs
❌ Only functional gaps — technical debt kills velocity
❌ No prioritization — all urgent, nothing done
❌ Score without evidence — Default-FAIL applies
❌ One-shot analysis — gaps need tracking; use engram
❌ Ignore industry standards — reinvent wheels, miss known patterns
