# sdd-continue — Detailed Reference

## Dispatch Logic

If the `gentle-ai` binary is available, run `gentle-ai sdd-continue [change] --cwd <repo>` and treat its dispatcher/status output as authoritative — but only when the session artifact store is `openspec` or `hybrid`.

When the session artifact store is `engram`, do NOT invoke the native dispatcher at all — it cannot see the change (it reads only `openspec/changes/`); resolve status entirely from Engram (`mem_search` + `mem_get_observation` on the change's topic keys) using the manual status schema in `~/.config/opencode/skills/_shared/sdd-status-contract.md` (the same schema used when the binary is unavailable).

The dispatcher is authoritative only for `openspec`/`hybrid`. If unavailable, resolve the active change using the status contract. If `$ARGUMENTS` is missing and more than one active change exists, ask the user to choose and STOP. Do not guess.

## Artifact Check & Dependency Graph

Check which artifacts already exist for the active change (proposal, specs, design, tasks). Determine the next phase based on the dependency graph:

```
proposal → [specs ∥ design] → tasks → apply → verify → archive
```

Launch the appropriate sub-agent(s) for the next phase only if authoritative status says the dependency is ready. Route only by `nextRecommended` and dependency states; never infer from free text.

- If `blockedReasons` is non-empty → do not proceed to apply, archive, or terminal work
- If `nextRecommended` is `verify` → verification/remediation may run only to refresh evidence
- If `nextRecommended` is `resolve-blockers` → report `blockedReasons` and stop
- If `nextRecommended` is a planning token (`propose`, `spec`, `design`, or `tasks`) → launch the corresponding planning phase

Produce or consume structured status before acting: schemaName, planningHome/changeRoot, artifactPaths/contextFiles, task progress, dependency states, next recommended action, blocked reasons, and actionContext.

## Workspace Resolution

- **Working directory**: run `git rev-parse --show-toplevel 2>/dev/null || pwd` with your bash tool and use the returned path as the authoritative workspace. In OpenCode Desktop (Electron) the parse-time interpolation resolves to the app data directory, not the project.
- **Current project**: the `basename` of the detected workspace above.

## Engram Search

To check which artifacts exist in engram/hybrid, search:

```
mem_search(query: "sdd/$ARGUMENTS/", project: "{project}")
```

to list all artifacts for this change. Sub-agents handle persistence automatically using the selected artifact store.

## Status Contract

Prefer `gentle-ai sdd-continue [change] --cwd <repo>` when available — but only when the session artifact store is `openspec` or `hybrid`; when the store is `engram`, do NOT invoke the binary and resolve status from Engram using the manual status schema.

Otherwise read the installed shared status contract from this agent's skills directory and follow it:

- `~/.config/opencode/skills/_shared/sdd-status-contract.md` for OpenCode
- `~/.config/kilo/skills/_shared/sdd-status-contract.md` for Kilo Code
- `~/.qwen/skills/_shared/sdd-status-contract.md` for Qwen
- Or the equivalent configured skills directory for the current adapter

Do not use a workspace-relative `skills/_shared/...` path. Carry `actionContext` and allowed edit roots into any sub-agent launch. If status reports `workspace-planning` with no allowed edit roots, do not launch apply/verify/archive work that would infer repo-local ownership.
