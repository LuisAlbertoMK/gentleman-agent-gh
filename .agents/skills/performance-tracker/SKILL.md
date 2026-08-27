---
name: performance-tracker
description: "Score and track app performance — 6 dims, continuous scoring, trend analysis"
triggers: "performance score, mobile perf, desktop perf, rendimiento, app score, benchmark, perf tracking, performance trend"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 576
---
## When to Use
Score and track app performance — 6 dims, continuous scoring. App PERFORMANCE only (agent perf → `auto-metrics`). Mobile, Desktop, Web.
## 6 Dimensions (1-10)
Load|Render|Memory|Network|Bundle|Energy — thresholds, quick checks → reference.
## Score Storage & Trend
`mem_save(type="learning", title="perf-score:{app}-{platform}", content="**Load**:X|...|**Avg**:X.X|**Platform**:{mob|desk|web}|**App**:{name}")`. Trend (every 10 / session end): `mem_search(query="perf-score:", limit=20)` → prev(5) vs recent(5). Drop >0.5 → gap-analysis.
## Action by Avg
≥8 Maintain · 6-7.9 Light review + profile · 4-5.9 gap-analysis + fix · <4 Critical perf sprint
## Hard Rules
- Score EVERY dimension from real measurement — NEVER guess ("feels fast")
- Platform in title (`perf-score:{app}-{platform}`); NEVER mix platforms in one trend
- NEVER skip a dimension — unavailable → neutral 7 + annotate
- Trend only at N≥5; regression = drop >0.5 → gap-analysis; >0.2 → light review
- CI: median-of-3 lighthouse; never crash on missing process — degrade to static-only
## Output
`PERF-SCORE:<app>—<date> DIMS:[Load|Render|Memory|Network|Bundle|Energy]=<1-10> AVG=<n.n> PLATFORM:<mob|desk|web> TREND:<delta>→<stable|drift|regression>`
## Anti-Patterns
Score without real data · cross-platform in same trend · skip bundle/cache · score once
## Reference
Thresholds table + quick checks + worked examples (5) → docs/skills/performance-tracker/reference.md

## Verification
- Output: response matches the ## Output contract format exactly
- token_budget: total tokens within frontmatter token_budget
- frontmatter: name, description, triggers, token_budget present and stable
- cross-refs: each referenced skill exists
- anti-patterns: none of the listed anti-patterns reintroduced
