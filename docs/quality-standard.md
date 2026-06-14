# Quality Standard (Gentleman-VMK)

> **Load on-demand**: `read docs/quality-standard.md` before commit or when doing complex changes.
> Applies to EVERY project, EVERY change, EVERY session. No exceptions.

## 13 Quality Dimensions

| # | Dimensión | What I check | Trigger |
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
| 12 | **Bitácora** | Track changes, decisions, rationale in `docs/bitacora.md` or CHANGELOG | **Every session** |
| 13 | **Metrics** | Before/after scoring, delta tracking, trend analysis in `docs/metricas/` | Every task ≥3 steps |

## Triggers
- **Session start (unknown project)** → full 13-dim intake cycle
- **Session start (known project)** → gap check on artifacts
- **Code change** → run relevant dimensions (CSS → responsive + UI/UX; API route → security + perf)
- **Before commit** → quality gate w/ applicable dimensions (minimum: clean code + orthography)
- **Session end** → bitácora + metrics + engram summary

## Always-On (never negotiate)
1. Orthography: zero typos in every text
2. Clean Code: every function — check naming, SRP, complexity
3. Bitácora: every significant change logged
4. Metrics: tasks ≥3 steps → before/after scoring
5. Artifacts: missing/stale → flag + offer to fix
