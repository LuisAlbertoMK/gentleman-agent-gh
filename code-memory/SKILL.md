---
name: code-memory
description: >
  Persist code state between sessions.
  Trigger: "continuá", "donde quedamos", "recordá código", multi-session project state.
license: Apache-2.0
metadata:
  author: mk
  version: "1.0"
---

## When
Continue prior work · Need exact code recovery · Multi-session persistent state · "Dónde quedamos"

## Problem
LLMs have no code memory between sessions. Only short current conversation context.

## Solution: Code State File
`.agent-state.json` in project root:
```json
{
  "session_id": "uuid",
  "last_update": "ISO timestamp",
  "project": { "name": "nombre", "path": "/path", "language": "go|ts|py", "framework": "name" },
  "files": [{
    "path": "src/main.go", "status": "in_progress|completed|blocked",
    "last_edit": "ISO", "content_hash": "sha256", "summary": "what it does",
    "key_sections": { "function_x": "lines 10-25, does Y" }
  }],
  "todos": [{ "id": 1, "description": "implement auth", "status": "completed|pending|blocked", "file": "src/auth.go" }],
  "context": { "current_task": "login endpoint", "next_step": "password validation", "recent_changes": ["handler", "User struct"] }
}
```

## File Structure
```
project/
├── .agent-state.json          # Main state
├── .agent-todos.md            # Task list
├── .agent-context/            # Compiled context
│   ├── index.md               # Project map
│   ├── pending-changes.md     # Unapplied changes
│   └── questions.md           # Pending questions
└── .agent-artifacts/          # Saved snippets
```

## Commands
```bash
agent-state save --file src/main.go --status in_progress   # After significant change
agent-state save --session-end                              # End session
agent-state load [--file src/main.go]                       # Load state
agent-state status [--pending]                              # View state
```

## Workflow
### Start Session
1. Find `.agent-state.json`
2. Exists → load + show summary
3. Not found → create new

### During Session
1. Detect significant code changes
2. Update `.agent-state.json`
3. Completed tasks → update todos

### End Session
1. Save full state
2. List pending questions
3. Summarize next step

## Auto-Save Triggers
File created/deleted · >20 lines modified · Function/task completed · Non-obvious discovery (bug, edge case) · Important user question

## Load Prompt Template
```
## Project State
### Last work: [summary]
### Active files: [file]: [status] - [summary]
### Pending: [ ] task 1 · [ ] task 2
### Next step: [what to do now]
### Pending questions: [ ] question for user
```
