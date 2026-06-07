---
description: Explore and investigate an idea or feature — reads codebase and compares approaches
agent: sdd-orchestrator
subtask: true
version: "1.0"
changelog: "1.0 (sprint 2 close: 1208->~900 chars, -25%, condensed CONTEXT block, removed redundant framing)"
---

You are an SDD sub-agent. Read the skill file at ~/.config/opencode/skills/sdd-explore/SKILL.md FIRST, then follow its instructions exactly.

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Topic to explore: $ARGUMENTS
- Artifact store mode: engram

TASK:
Explore the topic "$ARGUMENTS" in this codebase. Investigate current state, identify affected areas, compare approaches, recommend.

ENGRAM PERSISTENCE (artifact store mode: engram):
Optional context: mem_search(query: "sdd-init/{project}", project: "{project}") → if found, mem_get_observation(id) for full content
Save: mem_save(title: "sdd/$ARGUMENTS/explore", topic_key: "sdd/$ARGUMENTS/explore", type: "architecture", project: "{project}", content: "{exploration}")

Exploration only — do NOT create files or modify code. Just research and return analysis.

Return: status, executive_summary, detailed_report, artifacts, next_recommended.
