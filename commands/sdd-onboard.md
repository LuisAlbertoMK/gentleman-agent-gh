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

ENGRAM PERSISTENCE: See [\_shared/engram-convention.md](../.agents/skills/_shared/engram-convention.md) for full protocol.

Return: status, executive_summary, artifacts, next_recommended.
