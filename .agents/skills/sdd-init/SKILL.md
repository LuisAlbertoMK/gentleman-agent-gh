---
name: sdd-init
description: "Initialize SDD context, testing capabilities, registry, persistence. Trigger: sdd init, iniciar sdd, openspec init."
triggers: "SDD init, initialize SDD, bootstrap SDD, SDD context setup"
delegate_only: true
changelog: docs/ciclos/cycle28-20260815.md
---

> **ORCHESTRATOR GATE**: `skill()` → ORCHESTRATOR STOP, delegate to `sdd-init` sub-agent. Executor: execute directly.

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

## Execution Steps
1. Inspect project files (`package.json`, `go.mod`, `pyproject.toml`, CI, lint/test config) → summarize stack/conventions.
2. Detect test runner, test layers, coverage, linter, type checker, formatter.
3. Resolve Strict TDD from agent marker, `openspec/config.yaml`, detected runner fallback, or no-runner fallback.
4. Initialize persistence for resolved mode.
5. Build `.atl/skill-registry.md` using skill-registry scan rules.
6. Persist testing capabilities and project context.
7. Return structured initialization envelope.

## Output Contract
Return `status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`. Include: project, stack, persistence mode, Strict TDD status, testing capability table, saved observation IDs/paths, registry path, next `/sdd-explore` or `/sdd-new` step.

---

> See [reference.md](docs/skills/sdd-init/reference.md) for extended details, examples, and detailed patterns.