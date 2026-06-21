---
name: doc-sync
description: "Sync documentation across repos, branches, and locations — maintain READMEs, changelogs, and docs in multiple places from a single source"
triggers: "doc sync, documentation sync, sync docs, update readme, sync changelog, propagate docs"
license: Apache-2.0
metadata:
  tags: [documentation, workflow]
  author: gentleman-vMK
  version: "1.0"
  changelog: "1.0: created from AGENTS.md Skill Router reference 'Sync docs → doc-sync'"
---
## Purpose
Keep documentation in sync across multiple locations (READMEs across forks, changelogs in multiple repos, docs in different branches) from a single source of truth.

## When to use
- Propagating changes from opencode → opencode-vmk → gentleman-vMK
- Updating README across forks after significant changes
- Syncing changelogs between repos
- Keeping docs consistent across branches during a release

## Sync flow
1. Identify SOURCE (authoritative doc) and TARGETS (locations to update)
2. Read source content
3. For each target: read → diff → apply changes preserving target-specific sections
4. Verify: check for broken cross-refs, outdated version numbers, stale links
5. Commit with message: `docs(sync): {summary}`
