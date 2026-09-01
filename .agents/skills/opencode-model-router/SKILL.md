---
name: opencode-model-router
description: "Route tasks by model strength — specialized agents for analysis, implementer for execution"
changelog: "2026-08-31 — SD 9.9→10 fix"
token_budget: 820
---

## When to Use
Route to 78 specialists via domain→agent table. Truth: `scripts/lib/opencode-base.json`.

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
| reasoning | gentleman-reasoning | # P0-3 reasoning tier (nemotron-3-ultra-free, chain-of-thought) |
| quick-edit | gentleman-quick |
| default | gentleman-vMK |

## Refs
Cross-Refs: skill-graph | skill-registry
