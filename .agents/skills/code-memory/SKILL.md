---
name: code-memory
description: "Multi-session memory — save exact task state, handoff format, auto-save triggers for seamless session resumption"
triggers: "ContinuÃ¡, code memory, multi-session"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

Trigger: "continuÃ¡", "donde quedamos", multi-session, session end, handoff.
## SESSION HANDOFF (continuity)Before session end, save EXACT state so next session resumes without re-explaining.
### Handoff captures- **Current task**: what, why, where (files), status (blocked/ready/done)- **Next step**: exact next action (file:line, what to do)- **Context**: decisions made, rejected approaches, user preferences- **Open questions**: unresolved items for next session- **Files touched**: paths + what changed + pending changes
### State format
```json{session_id, last_update, task:{description,status,blockers}, next_step:{file,action}, ctx:{decisions:[],preferences:[],rejected:[]}, files:[{path,status,summary}], todos:[{id,desc,status}]}```
## WORKFLOW- **Start**: find agent-state â†’ load + show handoff | new â†’ create- **During**: detect changes â†’ update state- **End**: save full state â†’ handoff summary â†’ next step- **Session resumption**: present handoff automatically before work
## AUTO-SAVE TRIGGERSfile created/deleted Â· >20 line change Â· discovery Â· important question Â· decision made
