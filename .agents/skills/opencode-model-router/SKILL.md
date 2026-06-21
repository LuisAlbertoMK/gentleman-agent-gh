---
name: opencode-model-router
description: "Route tasks by model strength — delegated vs direct handling, with security gates and fallback chains"
triggers: "model router, routing, delegate or direct, model decision, trial risk, security gate"
license: Apache-2.0
metadata:
  tags: [engineering, routing, orchestration]
  author: gentleman-vMK + Big Pickle
  version: "1.1"
  changelog: "1.1: Karpathy compression (4.9→2.5KB), removed verbose description, merged security+risk"
---

# opencode-model-router

Decision tree for Big Pickle: **delegate vs direct** based on task type, context size, and model risk.

## ⚠️ SECURITY GATE (always first)
1. Credentials/secrets/PII? → **DIRECT**. Never delegate.
2. Recurring task (cron/CI)? → **DIRECT**. Trial models may disappear.
3. Context >150K tokens? → **DIRECT**. Only Big Pickle handles >150K stably.
4. Otherwise → continue to routing.

## Routing Table
| Type | Primary | Fallback | Skill |
|------|---------|----------|-------|
| UI/UX • CSS • Tailwind | Delegate | Direct | `baseline-ui` |
| React/Frontend (<100K ctx) | Delegate | Direct | `baseline-ui` |
| E2E Testing | Delegate | Direct | per stack |
| Performance • CWV | Delegate | Direct | `performance` |
| Syntax/Linting | Delegate | Direct | `code-review-agent` |
| SEO • Content | Delegate | Direct | `seo` |
| **Architecture** | **DIRECT** | — | `senior-engineer` |
| **Codebase Audit >150K** | **DIRECT** | — | `project-mapper` |
| **Code Review** | **DIRECT** | — | `code-review-agent` |
| **Full Feature** | **DIRECT** | — | `sdd-*` |
| **Recurring/Cron** | **DIRECT** | — | per task |
| Default | **DIRECT** | — | `skill-graph` |

## Delegate Pattern
```
DELEGATE(subagent, prompt + style hint)
  → OK → integrate result
  → fail (timeout/error) → DIRECT with skill
  → partial → complete direct
```

## Fallback Chain
```
DeepSeek V4 Flash (trial, medium risk) → Big Pickle (stable)
MiMo-V2.5 (trial, high risk) → Big Pickle
Nemotron 3 Ultra (trial, high risk) → Big Pickle
Big Pickle → end of chain
```

## Context → Action
| Context | Action |
|---------|--------|
| <50K | Normal routing |
| 50K-100K | Prefer delegate for fast models |
| 100K-150K | Delegate only critical syntax/perf |
| >150K | Security Gate → direct forced |
| >200K | Direct mandatory |

## Model Risk
| Model | Risk | Notes |
|-------|------|-------|
| Big Pickle | Low | Production, long sessions |
| DeepSeek V4 Flash | Medium | May disappear. Active tasks only. |
| MiMo-V2.5 | High | Exploration only |
| Nemotron 3 Ultra | High | One-off. No sensitive data. |

`ponytail:` delegate() has no model hint control — when OpenCode adds it, update routing table.
