# Delegation Prompt Template

## Safe Prompt Structure
```
Task: {specific task description}
Context: {Engram IDs for past decisions}
Files: {paths to read, what to look for}
Output: {format expected}
Limits: {boundaries — what NOT to do}
```

## Example: Parallel Exploration
```markdown
Task: Explore auth middleware and report JWT flow
Context: engram-obs-42 (previous auth decision)
Files: src/middleware/auth.go → read entry point + validation
Output: 4 sections (entry points, risks, patterns, recommendation)
Limits: Don't modify files, don't run tests
```

## Anti-patterns
| Anti-pattern | Why | Fix |
|---|---|---|
| Share full history | Wastes tokens, contaminates context | Use Engram IDs |
| Vague task | "Explore the codebase" = useless | "Explore auth middleware JWT flow" |
| Depends on knowledge | "As we discussed..." | Include decision context |
