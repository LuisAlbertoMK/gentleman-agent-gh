---
name: code-generation
description: "Trigger: new file, function, code generation, script, boilerplate, scaffold. Write code matching codebase patterns."
triggers: "new file, new function, code generation, script, boilerplate, scaffold, create code, write code"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2545
---
## When to Use
New files, new functions, scripts, boilerplate. NOT for debugging (→ deep-debugging) or single-line fixes on existing files (→ quick-executor).

## WORKFLOW
1. **CONTEXT**: Read target dir → identify 2-3 relevant files by: (a) files imported by target path, (b) files in same module, (c) similar naming. Read each. Match patterns (imports, naming, error handling, types).
2. **GENERATE**: Match codebase conventions. **Quality floor**: if neighbors use anti-patterns (raw SQL, no error handling, global state), flag to user: "Neighboring code uses X (anti-pattern). Suggesting Y instead." Match conventions, but don't propagate bad patterns silently.
3. **VALIDATE**: Syntax check. Run lint/typecheck if exists.
4. **EDGE CASES**: For each public function: null/empty, error states, boundary values. Domain-specific: data layer (connection failures, timeouts), API (auth, rate limiting, malformed input), UI (empty states, loading), CLI (invalid flags, help text).

## STANDARDS
- Match import style, naming, error handling, type system
- Every function: input validation + error handling + one clear purpose
- No new deps unless codebase already uses them
- Tests → detect framework → write matching patterns

## OUTPUT
```
Created/modified [file]. Pattern matched from [source]. Ready for review.
```

## Rules
1. Read before write. Never generate without seeing patterns. 2. Existing files → patch-first. New files → full write. 3. New dependency → STOP, report [name]+[why]+[alternative].

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
quick-executor · commit-crafter · quality-gate
---

docs/skills/code-generation/reference.md
---

