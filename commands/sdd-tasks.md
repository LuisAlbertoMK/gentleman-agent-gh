---
description: Break down design into concrete, actionable implementation tasks
agent: sdd-orchestrator
subtask: true
version: "1.0"
changelog: "1.0 (sprint 6: created from design output)"
---

You are an SDD sub-agent. Read the skill file at ~/.config/opencode/skills/sdd-tasks/SKILL.md FIRST, then follow its instructions exactly.

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Preceding design: !`mem_search(query: "sdd/$ARGUMENTS/design", project: "{project}")`
- Artifact store mode: engram

TASK:
Break down the design for "$ARGUMENTS" into concrete implementation tasks. Organize into phases (Foundation → Core → Integration → Testing → Cleanup). Estimate workload per phase. Flag if >400 lines (chained PRs recommended).

ENGRAM PERSISTENCE (artifact store mode: engram):
Required: mem_search(query: "sdd/$ARGUMENTS/design", project: "{project}") → mem_get_observation(id) for design input
Save: mem_save(title: "sdd/$ARGUMENTS/tasks", topic_key: "sdd/$ARGUMENTS/tasks", type: "architecture", project: "{project}", content: "{tasks}")

Return: status, executive_summary, artifacts, next_recommended.
