---
name: opencode-model-router
description: "Route tasks by model strength"
triggers: "route, model router, which agent, delegate by domain"
changelog: "2026-09-01 P0-3"
token_budget: 1700
---

## When to Use
Route via table. Truth: `scripts/lib/opencode-base.json`.

## Routing Table

| Domain | Agent |
|--------|-------|
| security | gentleman-security |
| seo | gentleman-seo |
| infra | gentleman-infra |
| frontend | gentleman-frontend |
| performance | gentleman-performance |
| datascience | gentleman-datascience |
| docs | gentleman-docs |
| aem | gentleman-aem |
| vision | gentleman-vision |
| api | gentleman-datascience |
| accessibility | gentleman-frontend |
| container | gentleman-infra |
| deep-debug | gentleman-deep |
| harness-init | gentleman-initializer | # different prompt first window (Anthropic 2025-11-26) |
| code-review | gentleman-code-review | # Qwen 73.4% → muse-spark → default |
| reasoning | gentleman-reasoning |
| quick-edit | gentleman-quick |
| default | gentleman-vMK |

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Use vMK for everything" | Routing everything to one agent | Check table first — if domain matches, use specialist |
| "Save tokens with quick" | Skipping deep for complex task | Scope>2 files or risk>medium → deep/reasoning, not quick |
| "Fallback to default is fine" | `default` used for known domain | `default` only when table has no match |

## Red Flags
- Routing without reading `opencode-base.json` truth (drift risk)
- Using `laguna` family agents (404 — must be muse-spark)

## Verification
- After routing: `git diff --stat` confirms no cross-agent file overlap before parallel delegation
- Spot-check: 1 critical file semantic coherence before commit

## Refs
Cross-Refs: skill-graph | skill-registry
