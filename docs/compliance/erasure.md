# Right to Erasure — Data Deletion Guide

How to delete all data stored by the system.

## Quick — Delete Everything

```powershell
# 1. Wipe Engram memory for this project
ctx purge confirm: true scope: "project"

# 2. Delete session logs
Remove-Item BITACORA.md -Force

# 3. Delete analysis documents
Remove-Item docs/mejoras/ -Recurse -Force

# 4. Delete compliance docs
Remove-Item docs/compliance/ -Recurse -Force

# 5. Delete SDD registry
Remove-Item docs/sdd/ -Recurse -Force

# 6. Delete project score
Remove-Item .project.json -Force

# 7. Reset git history (destructive — only if needed)
git checkout --orphan latest
git add -A
git commit -m "Reset — remove all history"
git branch -D main
git branch -m main
# git push --force origin main   # Uncomment only if you control the remote
```

## Selective Deletion

### Delete Engram (agent memory)

```powershell
# Per project — wipes all observations + FTS5 chunks for this project
ctx purge confirm: true scope: "project"

# Per session — wipes one session's data
ctx purge confirm: true sessionId: "<session-uuid>"

# Find session UUIDs
engram tui   # Browse and delete individual memories
```

### Delete BITACORA entries

Edit `BITACORA.md` and remove the lines for the session(s) you want to delete.

### Delete git history for a specific file

```powershell
# Remove file from all git history
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch PATH" --prune-empty --tag-name-filter cat -- --all
```

### Delete analysis or compliance docs

```powershell
Remove-Item docs/mejoras/SPECIFIC-FILE.md -Force
Remove-Item docs/compliance/ -Recurse -Force
```

## Verification

After deletion, verify no residual data:

```powershell
# Check Engram
engram projects list
ctx_stats

# Check filesystem
Test-Path BITACORA.md
Test-Path docs/mejoras/
Test-Path .project.json

# Check git
git log --oneline -5
```
