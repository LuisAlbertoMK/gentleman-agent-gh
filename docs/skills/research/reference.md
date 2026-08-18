# research — Reference Materials

> **Externalized from** .agents/skills/research/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Example: Library Evaluation
Search pattern combining both tools:
```
websearch("zustand vs jotai vs valtio 2026 benchmark" numResults=8)
→ webfetch(URL of top comparison)
→ websearch("zustand migration from redux experience" numResults=5)
→ webfetch(URL of migration guide)
```

| Criteria | Zustand | Jotai | Valtio |
|----------|---------|-------|--------|
| Bundle | 2.5 KB | 4.2 KB | 3.1 KB |
| API style | Single store | Atomic atoms | Proxy-based |
| Learning curve | Low | Medium | Medium |
| React 19 compat | ✅ | ✅ | ⚠️ pending |
| **Pick if** | Simple state | Fine-grained | Mutable style |

## Dead Ends
Document rejected paths to prevent future re-evaluation:
```
**Not pursuing**: {option}
**Why**: {licensing | perf below threshold | unmaintained since Y}
**Evidence**: {link/benchmark}
**Re-evaluate if**: {trigger condition}
```
Save via: `mem_save(title="Research: {topic} — rejected {option}" type="discovery")`

## Post-Research mem_save
```
title: "Research: {topic} — recommendation"
type: "decision"
content: |
  **What**: Selected {winner} over {alternatives}
  **Why**: {top 2 reasons}
  **Where**: {implementation files}
  **Rejected**: {option} because {fatal flaw}
  **Confidence**: {1-5}
```

## Depth Levels
| Level | Sources | Time |
|-------|---------|------|
| Quick Scan | 2-3 | 5-10 min |
| Moderate | 5-8 | 20-40 min |
| Deep | 10+ + PoC | 1-4 hrs |

## Anti-Patterns
Confirmation bias | Doc-only (no real-world check) | No deadline | Single source | Old info

## Commands
```
websearch("TOPIC 2026 comparison OR benchmark" numResults=8)
webfetch(URL)
websearch("TOPIC vs ALTERNATIVE pros cons 2026" numResults=10)
mem_save(title="Research: TOPIC" type="discovery")
```

## Refs
cross-project-wisdom · execution-mode · skill-graph

## Examples (4-5)

### Example 1: Framework Migration Path
**Goal**: Evaluate migration from Next.js Pages Router to App Router for a 200-page e-commerce site
```
Scope: 2-week decision window, zero-downtime requirement, team of 8
Gather:
  - websearch("Next.js App Router migration guide 2026" numResults=8)
  - websearch("Next.js Pages to App Router incremental migration" numResults=6)
  - webfetch(Next.js official migration docs)
  - websearch("App Router production case study ecommerce 2026" numResults=5)
Synthesize: 3-column table (effort | risk | benefit per feature area)
Decide: Incremental route-group migration, defer Server Actions to Phase 2
```

### Example 2: State Management Selection
**Goal**: Pick state library for new React 19 + TanStack Query project
```
Scope: 1-day spike, bundle budget <10KB, team familiar with Redux
Gather:
  - websearch("zustand vs jotai vs redux-toolkit 2026 bundle size" numResults=8)
  - websearch("TanStack Query + Zustand integration patterns" numResults=5)
  - webfetch(Zustand v5 release notes)
Synthesize: 4-criteria matrix (bundle | DX | TS support | migration path)
Decide: Zustand v5 — 2.5KB, hooks API, first-class TS, Redux DevTools compat
```

### Example 3: Database Technology Evaluation
**Goal**: Choose primary DB for multi-tenant SaaS (PostgreSQL vs PlanetScale vs Neon)
```
Scope: 3-day deep dive, PoC required, 5-year horizon
Gather:
  - websearch("PostgreSQL multi-tenancy patterns 2026 row level security" numResults=8)
  - websearch("PlanetScale vs Neon branching workflow comparison" numResults=6)
  - webfetch(PlanetScale schema migration docs)
  - websearch("Neon autoscaling cold start latency 2026" numResults=5)
Synthesize: 6-dim matrix (cost | scaling | branching | RLS | tooling | vendor lock-in)
Decide: PostgreSQL + RLS — full control, mature ecosystem, zero vendor lock-in
```

