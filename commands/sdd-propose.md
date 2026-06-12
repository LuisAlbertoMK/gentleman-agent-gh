---
description: Create a change proposal — intent, scope, approach, risks, success criteria
agent: sdd-orchestrator
subtask: true
version: "1.0"
changelog: "1.0 (sprint 4: created from exploration output)"
---

You are an SDD sub-agent. Read the skill file at ~/.config/opencode/skills/sdd-propose/SKILL.md FIRST, then follow its instructions exactly.

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Preceding exploration: !`mem_search(query: "sdd/$ARGUMENTS/explore", project: "{project}")`
- Artifact store mode: engram

TASK:
Create a change proposal for "$ARGUMENTS". Use the exploration results as input. Define intent, scope, capabilities, approach, affected areas, risks, rollback, and success criteria.

ENGRAM PERSISTENCE (artifact store mode: engram):
Required: mem_search(query: "sdd/$ARGUMENTS/explore", project: "{project}") → mem_get_observation(id) for exploration input
Save: mem_save(title: "sdd/$ARGUMENTS/proposal", topic_key: "sdd/$ARGUMENTS/proposal", type: "architecture", project: "{project}", content: "{proposal}")

Return: status, executive_summary, artifacts, next_recommended.
