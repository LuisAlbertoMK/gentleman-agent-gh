# Quality Standard (Gentleman-VMK)

> **Load on-demand**: `read operations/quality-standard.md` before commit or when doing complex changes.
> Applies to EVERY project, EVERY change, EVERY session. No exceptions.

## Quality Dimensions (Agent Review)

These are checked by the agent during code review. They are NOT scored numerically.

| # | Dimension | What I check | Trigger |
|---|-----------|-------------|---------|
| 1 | **Project Artifacts** | README, ROADMAP, PRD, CHANGELOG, ARCHITECTURE.md, ADRs — exist, current, accurate | Session start + gap detected |
| 2 | **Security** | Secrets in code, dep vulnerabilities, auth gaps, input validation, XSS/CSRF, SSRF | Intake + relevant changes |
| 3 | **Performance** | Bottlenecks, N+1 queries, bundle size, render cycles, Core Web Vitals, memory leaks | Intake + relevant changes |
| 4 | **Optimization** | Algorithm efficiency, caching, lazy loading, memoization, code splitting, tree-shaking | Intake + relevant changes |
| 5 | **Dead Code** | Unused exports, orphan functions, unreachable branches, commented-out code, dead imports | Intake + relevant changes |
| 6 | **Clean Code** | Naming, SRP, DRY, cyclomatic complexity, god objects, magic numbers, long functions | **Every code change** |
| 7 | **Best Practices** | Framework conventions, error handling, logging, test coverage, type safety, edge cases | **Every code change** |
| 8 | **UI/UX** | Usability, accessibility (a11y — WCAG), visual hierarchy, consistency, affordances, feedback | UI/frontend changes |
| 9 | **Responsive** | Mobile-first, breakpoints, touch targets (≥44px), layout shifts (CLS), print styles | UI/frontend changes |
| 10 | **SEO** | Meta tags, semantic HTML, JSON-LD structured data, heading hierarchy, alt text, sitemap, canonical | Web/frontend changes |
| 11 | **Orthography** | Typos, grammar, consistent language (regional variants), punctuation, case consistency | **Every text/output** |
| 12 | **Bitácora** | Track changes, decisions, rationale in `BITACORA.md` or CHANGELOG | **Every session** |
| 13 | **Metrics** | Before/after scoring, delta tracking, trend analysis in `docs/metricas/` | Every task ≥3 steps |

## Scoring Dimensions (Automated)

These are computed by `scripts/score-auto.ps1` → `scripts/lib/score-dims.ps1`. They produce the project score.

| # | Code | Dimension | What it measures |
|---|------|-----------|-----------------|
| 1 | PA | Project Artifacts | README, cross-refs, skill count, .project.json |
| 2 | Sec | Security | Weak crypto, hardcoded secrets |
| 3 | DC | Dead Code | Orphan skills, dead junctions, commented-out code |
| 4 | CC | Clean Code | Help, params, strict mode, try/catch coverage |
| 5 | BP | Best Practices | Parameter coverage, error handling ratio |
| 6 | Or | Orthography | UTF-8 corruption / mojibake detection |
| 7 | Bi | Bitácora | BITACORA.md existence and line count |
| 8 | Me | Metrics | Metricas dir, error logs, reports existence |
| 9 | SP | Script Performance | Script count, avg size, huge scripts |
| 10 | SE | Skill Effectiveness | Skill count, size distribution, overweight |
| 11 | CA | Cycle Activity | Inter-track cycle progress |
| 12 | BI2 | Backlog Integrity | Backlog item pass rate |
| 13 | SD | Score Depth | 42 sub-dimensions across all above |
| 14 | SG | SSoT Age | .project.json staleness (days since last update) |

> **Note**: Quality dimensions (agent review) and Scoring dimensions (automated) overlap on some names (Security, Dead Code, etc.) but measure different things. Quality dimensions are qualitative checks; scoring dimensions are quantitative metrics.

## Triggers
- **Session start (unknown project)** → full 13-dim quality intake
- **Session start (known project)** → gap check on artifacts
- **Code change** → run relevant quality dimensions
- **Before commit** → quality gate w/ applicable dimensions
- **Session end** → bitácora + metrics + engram summary

## Always-On (never negotiate)
1. Orthography: zero typos in every text
2. Clean Code: every function — check naming, SRP, complexity
3. Bitácora: every significant change logged
4. Metrics: tasks ≥3 steps → before/after scoring
5. Artifacts: missing/stale → flag + offer to fix
