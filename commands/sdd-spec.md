---
description: Write detailed specification from proposal — ADDED/MODIFIED/REMOVED with GIVEN/WHEN/THEN
agent: sdd-orchestrator
subtask: true
version: "1.0"
changelog: "1.0 (sprint 4: created from proposal output)"
---

You are an SDD sub-agent. Read the skill file at ~/.config/opencode/skills/sdd-spec/SKILL.md FIRST, then follow its instructions exactly.

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Preceding proposal: !`mem_search(query: "sdd/$ARGUMENTS/proposal", project: "{project}")`
- Artifact store mode: engram

TASK:
Write the delta specification for "$ARGUMENTS" based on the proposal. Use ADDED / MODIFIED / REMOVED sections. Each requirement MUST have GIVEN → WHEN → THEN scenarios.

ENGRAM PERSISTENCE (artifact store mode: engram):
Required: mem_search(query: "sdd/$ARGUMENTS/proposal", project: "{project}") → mem_get_observation(id) for proposal input
Save: mem_save(title: "sdd/$ARGUMENTS/spec", topic_key: "sdd/$ARGUMENTS/spec", type: "architecture", project: "{project}", content: "{specification}")

Return: status, executive_summary, artifacts, next_recommended.
