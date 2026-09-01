---
name: sdd-propose
description: "Create SDD change proposal with intent, scope, approach. Trigger: orchestrator launches proposal work."
triggers: "SDD propose, proposal, intent, approach, change proposal"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2322
---
Input: change name, exploration analysis OR user description, store mode (`engram|openspec|hybrid|none`).
| Mode | Behavior |
|---|---|
| `engram` | Read `sdd/{change}/explore` + `sdd-init/{project}` (opt); save as `sdd/{change}/proposal` |
| `openspec` | Follow `openspec-convention.md` |
| `hybrid` | Both (Engram primary + filesystem) |
| `none` | Return only |
Never force `openspec/` unless requested or `hybrid`.
### 1: Load Skills → §A `sdd-phase-common.md`
### 2: Create Directory
openspec/hybrid: `openspec/changes/{change}/proposal.md` · engram/none: skip
### 3: Read Specs (openspec/hybrid: `openspec/specs/`)
### 4: Write proposal.md — template → reference. **Budget**: <450 words; bullets/tables > prose. No spec changes → "None" in both Capabilities.
### 5: Persist — §C: artifact `proposal`, topic_key `sdd/{change}/proposal`, type `architecture`
### 6: Return — envelope → reference.
`openspec` mode: always create `proposal.md`; exists → read → update. Every proposal: rollback plan + success criteria; concrete paths in Affected Areas.
## Anti-Patterns
- **Over-specification**: no pseudo-code/signatures/algorithms — proposal owns what/why, sdd-spec owns how
- **Vague scope**: In/Out must list concrete paths — "Improve auth" unverifiable vs "JWT issuer, refresh flow, rate limiting"
## Reference
Shaping questions + proposal template + return envelope → docs/skills/sdd-propose/reference.md
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: sdd | sdd-spec

