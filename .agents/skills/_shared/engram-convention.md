# Engram Artifact Convention (canonical reference)

## ⚠️ Critical Rule
`mem_search` returns 300-char PREVIEWS only. You MUST call `mem_get_observation(id)` for EVERY artifact you intend to use.

## Batch Search/Retrieve Pattern
```
STEP A — SEARCH (get IDs only, group ALL first):
  mem_search(query: "sdd/{change-name}/spec", project: "{project}")     → spec_id
  mem_search(query: "sdd/{change-name}/design", project: "{project}")   → design_id
  mem_search(query: "sdd/{change-name}/tasks", project: "{project}")    → tasks_id

STEP B — RETRIEVE (mandatory — 300-char preview rule):
  mem_get_observation(spec_id) | mem_get_observation(design_id) | mem_get_observation(tasks_id)
```

## Naming Convention
All SDD artifacts:
`title: "sdd/{change-name}/{artifact-type}"` · `topic_key: same` · `type: "architecture"` · `project: "{project}"` · `scope: "project"`

| Artifact | Topic Key | Used By |
|----------|-----------|---------|
| Project context | `sdd-init/{project}` | Orchestrator |
| Exploration | `sdd/{change-name}/explore` | propose |
| Proposal | `sdd/{change-name}/proposal` | spec |
| Spec | `sdd/{change-name}/spec` | design, apply, verify |
| Design | `sdd/{change-name}/design` | tasks, apply, verify |
| Tasks | `sdd/{change-name}/tasks` | apply, verify, archive |
| Apply progress | `sdd/{change-name}/apply-progress` | apply (optional continuation) |
| Verify report | `sdd/{change-name}/verify-report` | archive |
| Archive report | `sdd/{change-name}/archive-report` | archive |
| State | `sdd/{change-name}/state` | orchestrator recovery |

## Save Pattern
```
mem_save(title: "sdd/{change-name}/{type}", topic_key: "sdd/{change-name}/{type}",
         type: "architecture", project: "{project}",
         content: "{full markdown}")
```

## Updates
- Known ID: `mem_update(id: <id>, content: "{new content}")`
- Same topic_key + project + scope → UPSERT (overwrites, old lost)
- Apply progress: save new, DO NOT overwrite — merge old + new progress

## Apply-Specific
```
Update tasks as completed: mem_update(id: tasks_id, content: "{[x] done, [ ] pending}")
Save progress: mem_save(title: "sdd/{change-name}/apply-progress", ...)
Continuation: mem_search("sdd/{change-name}/apply-progress") → mem_get_observation → merge
```

## Orchestrator-Specific
```
Skill registry:  mem_search("skill-registry") → mem_get_observation()
Project context: mem_search("sdd-init/{project}") → mem_get_observation()
TDD mode check:  mem_search("sdd-init/{project}") → if strict_tdd: true, inject TDD rules
Apply continue:  mem_search("sdd/{change-name}/apply-progress") → merge on continuation
```

## State Artifact (orchestrator recovery after compaction)
```
mem_save(title: "sdd/{change-name}/state", topic_key: same, type: "architecture",
         content: "change: {name}\nphase: {last}\nartifact_store: engram\n...")
Recovery: mem_search("sdd/{change-name}/state") → mem_get_observation.
```

> 💡 Commands that reference this file: `sdd-apply`, `sdd-verify`, `sdd-archive`, `sdd-orchestrator`.
