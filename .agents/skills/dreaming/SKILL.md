---
name: dreaming
description: Cross-session pattern extraction via Engram. Curate memory, update skills.
license: Apache-2.0
metadata: version: "1.2"
triggers: session start/end, ~5 tool calls, "dream/patrones/memory review"
---

## Protocol (5 modes — same pattern: scan→cluster→act)

| Mode | When | Action |
|------|------|--------|
| **Quick scan** | Session start | MANDATORY before any work. `mem_context` + `mem_search(keywords=user first msg)` + `mem_search(error|bug)` + scan anti-patterns. Past failure like current?→prevent. |
| **Project fingerprint** | First interaction | Save project fingerprint: `mem_save(type="architecture", title="project:{name}", topic_key="project/{name}", content="**Tech**:{lang/framework/db}**Structure**:{dirs}**Patterns**:{arch}**Tests**:{count}**Gaps**:{known issues}")` |
| **Harvest** | Session end | `mem_session_summary` + extract patterns (error→catalog, workflow→skill, arch→mem_save). Same error 2+ sessions→AGENTS.md. |
| **Mini-dream** | ~5 tools | Self-check quality/efficiency/reusability. Skill gap→create/update. Error repeated→catalog. |
| **Full dream** | Milestone | `mem_search(type="error|bugfix")` across ALL sessions. ≥2→anti-pattern. ≥3→AGENTS.md rule. Check decision contradictions. Curate stale obs. |

## Proactive Recall (NEW — mandatory)
BEFORE any task execution:
1. Extract 3-5 keywords from user's message
2. `mem_search(query="<keywords>", limit=5)` — check if similar work was done before
3. If found → `mem_get_observation` for details → apply past learnings
4. If no results → proceed fresh, save results for future

## Project Fingerprint (NEW — first interaction per project)
When entering a project for the first time (or after long gap):
1. Detect: lang, framework, test tool, arch pattern, dir layout
2. Save to engram with `topic_key="project/{name}"`
3. On subsequent sessions: `mem_search(query="project/{name}", scope=project, limit=1)` to reload context
4. Update when project structure changes significantly

## Anti-Patterns
❌ Isolated sessions · fix-only-no-document · every session fresh · no memory scan before work · project context lost between sessions
✅ Cross-session patterns · permanent immunity · curate signal/drop noise · scan memory first · project fingerprint persisted
