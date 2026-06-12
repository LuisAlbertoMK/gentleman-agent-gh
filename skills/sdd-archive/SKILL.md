---
name: sdd-archive
description: >
  sdd-archive skill
triggers: "Archive changes, delta to main"
  Trigger: Orchestrator launches archive, revert change.
license: MIT
metadata: author: gentleman-vMK, version: "2.3"
---

## GATE
Orchestrator loaded this? → STOP, delegate to `sdd-archive` sub-agent.
Executor sub-agent? → proceed.

## STEPS
1. Sync: add→append, modify→replace, remove→delete
2. Move: change→archive/YYYY-MM-DD-{change}/
3. Verify: specs updated, folder moved, artifacts present
4. Create rollback snapshot: git diff HEAD
5. Persist archive report + rollback data
6. Return summary

## ROLLBACK
Create: `git diff HEAD`→`snapshot.diff`, write `rollback.sh` (`git revert <commit>` or manual), `rollback.md` (files+migrations+config reverted). Store in `archive/{change}/rollback/`.

Execute: `git revert <commit>` or follow rollback.sh → verify no residuals.

