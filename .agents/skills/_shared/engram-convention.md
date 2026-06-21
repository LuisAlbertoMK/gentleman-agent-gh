# Engram Artifact Convention (reference)

NOTE: `mem_search`/`mem_save`/`mem_get_observation` calls are inlined in each SKILL.md. This is supplementary reference.

## Naming
All SDD artifacts: `title: sdd/{change-name}/{artifact-type}` · `topic_key: same` · `type: architecture` · `project: {detected}` · `scope: project`

Types: explore | proposal | spec | design | tasks | apply-progress | verify-report | archive-report | state
Exception: `sdd-init` uses `sdd-init/{project-name}`.

## Recovery (2-step)
```
Step 1: mem_search(query: "sdd/{change-name}/{artifact-type}", project: "{project}") → ID
Step 2: mem_get_observation(id) → full content
```
Group all searches first, then all retrievals. Same for project context: `mem_search("sdd-init/{project}")` → `mem_get_observation`.

## Writing
```
mem_save(title: "sdd/{change-name}/{artifact-type}", topic_key: same, type: "architecture",
         project: "{project}", content: "{full markdown}")
```
Update: `mem_update(id, content)` when ID is known. Same `topic_key` + `project` + `scope` → UPSERT (overwrite, old lost).

## State Artifact (orchestrator recovery after compaction)
```
mem_save(title: "sdd/{change-name}/state", topic_key: same, type: "architecture",
         content: "change: {name}\nphase: {last}\nartifact_store: engram\nartifacts:\n  proposal: bool\n  specs: bool\ntasks_progress:\n  completed: []\n  pending: []\nlast_updated: {date}")
```
Recovery: `mem_search("sdd/{change-name}/state")` → `mem_get_observation`.
