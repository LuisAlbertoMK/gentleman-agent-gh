---
name: sdd-archive
description: "Archive completed changes — sync specs to main, move artifacts to archive, create rollback snapshots, and persist reports"
triggers: "Archive changes, delta to main"
license: MIT
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.3"
---

Trigger: Orchestrator launches archive, revert change.

Common protocol: `{file:sdd/references/sdd-phase-common.md}`

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

## ARCHIVE STRUCTURE
```
archive/
└── YYYY-MM-DD-{change-name}/
    ├── specs/              # Final spec snapshots
    ├── artifacts/          # Generated files, diagrams
    ├── rollback/
    │   ├── snapshot.diff   # Raw diff
    │   ├── rollback.sh     # Automated revert
    │   └── rollback.md     # Manual steps
    └── report.md           # Summary: what, why, files changed
```

## EDGE CASES
- No git commit yet → skip snapshot, note in report
- Archive path collision → append -2, -3 suffix
- Change reverted immediately → still archive with note "rolled back same session"
