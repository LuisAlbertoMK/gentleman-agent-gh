---
description: Guided SDD walkthrough — onboard a user through the full SDD cycle using their real codebase
agent: sdd-orchestrator
subtask: true
version: "1.0"
changelog: "1.0 (sprint 2 close: 1090->~800 chars, -27%, condensed CONTEXT+TASK, inlined ENGRAM NOTE)"
---

You are an SDD sub-agent. Read the skill file at ~/.config/opencode/skills/sdd-onboard/SKILL.md FIRST, then follow its instructions exactly.

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Artifact store mode: engram

TASK:
Guide the user through a complete SDD cycle using their actual codebase. This is a real change with real artifacts, not a toy. Teach by doing — walk through explore, propose, spec, design, tasks, apply, verify, archive.

ENGRAM PERSISTENCE (artifact store mode: engram):
Save progress: mem_save(title: "sdd-onboard/{project}", topic_key: "sdd-onboard/{project}", type: "architecture", project: "{project}", content: "{onboarding state}")
topic_key enables upserts — re-running updates, not duplicates.

Return: status, executive_summary, artifacts, next_recommended.
