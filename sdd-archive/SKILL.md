---
name: sdd-archive
description: > Sync delta→main→archive + rollback.
  Trigger: Orchestrator launches archive, revert change.
license: MIT
metadata: author: gentleman-programming, version: "2.2"
---

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
