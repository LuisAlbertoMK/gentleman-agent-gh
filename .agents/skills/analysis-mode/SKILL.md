---
name: analysis-mode
description: "Smart multi-agent analysis — 6 specialists, 8 dimensions, consolidated plan output"
triggers: "!analisis, analysis mode, multi-agent analysis, smart analysis, 8 dimensions, perspective validation"
license: Apache-2.0
metadata:
  tags: [analysis, architecture]
  author: gentleman-vMK
  version: "1.0"
  changelog: "1.0: extracted from AGENTS.md"
  dependencies: [karpathy-loop, lean-context, project-mapper]
---
Overrides DEFAULT/SIMPLE/COMPLEX. Trigger with `!analisis` as first token (case-insensitive).

**ANALYSIS-ONLY GATE**: During `!analisis`, NO code execution, NO file writes EXCEPT the output plan. Any write attempt → BLOQUEAR + log to plan as "blocked action". Must exit analysis mode before implementing.

PRESERVED: Ponytail rung 0, engram save, session close on request.
SKIPPED: triple-verify skill, Security §D, quality gate, commit pipeline, auto-metrics, Ponytail rungs 1-8.
EXEMPT from §A Skill combo (uses Q&A load: karpathy-loop + lean-context).

## PROCESS
0. **Project-mapper**: detect stack (lenguajes, frameworks, DB, infra) via skill `project-mapper`.
0.5. **Wisdom injection**: `. "$env:GENTLEMAN_AGENT_ROOT\scripts\bash-safe.ps1"; & "$env:GENTLEMAN_AGENT_ROOT\scripts\wisdom-loader.ps1" -Technology "<stack>"` → add matching patterns as "known gotchas" to sub-agent briefings.
1. **Smart selection**: pick 6 of 7 specialists per stack (FREE TIER), auto-exclude irrelevant:
   - security=nemotron-3-ultra-free · infra=deepseek-v4-flash-free · frontend=kimi-k2.5-free
   - performance=nemotron-3-ultra-free · datascience=mimo-v2.5-free · docs=big-pickle
   - seo=nemotron-3-super-free (public sites only)
2. Load karpathy-loop + lean-context. Parallel: 6 subagents + 1 web research.
3. Each subagent returns: `Decision Taken | Files Changed | Key Findings | Nuance`.
4. **Perspective validation** — ALL 8 mandatory dimensions or FAIL:

| # | Dim | Agent | Scope |
|---|-----|-------|-------|
| 1 | Security | security | Auth, injection, secrets, vulns |
| 2 | Performance | performance | Load, latency, N+1, cache, bundle |
| 3 | UX | frontend | Flows, a11y, design system |
| 4 | Infra | infra | Docker, scaling, DR, CI/CD |
| 5 | Data | datascience | DB schema, queries, pipelines |
| 6 | Architecture | main | Coupling, patterns, tech debt |
| 7 | DX | docs | Docs, onboarding, tooling |
| 8 | Business | main | Roadmap, priorities, ROI |

5. Synthesize: consensos, divergencias, fundamentos, risk score per finding.

## OUTPUT
- **Location**: `docs/mejoras/YYYY-MM-DD-<project-name>-analisis.md`
- **Format**: Structured plan with sections: Executive Summary, Per-Dimension Findings, Consensus, Divergence, Risk Matrix, Recommendations
- **Lifecycle**: First run → create v1. Subsequent runs → update existing file (increment version in header).
- **Gate**: Plan only — NO code, NO commit. Must exit analysis mode before implementing.
