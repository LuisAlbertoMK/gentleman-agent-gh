---
name: sdd-archive
description: > Sync delta → main → archive + rollback support.
  Trigger: Orchestrator launches archive, need to revert change.
license: MIT
metadata: author: gentleman-programming, version: "2.1"
---

## STEPS
1. Sync: add→append, modify→replace, remove→delete
2. Move: change→archive/YYYY-MM-DD-{change}/
3. Verify: specs updated, folder moved, artifacts present
4. Create rollback snapshot: git diff HEAD
5. Persist archive report + rollback data
6. Return summary

## ROLLBACK
Every archived change stores a rollback plan:
```
rollback/{change-name}/
├── rollback.sh       # commands to revert
├── snapshot.diff     # pre-apply state (git diff HEAD)
└── rollback.md       # human-readable: what changed, how to revert
```

### Rollback creation
1. Before archive: capture `git diff HEAD` → `snapshot.diff`
2. Generate `rollback.sh`: `git revert <commit>` or manual undo steps
3. Write `rollback.md`: changed files, data migrations reversed, config reverted
4. Store in `archive/YYYY-MM-DD-{change}/rollback/`

### Rollback execution
```bash
# Option 1 (git revert):
git revert <commit-hash>

# Option 2 (manual):
# Follow rollback.md steps, apply rollback.sh
# Verify no residual changes
```
