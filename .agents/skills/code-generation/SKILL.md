---
name: code-generation
description: "Trigger: new file, function, code generation, script, boilerplate, scaffold. Write code matching codebase patterns."
triggers: "new file, new function, code generation, script, boilerplate, scaffold, create code, write code"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
New files, new functions, scripts, boilerplate. NOT for debugging (→ deep-debugging) or single-line fixes on existing files (→ quick-executor).

## WORKFLOW
1. **CONTEXT**: Read target dir → identify 2-3 relevant files by: (a) files imported by target path, (b) files in same module, (c) similar naming. Read each. Match patterns (imports, naming, error handling, types).
2. **GENERATE**: Match codebase conventions. **Quality floor**: if neighbors use anti-patterns (raw SQL, no error handling, global state), flag to user: "Neighboring code uses X (anti-pattern). Suggesting Y instead." Match conventions, but don't propagate bad patterns silently.
3. **VALIDATE**: Syntax check. Run lint/typecheck if exists.
4. **EDGE CASES**: For each public function: null/empty, error states, boundary values. Domain-specific: data layer (connection failures, timeouts), API (auth, rate limiting, malformed input), UI (empty states, loading), CLI (invalid flags, help text).

## FILE CREATION
(1) Read parent dir to confirm structure. (2) Write file. (3) Verify syntax.

## STANDARDS
- Match import style, naming, error handling, type system
- Every function: input validation + error handling + one clear purpose
- No new deps unless codebase already uses them
- Tests → detect framework → write matching patterns

## DISAMBIGUATION
If request matches quick-executor scope (single existing file, clear before/after, <20 lines) → defer to quick-executor.

## SEVERITY
| P0 | Generated code breaks build | P1 | Convention mismatch | P2 | Missing edge case | P3 | Style nits |

## OUTPUT
```
Created/modified [file]. Pattern matched from [source]. Ready for review.
```

## Rules
1. Read before write. Never generate without seeing patterns. 2. Existing files → patch-first. New files → full write. 3. New dependency → STOP, report [name]+[why]+[alternative].

## Refs
quick-executor · commit-crafter · quality-gate

## Anti-Patterns
Generate without reading existing code · Add unnecessary deps · Skip edge cases · Ignore codebase conventions · Silently propagate anti-patterns
