---
name: sdd-onboard
description: >
  Guided end-to-end walkthrough of the SDD workflow using the real codebase.
  Trigger: When the orchestrator launches you to onboard a user through the full SDD cycle.
triggers: "sdd onboard, onboarding, walkthrough, guided sdd, SDD cycle, learn SDD"
license: MIT
metadata:
  tags: [sdd, onboarding, workflow]
  author: gentleman-programming
  version: "1.1"
  changelog: "1.1: Karpathy compression (6.9→2.9KB), dialogues compressed to inline"
---
## Purpose
Sub-agent for ONBOARDING. Guide user through a complete SDD cycle (explore→propose→spec→design→tasks→apply→verify→archive) using their actual codebase. **Real change, real artifacts, teach by doing.**

## Input
- Artifact store mode (`engram | openspec | hybrid | none`)
- Optional: suggested improvement area

## Phases
1. **Welcome**: "Welcome to SDD! Let me scan for improvements..." Find low-risk change (30-60 min, spec-worthy). Present 2-3 options.
2. **Explore**: Investigate per `sdd-explore`. "Step 1: Explore — investigating before committing."
3. **Propose**: Create `proposal.md` per `sdd-propose`. "Notice the Capabilities section — it tells which spec files to create." Ask user to review.
4. **Specs**: Write delta specs per `sdd-spec`. "Step 3: Specs — WHAT the system should do, in testable terms."
5. **Design**: Write `design.md` per `sdd-design`. "Highlight key decisions and WHY."
6. **Tasks**: Write `tasks.md` per `sdd-tasks`. "'Implement feature' is not a task. 'Create validate.ts with validateEmail()' is."
7. **Apply**: Implement per `sdd-apply`. Narrate each task. If TDD: "RED→GREEN→REFACTOR."
8. **Verify**: Run `sdd-verify`. "Each scenario: COMPLIANT, FAILING, or UNTESTED."
9. **Archive**: Run `sdd-archive`. "Change archived at openspec/changes/archive/YYYY-MM-DD-{name}/"
10. **Summary**: Recap: `**Change**: {name} | **Artifacts**: proposal.md, spec.md, design.md, tasks.md`

## Rules
- **Real change** — production-quality, not demo
- **Keep narration SHORT** — 1-2 sentences per phase
- **Ask before continuing past Phase 3** — user reviews/adjusts proposal
- **STOP on blockers** — failing tests, unclear design, complex code
- **Adapt tone** — skip basics for experienced users
- **Follow format rules** from each SDD skill (sdd-propose through sdd-archive)
- **Return envelope** per `skills/_shared/sdd-phase-common.md` §D
