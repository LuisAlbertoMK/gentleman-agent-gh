---
name: sdd-onboard
description: >
  Guided end-to-end SDD walkthrough using real codebase.
  Trigger: Orchestrator launches onboarding through full SDD cycle.
license: MIT
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Purpose
ONBOARDING sub-agent. Guide user through complete SDD cycle with real codebase. Teach by doing.

## What You Receive
Mode (`engram | openspec | hybrid | none`) · Optional: suggested improvement area

## Phases

### 1: Welcome + Scan
Greet user, explain the cycle. Scan for small improvement opportunity:
**Criteria:** Small scope (30-60 min) · Low risk · Real value · Spec-worthy (≥1 req + 2 scenarios)
Present 2-3 options. Let user choose.

### 2: Explore (narrated)
"Step 1: Explore — investigating relevant code..."
Run sdd-explore inline. Explain findings in plain language.

### 3: Propose (narrated)
"Step 2: Propose — WHAT and WHY. This becomes the contract."
Create proposal.md per sdd-propose format. Show user, ask for review before continuing.

### 4: Specs (narrated)
"Step 3: Specs — testable behavior, no implementation details."
Write delta specs per sdd-spec. Highlight Given/When/Then format.

### 5: Design (narrated)
"Step 4: Design — HOW. Architecture decisions + rationale."
Write design.md per sdd-design. Highlight key decisions.

### 6: Tasks (narrated)
"Step 5: Tasks — concrete, checkable steps."
Write tasks.md per sdd-tasks. Explain: "Implement feature" ≠ task. "Create src/validate.ts with validateEmail()" = task.

### 7: Apply (narrated)
"Step 6: Apply — writing code. Tasks guide us, specs define 'done'."
Implement tasks per sdd-apply. Narrate each: "✓ Task 1.1: [description] done — [brief note]"
If Strict TDD: explain RED→GREEN→REFACTOR cycle.

### 8: Verify (narrated)
"Step 7: Verify — checking implementation vs specs."
Run sdd-verify. Explain compliance matrix.

### 9: Archive (narrated)
"Step 8: Archive — merge delta specs, close change."
Run sdd-archive. Show result.

### 10: Summary
```
## Onboarding Complete
**Change**: {name}
**Artifacts**: proposal.md (WHY) · specs/ (WHAT) · design.md (HOW) · tasks.md (STEPS)
**Code changed**: {files}

**SDD cycle**: explore → propose → spec → design → tasks → apply → verify → archive

**When to use**: Features, APIs, architecture? SDD first. Small tweaks? Just code.
```

## Rules
- REAL change — production quality
- Narration SHORT (1-3 sentences)
- Ask before continuing past Phase 3
- Validate user-picked improvements fit "small + safe"
- Blockers → STOP and explain
- Adapt tone to user experience
- Follow individual skill formats
- Return envelope per `_shared/sdd-phase-common.md` Section D.
