---
name: _shared
description: "Internal shared references for SDD skills. Not an invokable skill."
triggers:
  - sdd shared references
  - internal shared docs
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1500
---

## Purpose

This directory stores shared reference documents consumed by real SDD skills
(for example: `sdd-phase-common.md`, `persistence-contract.md`).

## Not Invokable

`_shared` is a support package only. Do not invoke it as a skill.
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
Cross-Refs: sdd | sdd-init

