---
name: skills-link
description: Mirror/copy of skills for portability and cross-machine sync. Not an invokable skill.
triggers: []
cross-refs:
anti-patterns:
---

# skills-link

Internal mirror of skills for portability and cross-machine synchronization.

**This is NOT an invokable skill.** It exists as a structural copy to ensure skill availability across environments.

## Purpose

- Backup of canonical skills for disaster recovery
- Cross-machine sync target
- Reference copy for drift detection

## Notes

- Contents mirror `.agents/skills/*` (excluding this directory)
- Updated via `sync-vmk.ps1` or manual copy
- Do not edit directly — edit the canonical skill in `.agents/skills/<skill-name>/`
