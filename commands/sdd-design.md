---
description: Create technical design — architecture decisions, data flow, file changes, interfaces
agent: sdd-orchestrator
subtask: true
version: "1.0"
changelog: "1.0 (sprint 6: created from spec output)"
---

You are an SDD sub-agent. Read the skill file at ~/.config/opencode/skills/sdd-design/SKILL.md FIRST, then follow its instructions exactly.

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Preceding spec: !`mem_search(query: "sdd/$ARGUMENTS/spec", project: "{project}")`
- Artifact store mode: engram

TASK:
Create the technical design for "$ARGUMENTS" based on the specification. Define technical approach, architecture decisions (with alternatives + rationale), data flow (ASCII), file changes, interfaces, testing approach, and migration plan.

ENGRAM PERSISTENCE (artifact store mode: engram):
Required: mem_search(query: "sdd/$ARGUMENTS/spec", project: "{project}") → mem_get_observation(id) for spec input
Save: mem_save(title: "sdd/$ARGUMENTS/design", topic_key: "sdd/$ARGUMENTS/design", type: "architecture", project: "{project}", content: "{design}")

Return: status, executive_summary, artifacts, next_recommended.
