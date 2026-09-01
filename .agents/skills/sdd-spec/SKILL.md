---
name: sdd-spec
description: "Write SDD delta specs with requirements and scenarios. Trigger: orchestrator launches spec work."
triggers: "SDD spec, specification, given when then, requisitos, spec writing"
delegate_only: true
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2339
---
From orchestrator: change name, artifact store (`engram | openspec | hybrid | none`).
- **engram**: Read `sdd/{change}/proposal`; save as `sdd/{change}/spec`
- **openspec**: Read `openspec-convention.md`
- **hybrid**: Both
- **none**: Return only
1. **Load Skills** — §A of `sdd-phase-common.md`
2. **Identify Domains** from proposal's Capabilities:
   - New → FULL spec at `openspec/specs/<name>/spec.md`
   - Modified → DELTA spec at `openspec/changes/{change}/specs/<name>/spec.md`; read existing first
   - Fallback: infer from "Affected Areas"
3. **Read Existing Specs** (openspec/hybrid: `openspec/specs/{domain}/spec.md`)
4. **Write Specs** (openspec/hybrid: `openspec/changes/{change}/specs/{domain}/spec.md`)
### MODIFIED Workflow (CRITICAL)
1. Copy ENTIRE requirement block (from `### Requirement:` through ALL scenarios)
2. Paste under `## MODIFIED Requirements` → Edit → Add "(Previously: {summary})"
NEVER write partial MODIFIED blocks. New behavior without changing existing → ADDED.
5. **Persist** — §C of `sdd-phase-common.md`: artifact `spec`, topic_key `sdd/{change}/spec`, type `architecture`
6. **Return Summary**: Change, domain table (Type, Reqs, Scenarios), coverage (happy/edge/error), Next phase.
Rules (Given/When/Then, RFC 2119, MODIFIED copy, REMOVED/RENAMED Migration, <650 words) → reference.
## Reference
Delta Format + New Domain + rules → docs/skills/sdd-spec/reference.md
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
Cross-Refs: sdd | sdd-design