### Example 4: Authentication Architecture
**Goal**: Design auth for B2B app with SSO, RBAC, and audit logging
```
Scope: 2-day architecture spike, compliance requirements (SOC2), team knows OIDC
Gather:
  - websearch("NextAuth v5 vs Clerk vs Auth0 B2B enterprise 2026" numResults=8)
  - websearch("OIDC RBAC claims mapping best practices" numResults=5)
  - webfetch(NextAuth v5 adapter architecture)
  - websearch("audit logging authentication events OpenTelemetry" numResults=4)
Synthesize: Build-vs-buy matrix + compliance gap analysis
Decide: NextAuth v5 (self-hosted) + custom audit middleware — control + cost
```

### Example 5: Performance Investigation
**Goal**: Diagnose 3s LCP on mobile checkout page
```
Scope: 4-hour investigation, production data access, no code freeze
Gather:
  - websearch("Next.js 15 LCP optimization server components 2026" numResults=6)
  - websearch("React 19 useDeferredValue vs startTransition benchmarks" numResults=5)
  - webfetch(web.dev INP optimization guide)
  - Chrome DevTools trace + Lighthouse CI runs (local evidence)
Synthesize: Waterfall analysis → root cause table (blocking JS | images | fonts | TTFB)
Decide: Font subsetting + streaming SSR + priority hints — projected 40% LCP gain

## Testing (3 scenarios)

### Test 1: Scope Guard
```bash
# Input: "Research everything about React"
# Expected: REJECT — scope too broad, no constraints, no deadline
# Fix: "Research React 19 Server Components vs Client Components for data fetching in 2 hours"
```

### Test 2: Source Quality Gate
```bash
# Input: 3 sources all from same vendor blog (e.g., 3 Vercel posts)
# Expected: REJECT — single-vendor bias, no community/benchmarks
# Fix: Require ≥1 official, ≥1 community, ≥1 benchmark/third-party
```

### Test 3: Decision Traceability
```bash
# Input: Research completes with recommendation but no mem_save
# Expected: REJECT — decision not persisted, future sessions lose context
# Fix: mem_save with title="Research: {topic} — recommendation" type="decision"
```

## Edge Cases (4)

### Edge Case 1: Conflicting Benchmarks
**Scenario**: Bundlephobia says 15KB, npm says 42KB, actual gzipped in app is 8KB
**Resolution**: Trust production build measurement > registry stats > bundlephobia
**Action**: Run `npm pack && gzip -c package.tgz | wc -c` in actual project context

### Edge Case 2: Rapid Version Churn
**Scenario**: Library releases v1.0 → v2.0 → v3.0 in 3 months; docs lag behind
**Resolution**: Pin to latest stable minor, read CHANGELOG + GitHub issues, not just docs
**Action**: websearch("{lib}@latest breaking changes migration guide" numResults=10)

### Edge Case 3: Inaccessible Primary Source
**Scenario**: Vendor docs behind login/wall; only secondary summaries available
**Resolution**: Use secondary sources but flag confidence as "unvalidated"
**Action**: mem_save with confidence: unvalidated + note "vendor docs inaccessible"

### Edge Case 4: Dead End with Partial Value
**Scenario**: 3-day deep dive proves approach unworkable, but yields reusable patterns
**Resolution**: Document rejection + extract salvageable patterns as separate discoveries
**Action**: Two mem_save — one rejection, one pattern extraction

## Anti-Patterns (2 additional)

| Anti-Pattern | Symptom | Fix |
|--------------|---------|-----|
| **Analysis Paralysis** | Research exceeds deadline by 2x+ with no decision | Hard timebox per phase; escalate at 80% budget |
| **Proxy Metric Optimization** | Optimizing bundle size when TTFB is the real bottleneck | Validate metric-to-outcome correlation before deep dive |
