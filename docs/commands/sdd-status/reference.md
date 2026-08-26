# sdd-status — Detailed Reference

## Dispatch Logic

If the `gentle-ai` binary is available, run `gentle-ai sdd-status [change] --cwd <repo> --json --instructions` and treat its JSON as authoritative — but only when the session artifact store is `openspec` or `hybrid`.

When the session artifact store is `engram`, do NOT invoke the native dispatcher at all — it cannot see the change (it reads only `openspec/changes/`); resolve status entirely from Engram (`mem_search` + `mem_get_observation` on the change's topic keys) using the manual status schema in `~/.config/opencode/skills/_shared/sdd-status-contract.md` (the same schema used when the binary is unavailable).

The dispatcher is authoritative only for `openspec`/`hybrid`. If unavailable, read the installed shared status contract from this agent's skills directory and follow it.

Adapter-specific status contract paths:

- `~/.config/opencode/skills/_shared/sdd-status-contract.md` for OpenCode
- `~/.config/kilo/skills/_shared/sdd-status-contract.md` for Kilo Code
- `~/.qwen/skills/_shared/sdd-status-contract.md` for Qwen
- Or the equivalent configured skills directory for the current adapter

Do not use a workspace-relative `skills/_shared/...` path.

## Status Fields

Return structured status with:

- Active change selection and schemaName
- planningHome, changeRoot, artifactPaths, and contextFiles
- Artifact statuses for proposal, specs, design, tasks, apply-progress, and verify-report
- Task progress: total, completed, pending, and allComplete
- Dependency states for proposal, specs, design, tasks, apply, verify, and archive
- Next recommended action
- actionContext mode, workspace root, and allowed edit roots

## Routing Rules

- Do not infer routing from free text. Use `nextRecommended` and dependency states.
- If `blockedReasons` is non-empty → do not proceed to apply, archive, or terminal work.
- If `nextRecommended` is `verify` → verification/remediation may run only to refresh evidence.
- If `nextRecommended` is `resolve-blockers` → report `blockedReasons` and stop.
- If `nextRecommended` is a planning token (`propose`, `spec`, `design`, or `tasks`) → launch the corresponding planning phase.
- If status cannot be resolved safely → return `status: blocked` with the missing information.
