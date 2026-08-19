---
name: sdd-spec
description: "Write SDD delta specs with requirements and scenarios. Trigger: orchestrator launches spec work."
triggers: "SDD spec, specification, given when then, requisitos, spec writing"
delegate_only: true
changelog: docs/ciclos/cycle28-20260815.md
---

> **ORCHESTRATOR GATE**: `skill()` → STOP, delegate to `sdd-spec` sub-agent.

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

### Delta Format (condensed)
```
# Delta for {Domain}
### Requirement: {Name}
{RFC 2119} {behavior}
#### Scenario: {Name} - GIVEN/WHEN/THEN
### Requirement: {Name} (Previously: {what changed}) - GIVEN/WHEN/THEN
### Requirement: {Name} (Reason: {why}) (Migration: {replacement})
### Requirement: {Old} → {New} (Reason: {why}) (Migration: {how})
```

### MODIFIED Workflow (CRITICAL)
1. Copy ENTIRE requirement block (from `### Requirement:` through ALL scenarios)
2. Paste under `## MODIFIED Requirements` → Edit → Add "(Previously: {summary})"
NEVER write partial MODIFIED blocks. New behavior without changing existing → ADDED.

### New Domain (No Existing Spec)
Full spec: `# {Domain} Specification` → `## Purpose` → `## Requirements` with Given/When/Then.

5. **Persist** — §C of `sdd-phase-common.md`: artifact `spec`, topic_key `sdd/{change}/spec`, type `architecture`
6. **Return Summary**: Change, domain table (Type, Reqs, Scenarios), coverage (happy/edge/error), Next phase.

- Given/When/Then for all scenarios; RFC 2119 keywords (MUST/SHALL/SHOULD/MAY)
- Every requirement: ≥1 scenario (happy + edge cases); Scenarios TESTABLE — automatable from G/W/T
- Specs describe WHAT, not HOW; MODIFIED: ALWAYS copy full requirement + all scenarios before editing
- REMOVED: include Reason; Migration if consumers affected; RENAMED: state both names; include Migration
- Apply `rules.specs` from `openspec/config.yaml`; Size: <650 words; Prefer tables; Scenarios: 3-5 lines max
- Return envelope per §D of `sdd-phase-common.md`

---
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/sdd-spec/reference.md

---