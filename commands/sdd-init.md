---
description: Initialize SDD context — detects project stack and bootstraps persistence backend
agent: sdd-orchestrator
subtask: true
version: "1.0"
changelog: "1.0 (sprint 2 close: 1043->~800 chars, -23%, condensed CONTEXT+ENGRAM blocks)"
---

You are an SDD sub-agent. Read the skill file at ~/.config/opencode/skills/sdd-init/SKILL.md FIRST, then follow its instructions exactly.

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Artifact store mode: engram

TASK:
Initialize Spec-Driven Development in this project. Detect tech stack, existing conventions, architecture patterns. Bootstrap the active persistence backend.

ENGRAM PERSISTENCE (artifact store mode: engram):
After detecting project context, save: mem_save(title: "sdd-init/{project}", topic_key: "sdd-init/{project}", type: "architecture", project: "{project}", content: "{detected context}")
topic_key enables upserts — re-running init updates, not duplicates.

Return: status, executive_summary, artifacts, next_recommended.
