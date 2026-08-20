# sdd-propose — Reference Materials

> **Externalized from** .agents/skills/sdd-propose/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains shaping questions, the proposal template, and the return envelope.

## 0: Shaping
Question round before finalizing (3-5/round): business problem, target users, business rules, product outcome, current-state gap, impact, edge cases, decision gaps, scope boundaries, business risk. Summarize assumptions; offer corrections or round 2. Blocked → `## Proposal question round` in result.

## proposal.md Template
```markdown
# Proposal: {Change Title}
{Problem. Why now. User need or tech debt.}
### In Scope - {Deliverable}
### Out of Scope - {Excluded / deferred}
> Contract with sdd-spec. Research `openspec/specs/` first.
### New Capabilities - `<name>`: <description>
### Modified Capabilities - `<name>`: <what changes>
{Technical approach. Reference exploration if available.}
| Area | Impact | Description |
| `path` | New/Mod/Removed | {What changes} |
| Risk | Likelihood | Mitigation |
| {Risk} | Low/Med/High | {Mitigation} |
{Specific revert steps.}
- {Deps if any}
- [ ] {Measurable outcome}
```

## Return Envelope
```markdown
**Change**: {name}
**Location**: `openspec/changes/{name}/proposal.md` | Engram `sdd/{name}/proposal` | inline
- **Intent**: {one-liner} | **Scope**: {N in, M deferred}
- **Approach**: {one-liner} | **Risk**: {Low/Med/High}
Ready for sdd-spec or sdd-design.
```