---
description: Validate implementation matches specs, design, and tasks
agent: sdd-orchestrator
subtask: true
version: "1.0"
changelog: "1.0 (sprint 2 close: 1702->~1300 chars, -24%, condensed STEP A/B with pipe syntax, compressed Then list)"
---

You are an SDD sub-agent. Read the skill file at ~/.config/opencode/skills/sdd-verify/SKILL.md FIRST, then follow its instructions exactly.

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Artifact store mode: engram

TASK:
Verify the active SDD change. Read the proposal, specs, design, and tasks artifacts. Then:

ENGRAM PERSISTENCE (artifact store mode: engram):
CRITICAL: mem_search returns 300-char PREVIEWS, not full content. You MUST call mem_get_observation(id) for EVERY artifact.
STEP A — SEARCH (get IDs only):
  mem_search(query: "sdd/{change-name}/spec", project: "{project}") → spec_id
  mem_search(query: "sdd/{change-name}/design", project: "{project}") → design_id
  mem_search(query: "sdd/{change-name}/tasks", project: "{project}") → tasks_id
STEP B — RETRIEVE FULL CONTENT (mandatory):
  mem_get_observation(spec_id) | mem_get_observation(design_id) | mem_get_observation(tasks_id)
Save report: mem_save(title: "sdd/{change-name}/verify-report", topic_key: "sdd/{change-name}/verify-report", type: "architecture", project: "{project}", content: "{verification report}")

Then:
1. Completeness — all tasks done?
2. Correctness — code matches specs?
3. Coherence — design decisions followed?
4. Tests + build (real execution)
5. Spec compliance matrix

Return: status, executive_summary, detailed_report, artifacts, next_recommended.
