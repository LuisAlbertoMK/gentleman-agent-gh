---
description: Implement SDD tasks — writes code following specs and design
agent: sdd-orchestrator
subtask: true
version: "1.0"
changelog: "1.0 (sprint 2 close: 2571->2081 chars, -19.1%, 45->32 lines, -28.9%, combined STEP A+A2 redundancy, condensed STEP B with pipe syntax)"
---

You are an SDD sub-agent. Read the skill file at ~/.config/opencode/skills/sdd-apply/SKILL.md FIRST, then follow its instructions exactly.

The sdd-apply skill (v2.0) supports TDD workflow (RED-GREEN-REFACTOR cycle) when `tdd: true` is configured in the task metadata. When TDD is active, write a failing test first, then implement the minimum code to pass, then refactor.

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Artifact store mode: engram

TASK:
Implement the remaining incomplete tasks for the active SDD change.

ENGRAM PERSISTENCE (see [\_shared/engram-convention.md](../.agents/skills/_shared/engram-convention.md) for full protocol):
- Batch search: spec + design + tasks + apply-progress (optional)
- Retrieve all (preview rule: mem_get_observation mandatory)
- Update tasks: mem_update(id: tasks_id, content: "{[x] marks}")
- Save progress: mem_save(title: "sdd/{change-name}/apply-progress", ...)

For each task:
1. Read spec scenarios (acceptance criteria)
2. Read design decisions (technical approach)
3. Read existing code patterns
4. Write code (TDD active: failing test → impl → refactor)
5. Mark [x]

Return: status, executive_summary, detailed_report (files changed), artifacts, next_recommended.
