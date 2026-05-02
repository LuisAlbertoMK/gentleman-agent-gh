---
name: sdd-archive
description: > Sync delta specs → main → archive.
  Trigger: Orchestrator launches archive.
license: MIT
metadata: author: gentleman-programming, version: "2.0"
---

## STEPS
1.Sync: add→append, modify→replace, remove→delete
2.Move: change→archive/YYYY-MM-DD-{change}/
3.Verify: specs updated, folder moved, all artifacts present
4.Persist archive report
5.Return summary