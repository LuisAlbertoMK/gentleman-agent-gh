---
name: sdd-init
description: "Initialize SDD context, testing capabilities, registry, and persistence."
delegate_only: true
---

> **GATE**: Loaded via `skill()` -> STOP. Delegate to `sdd-init` sub-agent. Executor -> run directly.

## Activation
Run when asked to initialize SDD. You are the phase executor - do the work, don't delegate, don't act as orchestrator.

## Language
Artifacts default English; Spanish neutral/professional only if requested/required. Comments follow target context.

## Hard Rules
- Detect real stack, conventions, architecture, testing tools, persistence mode - never guess
- engram mode: do NOT create `openspec/`
- openspec mode: follow `../_shared/openspec-convention.md`, write file artifacts
- hybrid: both openspec files + Engram observations
- ALWAYS persist testing capabilities separately (`sdd/{project}/testing-capabilities` or `openspec/config.yaml` `testing:`)
- ALWAYS build `.atl/skill-registry.md`; save `skill-registry` to Engram when available
- `capture_prompt: false` for automated saves when supported
- `openspec/` exists -> report what exists, ask before updating

## Decision Gates
| Input | Action |
|---|---|
| mode=engram | Context + capabilities to Engram only |
| mode=openspec | openspec bootstrap files only |
| mode=hybrid | Both |
| mode=none | Detected context only; no SDD artifacts except registry if required |
| strict TDD marker/config | Use that value |
| no marker, runner exists | Default `strict_tdd: true` |
| no runner | `strict_tdd: false` + explain unavailable |

## Steps
1. Inspect project files (package.json, go.mod, pyproject.toml, CI, lint/test config) -> summarize stack/conventions.
2. Detect runner, test layers, coverage, linter, type checker, formatter.
3. Resolve Strict TDD: agent marker -> config.yaml -> runner fallback -> no-runner fallback.
4. Initialize persistence for resolved mode.
5. Build `.atl/skill-registry.md` (skill-registry scan rules).
6. Persist testing capabilities + project context.
7. Return structured init envelope.

## Output
`status`, `executive_summary`, `artifacts`, `next_recommended`, `risks` + project, stack, persistence mode, Strict TDD status, testing capability table, saved observation IDs/paths, registry path, next `/sdd-explore` or `/sdd-new`.

## References
- `references/init-details.md` (detection checklist, Engram payloads, config skeleton, templates)
- `../_shared/engram-convention.md`, `../_shared/openspec-convention.md`