# Success Metrics — Gentleman Agent

**Measurable outcomes beyond the 13-dimension scoring system.**

---

## Overview

The scoring system (`score-auto.ps1`) measures project health across 13 dimensions. This document defines **success metrics** — outcomes that matter to users and the team.

---

## User Satisfaction Metrics

| Metric | Target | Measurement | Source |
|--------|--------|-------------|--------|
| Task completion rate | >90% | Tasks completed without escalation | Engram session summaries |
| First-attempt success | >75% | Tasks done in single pass | Engram session summaries |
| User correction rate | <10% | Times user corrects agent | Engram mem_search (type: decision) |
| Escalation rate | <5% | Tasks requiring human intervention | Engram session summaries |

**Collection**: `mem_session_summary` captures `## Accomplished` and `## Instructions` sections.

---

## Token Efficiency Metrics

| Metric | Target | Measurement | Source |
|--------|--------|-------------|--------|
| Context savings ratio | >60% | Tokens saved via subagent delegation | ctx_stats |
| Cache hit rate | >80% | Repeated queries served from cache | ctx_search cache hits |
| Skill resolution time | <100ms | Time to match task to skill | skill-resolver-fast.ps1 |
| Prompt compression ratio | >50% | Tokens saved via Karpathy compression | token-count.ps1 |

**Collection**: `ctx_stats` provides token usage breakdown. `token-count.ps1` measures prompt sizes.

---

## Code Quality Metrics

| Metric | Target | Measurement | Source |
|--------|--------|-------------|--------|
| PSSA pass rate | 100% | PowerShell scripts pass static analysis | pssa-gate.ps1 |
| Test coverage | >50% | Scripts with Pester test files | score-dims.ps1 (SD sub-dim) |
| Breaking change rate | <2% | Changes that break existing functionality | Git log analysis |
| Review coverage | >90% | Changes reviewed by breaker/judge | Engram breaker saves |

**Collection**: `pssa-gate.ps1`, `score-dims.ps1`, Git history.

---

## Learning Effectiveness Metrics

| Metric | Target | Measurement | Source |
|--------|--------|-------------|--------|
| Pattern capture rate | >5/week | New patterns documented | ANTI-PATTERN-CATALOG.md |
| Wisdom reuse rate | >30% | Cross-project patterns applied | cross-project-wisdom hits |
| Bias calibration samples | >10 | Self-assessment accuracy | bias-calibration.json |
| Cycle completion rate | >80% | Cycles completed vs started | CYCLE.md tracking |

**Collection**: `wisdom-stats.ps1`, `learning-stats.ps1`, CYCLE.md.

---

## Operational Metrics

| Metric | Target | Measurement | Source |
|--------|--------|-------------|--------|
| CI pass rate | >95% | Quality gate passes on first run | GitHub Actions |
| Score trend | stable/up | No score regressions | .project.json trend |
| Skill drift detection | <5 | Skills with unexpected changes | check-skill-drift.ps1 |
| Config drift | <3 | Config files with unexpected changes | check-config-drift.ps1 |

**Collection**: GitHub Actions, `check-skill-drift.ps1`, `check-config-drift.ps1`.

---

## Feedback Loop

```
┌─────────────────────────────────────────────────────────────┐
│                    Feedback Loop                             │
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐               │
│  │ Execute  │───▶│ Measure  │───▶│ Analyze  │               │
│  └──────────┘    └──────────┘    └──────────┘               │
│       ▲                               │                      │
│       │           ┌──────────┐        │                      │
│       └───────────│ Improve  │◀───────┘                      │
│                   └──────────┘                               │
└─────────────────────────────────────────────────────────────┘
```

### Loop Steps

1. **Execute**: Run task with current approach
2. **Measure**: Collect metrics (score, tokens, corrections)
3. **Analyze**: Identify patterns (what worked, what didn't)
4. **Improve**: Update skills, prompts, or workflows
5. **Repeat**: Execute with improved approach

### Triggers

| Trigger | Action | Example |
|---------|--------|---------|
| User corrects 2x | Update skill or prompt | "Don't use var, use const" → update code style skill |
| Same fix 2x | Add to anti-pattern catalog | "Forgot null check" → add null-guard pattern |
| Score drops >0.5 | Investigate and fix | Security score drops → check for new vulnerabilities |
| Token usage spikes | Optimize prompts | Context hits RED zone → compress prompts |

---

## Reporting

### Weekly Report (auto-generated)

```markdown
# Week of {date}

## Metrics
- Tasks: {n} completed, {n} escalated
- Score: {score}/10 ({trend})
- Tokens: {n}K used, {n}% saved via delegation

## Learnings
- {n} new patterns captured
- {n} cross-project wisdom reused

## Issues
- {list of corrections or escalations}
```

### Monthly Review

- Score trend analysis
- Token efficiency trend
- Pattern catalog growth
- Bias calibration accuracy

---

*Metrics version: 1.0 — Project: gentleman-agent-gh*
