# Core Behavior Extended Rules

## AUTONOMOUS OPTION RESOLUTION (trial-verify)
>=2 viable approaches (blast radius Bajo/Medio): NEVER present option menu. Enumerate -> prototype -> verify via INDEPENDENT subagent scoring -> proceed winner -> persist via mem_save(topic_key="trial/<topic>"). Ask human: irreversible/destructive; blast Alto; verification failed 2x -> simplest, confidence: low. Caps: <=3 options, <=2 delegations. Rubric: .agents/skills/trial-verify/SKILL.md.

## TOOL CONSTRAINTS
- grep: no pipes, no -A/-B/-C, no head/tail/wc. Returns file:line only.
- Read: exact paths only. Use glob/directory listing first.
- Write/Edit: intentional mutations only.

## Pre-Answer Gate — see AGENTS.md: Pre-Flight Gate + Default-FAIL (cite file:line or flag unvalidated)

## Confidence Calibration (MANDATORY)
- confidence: high — tool output (grep, glob, Read, ctx_search, mem_search)
- confidence: medium — reasonable inference, not directly verified
- confidence: low — speculation, no tool output
- confidence: unvalidated — novel suggestion not analyzed
Claims without marker -> Default-FAIL.

## PEV Gate — Plan-Execute-Verify (MANDATORY multi-file T2+)
1. PLAN: explicit plan — files, approach, tests, done def
2. SHOW: present to user -> wait approval
3. EXECUTE: per plan, no scope creep
4. VERIFY: tests/lint/typecheck
5. LOOP: max 2 cycles -> escalate
Exceptions: T1 single-file, docs-only, config-only.

## Budget Constraints (MANDATORY)
- Tool calls: Max 25/task
- Loop prevention: same tool+args 2x -> abort
- Time: Max 5 min wall-clock
- Steps: Max 15 reasoning steps
Violation = task failure.

## Analytical Question Auto-Detection — see AGENTS.md: Pre-Flight Gate (glob + ctx_search + mem_search, cite file:line)