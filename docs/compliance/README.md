# GDPR / Compliance

This is a **meta-agent development tool** — it helps manage AI agent interactions in a software project. As such, its data processing is minimal and primarily local. This directory documents what data is collected, where it lives, and how users can exercise their rights.

## Guiding Principles

| Principle | How We Apply It |
|-----------|----------------|
| **Data minimisation** | Only operational data is stored (decisions, errors, session summaries). No tracking, no analytics, no telemetry. |
| **Purpose limitation** | Data serves one purpose: make the AI agent more effective across sessions. |
| **Storage limitation** | Engram (persistent memory) stores data indefinitely; user controls deletion via `ctx purge` or file deletion. |
| **Integrity & confidentiality** | Write-scope validation (`validate-write-scope.ps1`), permission modes (`auto`/`semi`/`manual`), and audit gates protect data. |
| **Accountability** | Session audit gate (`close-session.ps1`) tracks changes to protected files. Mode changes are explicit. |
| **User control** | All data is local and user-managed. No external service receives data. |

## Data Flow

```
User prompt → AI agent → Engram memory (local SQLite)
                        → BITACORA.md (local file)
                        → Git commits (local git)
                        → Mejoras/analysis (local files)
```

No data leaves this machine unless the user explicitly pushes to a remote git repository.

## Contents

| Document | What it covers |
|----------|----------------|
| [data-inventory.md](data-inventory.md) | Complete data catalogue — what, where, format, retention |
| [erasure.md](erasure.md) | Right to erasure — how to delete all data |
| [export.md](export.md) | Data portability — how to export all data |
