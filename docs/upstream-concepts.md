# Upstream Concepts: gentle-ai Go → PowerShell Translation

> Extracted 2026-06-20 from upstream gentle-ai. Backup + planner packages in Go,
> with PS translation for potential scripts integration.

## 1. Backup Snapshot System (`internal/backup/snapshot.go`)

**Core**: Timestamped backup dir with tar.gz archive + JSON manifest.

| Concept | Go | PS |
|---------|----|----|
| Snapshot dir | `Snapshotter{now func() time.Time}` | `$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"` |
| Manifest | `Manifest{ID, CreatedAt, Entries, Checksum, Pinned}` | `@{$id; created_at; checksum; entries=@(); pinned=$false}` |
| Archive | `snapshot.tar.gz` | `Compress-Archive` (or 7z for cross-session) |
| De-duplication | Composite SHA-256 over sorted file list | `Get-FileHash -Algorithm SHA256` + sort + rehash |

## 2. Retention & Dedup (`internal/backup/retention.go`)

**Core**: Prune old backups, keep N unpinned + all pinned.

- `DefaultRetentionCount = 5`
- Pinned backups survive pruning (mark with `pinned: true` in manifest)
- Composite checksum: SHA-256 each file → sort by path → concat `"path:hex\n"` → final SHA-256
- Empty checksum (0 files) skipped for dedup

## 3. Restore Logic (`internal/backup/restore.go`)

**Core**: Extract manifest, validate paths under home dir, atomic writes.

- Symlink escape guard: `Resolve-Path` on both sides, verify under `$env:USERPROFILE`
- Path validation even for non-existent paths (restore targets)
- Atomic write: write to temp, then rename (prevents partial writes)

## 4. Dependency Graph (`internal/planner/graph.go`)

**Core**: Static DAG of component dependencies with soft ordering constraints.

```text
Engram ← SDD ← Skills
Context7, Persona, Permissions, Theme (standalone)
Soft: Persona must write base BEFORE Engram/SDD append
```

## 5. Topological Sort (`internal/planner/order.go`)

**Core**: Kahn's algorithm + soft ordering post-processing.

- Compute in-degree for each node
- Queue zero-in-degree nodes (sorted alphabetically for determinism)
- Dequeue → append to order → decrement children's in-degree → repeat
- If count(ordered) != count(nodes) → cycle detected
- `applySoftOrdering`: shift `first` element before `second` in the ordered array
