---
name: quick-executor
description: "Trigger: quick edit, single file, atomic edit, fast fix, one-line fix. Single-file low-risk changes."
triggers: "quick edit, single file, atomic edit, fast fix, one-line fix, small change, quick fix"
---
## When to Use
1 file, clear before/after, low risk. SCOPE GUARD: >1 file → STOP, report to orchestrator or delegate to plan-execution.

## WORKFLOW
1. **READ** target file. Not exists → delegate to code-generation. Never create files directly.
2. **PLAN** minimal edit. Risk check: >20 lines OR >2 functions OR new deps → STOP, over-scoping.
3. **EDIT** in one atomic operation.
4. **VERIFY**: Test exists → run it. Build exists → run it. Language check:
   - Python: `python -c "import ast; ast.parse(open('file').read())"`
   - JS/TS: `node --check file.js` / `npx tsc --noEmit`
   - Go: `go vet ./...`
   - Rust: `cargo check`
   - Java: `javac -d /tmp File.java`
   - Ruby: `ruby -c file.rb`
   - PHP: `php -l file.php`
   - Shell: `bash -n script.sh`
   - Other: Read, verify syntax manually, note in report.
5. **REPORT**: One line.

## FAILURE
- Parse/compile fail → `git checkout -- <file>` (if git), suggest deep-debugging
- Test fail → 1 fix attempt. Still fails → STOP, escalate
- Unclear requirements → STOP, 1 question

## STANDALONE MODE
If invoked directly (not via orchestrator): report issues as findings, do not escalate. Apply fixes if clear.

## SEVERITY
| P0 | Blocks other work | P1 | User-facing bug | P2 | Improvement | P3 | Cleanup |

## OUTPUT
```
Changed [file] (lines N-M). Verified: [pass/fail].
```

## RULES
1. Max 1 file. No exceptions. 2. No rename/extract/refactor adjacent code. 3. No new dependencies. 4. Risk heuristic: size + complexity + deps → if any borderline → STOP.

## Refs
code-generation · commit-crafter · deep-debugging

## Anti-Patterns
Multi-file scope creep · Refactor adjacent code · Add dependencies · Skip verification · Create files (delegate to code-generation)
