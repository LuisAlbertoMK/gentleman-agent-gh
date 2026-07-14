# Rollback Guide

## Automatic Rollback (git revert)
```powershell
git revert <commit-hash> --no-edit
git push
```
Best for: single-commit changes, no data migrations.

## Manual Rollback
```powershell
# 1. Create snapshot before archiving
git diff HEAD > archive/{change}/rollback/snapshot.diff

# 2. Write rollback script
@"
# rollback.sh
git checkout HEAD~1 -- path/to/file.go
git checkout HEAD~1 -- path/to/config.go
# Restore deleted files
git checkout HEAD~1 -- path/to/deleted.go
"@

# 3. Verify no residuals
git status --short
```

## Rollback with Data Migration
1. Reverse migration script: `migrations/rollback_{timestamp}.sql`
2. Execute DB rollback BEFORE code revert
3. Code revert AFTER schema is consistent

## Checkpoints
Always store in: `archive/{change}/rollback/`
- `snapshot.diff` — raw diff
- `rollback.sh` — automated revert
- `rollback.md` — steps (files + migrations + config)
