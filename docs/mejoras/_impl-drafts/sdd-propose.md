---
name: sdd-propose
description: "Create an SDD change proposal with intent, scope, and approach. Trigger: orchestrator launches proposal work for a change."
license: MIT
metadata:
  author: gentleman-programming
version: 1.0.0-local
triggers: "SDD propose, proposal, intent, approach, change proposal, SDD proposal"
  version: "2.0"
  delegate_only: true
---

> **GATE**: Loaded via `skill()` -> STOP. Delegate to `sdd-propose` sub-agent. Executor -> run directly.

## Contract
Artifacts default English; Spanish only if explicitly requested.

## Inputs
Change name, exploration analysis OR user description, store mode (`engram|openspec|hybrid|none`).

## Persistence (sdd-phase-common B+C)
| Mode | Behavior |
|---|---|
| engram | Read `sdd/{change}/explore` + `sdd-init/{project}` (opt); save `sdd/{change}/proposal` |
| openspec | `openspec-convention.md` |
| hybrid | Both (Engram primary) |
| none | Return only |

Never force `openspec/` unless requested or hybrid.

## Steps
0. **Interactive shaping**: question round (3-5 Qs) before finalizing - business problem, users, rules/compliance, product outcome, current gap, impact, edge cases, decision gaps, scope boundaries, business risk. Summarize assumptions; offer corrections/round 2. Blocked from asking -> write `## Proposal question round` in result.
1. Load skills (Section A).
2. Create dir (openspec/hybrid): `openspec/changes/{change}/proposal.md`.
3. Read specs (openspec/hybrid): from `openspec/specs/`.
4. **Write proposal.md**: `# Proposal: {Title}` -> `## Intent` (problem/why-now) -> `## Scope` (In/Out) -> `## Capabilities` (New: each `openspec/specs/<name>/spec.md`, kebab-case; Modified: existing specs with changing requirements, delta) -> `## Approach` -> `## Affected Areas` (Area|Impact|Description) -> `## Risks` (Likelihood, Mitigation) -> `## Rollback Plan` -> `## Dependencies` -> `## Success Criteria` [ ]. Budget <450 words; bullets/tables over prose; no spec changes -> "None" in both Capabilities subsections.
5. **Persist (MANDATORY)**: Section C; artifact `proposal`, key `sdd/{change}/proposal`, type `architecture`.
6. **Return**: change, location, intent one-liner, scope N in/M deferred, approach, risk level, ready for sdd-spec or sdd-design.

## Rules
- openspec mode: always create proposal.md; exists -> read -> update
- Every proposal: rollback plan + success criteria
- Concrete file paths in Affected Areas; `rules.proposal` from config.yaml
- ALWAYS fill Capabilities - contract with sdd-spec
- Envelope per Section D (sdd-phase-common)