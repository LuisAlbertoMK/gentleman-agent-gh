---
name: sdd-archive
description: "Archive completed changes — sync specs to main, move artifacts to archive, create rollback snapshots, and persist reports"
triggers: "Archive changes, delta to main"
license: MIT
metadata: author: gentleman-vMK, version: "2.3"
---

Trigger: Orchestrator launches archive, revert change.
## GATEOrchestrator loaded this? â†’ STOP, delegate to `sdd-archive` sub-agent.Executor sub-agent? â†’ proceed.
## STEPS1. Sync: addâ†’append, modifyâ†’replace, removeâ†’delete2. Move: changeâ†’archive/YYYY-MM-DD-{change}/3. Verify: specs updated, folder moved, artifacts present4. Create rollback snapshot: git diff HEAD5. Persist archive report + rollback data6. Return summary
## ROLLBACKCreate: `git diff HEAD`â†’`snapshot.diff`, write `rollback.sh` (`git revert <commit>` or manual), `rollback.md` (files+migrations+config reverted). Store in `archive/{change}/rollback/`.Execute: `git revert <commit>` or follow rollback.sh â†’ verify no residuals.
