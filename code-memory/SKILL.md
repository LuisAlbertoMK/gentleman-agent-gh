---
name: code-memory
description: > Persist code state between sessions (".agent-state.json").
  Trigger: "continuá", "donde quedamos", multi-session state.
license: Apache-2.0
metadata: author: mk, version: "1.0"
---

## WHEN
Continue prior work · Exact code recovery · "Dónde quedamos"

## STATE FILE
```json
{session_id,last_update,project:{name/path/lang/framework},
files:[{path,status,summary,key_sections}],
todos:[{id,description,status}],ctx:{current_task,next_step,recent_changes}}
```

## WORKFLOW
Start: find .agent-state.json → load+show | new→create
During: detect changes→update|sync todos
End: save full state→pending questions→next step

## AUTO-SAVE
file created/deleted · >20 line change · func completed · discovery · important Q