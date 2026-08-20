# session-resume — Reference Materials

> **Externalized from** .agents/skills/session-resume/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains recall, pre-load, save-state, and test detail.

## Proactive Recall
1. `mem_search(query="<last session>", limit=5)` — past work
2. User msg keywords → `mem_search(query="<keywords>", type="bugfix|pattern|decision", limit=3)` → inject top 3
3. Present relevant decisions/bugfixes
4. `mem_search(query="project/{name}", scope=project, limit=1)`
5. Missing → trigger Project fingerprint (dreaming)

**Pre-answer search**: `engram-protocol` for proactive search; `gentleman-vMK.md` = Pre-Answer Evidence Gate.

## Skill Pre-load
```powershell
.\scripts\skill-graph.ps1 -Task "<session keywords>" -Format Text
```
Typical: 55→4-8 (−85-92%).

## Commands
`git status --porcelain` · `git log @{u}.. --oneline 2>/dev/null` · `git branch --show-current; git log -1 --oneline`

## Save State
### Handoff
Current task (what/why/where/status) · Next step (file:line, what) · Context (decisions, rejected, preferences) · Open questions · Files touched (paths + changes + pending).

### State format
JSON: `{session_id, task:{description,status,blockers}, next_step:{file,action}, ctx:{decisions:[],preferences:[],rejected:[]}, files:[{path,status,summary}], todos:[{id,desc,status}]}`

### Workflow
Start→load handoff|create. During→detect→update. End→save+handoff+next step.

### Auto-save triggers
file created/deleted · >20 line change · discovery · important question · decision

## Cross-Project Wisdom
1. Check `docs/cross-project/patterns/` exists. 2. Load matching patterns via `cross-project-wisdom`. 3. Present max 3 HIGH/CRITICAL advisory patterns.

## Examples
"dónde lo dejamos?" → `git status --porcelain` clean → no WARN; `git log @{u}..` empty → nothing unpushed; `mem_search("last session")` → top 3 injected → silent resume, 0 questions.

## Testing
1. Dirty drill: 1 touched file → WARN + ask (commit/stash/continue), max 4 options. 2. Clean drill: empty status → silent, 0 questions. 3. Pre-load: `skill-graph.ps1` → ≤8 lines.