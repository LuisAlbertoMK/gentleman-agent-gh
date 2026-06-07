---
description: Archive a completed SDD change — syncs specs and closes the cycle
agent: sdd-orchestrator
subtask: true
version: "1.0"
changelog: "1.0 (sprint 2 close: 2004->~1500 chars, -25%, combined STEP A search calls, condensed STEP B with pipe syntax)"
---

You are an SDD sub-agent. Read the skill file at ~/.config/opencode/skills/sdd-archive/SKILL.md FIRST, then follow its instructions exactly.

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Artifact store mode: engram

TASK:
Archive the active SDD change. Read the verification report first to confirm the change is ready. Then:

ENGRAM PERSISTENCE (artifact store mode: engram):
CRITICAL: mem_search returns 300-char PREVIEWS, not full content. You MUST call mem_get_observation(id) for EVERY artifact.
STEP A — SEARCH (get IDs only):
  mem_search(query: "sdd/{change-name}/proposal", project: "{project}") → proposal_id
  mem_search(query: "sdd/{change-name}/spec", project: "{project}") → spec_id
  mem_search(query: "sdd/{change-name}/design", project: "{project}") → design_id
  mem_search(query: "sdd/{change-name}/tasks", project: "{project}") → tasks_id
  mem_search(query: "sdd/{change-name}/verify-report", project: "{project}") → verify_id
STEP B — RETRIEVE FULL CONTENT (mandatory):
  mem_get_observation(proposal_id) | mem_get_observation(spec_id) | mem_get_observation(design_id) | mem_get_observation(tasks_id) | mem_get_observation(verify_id)
Record all observation IDs in the archive report for traceability.
Save: mem_save(title: "sdd/{change-name}/archive-report", topic_key: "sdd/{change-name}/archive-report", type: "architecture", project: "{project}", content: "{archive report with observation IDs}")

Then:
1. Sync delta specs into main specs (source of truth)
2. Move the change folder to archive with date prefix
3. Verify the archive is complete

Return: status, executive_summary, artifacts, next_recommended.
