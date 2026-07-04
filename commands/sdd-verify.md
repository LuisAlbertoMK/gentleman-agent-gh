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

ENGRAM PERSISTENCE (see [\_shared/engram-convention.md](../.agents/skills/_shared/engram-convention.md) for full protocol):
- Batch search: spec + design + tasks
- Retrieve all (preview rule: mem_get_observation mandatory)
- Save report: mem_save(title: "sdd/{change-name}/verify-report", ...)

Then:
1. Completeness — all tasks done?
2. Correctness — code matches specs?
3. Coherence — design decisions followed?
4. Tests + build (real execution)
5. Spec compliance matrix

Return: status, executive_summary, detailed_report, artifacts, next_recommended.
