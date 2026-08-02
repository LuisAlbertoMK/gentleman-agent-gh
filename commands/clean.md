---
description: Leave a repository clean — untracked files, .bak/.tmp junk, dangling junctions, optional git gc
---

You are executing `!clean`. Clean up a repository: temp/backup artifacts, dangling junctions, optionally untracked files and git gc. NEVER touches committed or staged files.

`$ARGUMENTS` = optional repo path (default: current workspace root), plus `-Yes` to apply, `-RemoveUntracked` to also remove untracked files, or `-Gc` for `git gc --prune=now`.

**Safety design**: untracked files are the risky category (may hold WIP/config/secrets). `-Yes` alone removes ONLY junk + dangling junctions. Untracked removal requires the explicit `-RemoveUntracked` opt-in. By default, untracked files are REPORTED but preserved.

Steps:

1. **Resolve root**: `$root = $env:GENTLEMAN_AGENT_ROOT; if (-not $root) { $root = Split-Path $PSScriptRoot -Parent }`. Target repo = `$ARGUMENTS` or current workspace.
2. **Dry-run first (mandatory)**: run `& "$root\scripts\clean-repo.ps1" -RepoRoot <target> -Quiet`. Report junk count, dangling junctions, untracked count.
3. **Sanity check before apply**: confirm the junk list contains no files the user needs. For untracked: if the user explicitly asked for a full clean, review the untracked list first — if anything looks like active work (config, secrets, WIP, docs), list it and STOP — ask first.
4. **Apply**: run `& "$root\scripts\clean-repo.ps1" -RepoRoot <target> -Yes -Quiet` for junk+dangling, or add `-RemoveUntracked` only after the untracked list was explicitly approved. Add `-Gc` only if the user asked or the repo needs it.
5. **Verify**: `git status --porcelain` shows no leftover junk; tracked files intact; untracked only what was explicitly approved.
6. **Report**: what was removed (counts), what was skipped and why, final `git status` summary.

Do NOT run git clean/gc directly — always go through the script so the dry-run gate holds. If the repo has staged or WIP changes, report them instead of removing anything.
