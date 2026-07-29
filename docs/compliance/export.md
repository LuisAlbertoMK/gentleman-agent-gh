# Data Portability — Export Guide

How to export all data stored by the system.

## Quick — Full Export

```powershell
# Create export directory
$exportDir = "export-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
New-Item -ItemType Directory -Path $exportDir -Force | Out-Null

# 1. Export Engram memory
engram sync --project gentleman-agent-gh   # Creates .engram/ directory
Copy-Item -Path ".engram" -Destination "$exportDir/engram" -Recurse -Force

# 2. Export BITACORA
Copy-Item -Path "BITACORA.md" -Destination "$exportDir/BITACORA.md" -Force

# 3. Export analysis documents
if (Test-Path "docs/mejoras") {
    Copy-Item -Path "docs/mejoras" -Destination "$exportDir/mejoras" -Recurse -Force
}

# 4. Export compliance docs
if (Test-Path "docs/compliance") {
    Copy-Item -Path "docs/compliance" -Destination "$exportDir/compliance" -Recurse -Force
}

# 5. Export SDD registry
if (Test-Path "docs/sdd") {
    Copy-Item -Path "docs/sdd" -Destination "$exportDir/sdd" -Recurse -Force
}

# 6. Export project score
Copy-Item -Path ".project.json" -Destination "$exportDir/project.json" -Force

# 7. Export config
Copy-Item -Path ".gentleman-mode" -Destination "$exportDir/gentleman-mode" -Force
Copy-Item -Path "sdd-config.yaml" -Destination "$exportDir/sdd-config.yaml" -Force

# 8. Export git log (commits authored by you)
git log --author="$(git config user.name)" --format="%H %ai %s" > "$exportDir/git-log.txt"

Write-Output "Export complete: $exportDir"
Write-Output "Total size: $((Get-ChildItem -Path $exportDir -Recurse | Measure-Object Length -Sum).Sum / 1KB) KB"
```

## Selective Export

| Data | Command |
|------|---------|
| Engram | `engram tui` (browse and select) or `engram sync` |
| BITACORA | Copy `BITACORA.md` |
| Mejoras | Copy `docs/mejoras/*.md` |
| SDD | Copy `docs/sdd/registry.yaml` |
| Project score | Copy `.project.json` |

## Human-Readable Formats

All stored data is in human-readable formats (Markdown, YAML, JSON). No proprietary or binary encoding is used (Engram uses SQLite but the data is text-based).

- BITACORA.md → Markdown ✓
- mejoras/ → Markdown ✓
- sdd/registry.yaml → YAML ✓
- sdd-config.yaml → YAML ✓
- .project.json → JSON ✓
- .gentleman-mode → plain text ✓
- Engram → SQLite + text ✓
