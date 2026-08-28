---
name: sdd-init
description: "Initialize SDD context, testing capabilities, registry, persistence. Trigger: sdd init, iniciar sdd, openspec init."
triggers: "SDD init, initialize SDD, bootstrap SDD, SDD context setup"
delegate_only: true
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1672
---

## Activation
Run when orchestrator/user asks to initialize SDD. You are the phase executor — do the work, don't delegate.

## Language
Generated artifacts default to English. Spanish: neutral/professional unless regional variant requested. Comments follow target context.

## Hard Rules
- Detect real stack, conventions, architecture, testing tools, persistence mode; never guess.
- `engram`: do NOT create `openspec/`. `openspec`: follow `../_shared/openspec-convention.md`, write files. `hybrid`: write both.
- Always persist testing capabilities as `sdd/{project}/testing-capabilities` or `openspec/config.yaml` `testing:`.
- Always build `.atl/skill-registry.md`; save `skill-registry` to Engram when available.
- `capture_prompt: false` for automated SDD/config saves.
- If `openspec/` exists, report what exists and ask before updating.

## Decision Gates
| Input | Action |
|---|---|
| `mode=engram` | Save context + capabilities to Engram only |
| `mode=openspec` | Create/update openspec bootstrap files only |
| `mode=hybrid` | Both Engram and openspec |
| `mode=none` | Return detected context only; no SDD artifacts except registry |
| Strict TDD marker/config found | Use that value |
| No marker but test runner exists | Default `strict_tdd: true` |
| No test runner | Set `strict_tdd: false`, explain unavailable |

## Reference
> docs/skills/sdd-init/reference.md
## Refs
Cross-Refs: sdd | sdd-explore
