# Data Inventory

Complete catalogue of what data the system collects, where it is stored, and how long it is retained.

## 1. Engram (Persistent Memory)

| Property | Value |
|----------|-------|
| **Location** | `~/.engram/engram.db` (global, per-user) |
| **Format** | SQLite |
| **Content** | Decisions, bug fixes, architecture decisions, discoveries, patterns, session summaries, user preferences |
| **Size** | ~500 KB |
| **Retention** | Indefinite — no auto-pruning |
| **Controller** | `ctx purge` (delete per session or per project) |
| **Backup** | `.engram/` directory in project (via `engram sync`) |

**What gets saved automatically:**
- Session summaries (via `mem_session_summary`)
- Bug fixes (via `mem_save` with type `bugfix`)
- Architecture decisions (via `mem_save` with type `architecture`)
- Discoveries and learnings (via `mem_save`)
- User prompts (via `mem_save_prompt`)
- Tool call history (ephemeral — not persisted to Engram)

## 2. BITACORA (Session Log)

| Property | Value |
|----------|-------|
| **Location** | `BITACORA.md` (project root) |
| **Format** | Markdown, one entry per session |
| **Content** | Session date, description, optional errors |
| **Size** | ~14 KB |
| **Retention** | Git-tracked — persists as long as the file exists |
| **Controller** | Manual: edit or delete the file, or delete entries |

## 3. Git History

| Property | Value |
|----------|-------|
| **Location** | `.git/` (project root) |
| **Format** | Git objects |
| **Content** | All committed file content, commit messages, authorship |
| **Retention** | Indefinite — all git history |
| **Controller** | `git reset`, `git rebase`, `git filter-branch` |

## 4. Project Score

| Property | Value |
|----------|-------|
| **Location** | `.project.json` (project root) |
| **Format** | JSON |
| **Content** | Dimension scores (SD, DC, Or, SC, Se, etc.) |
| **Retention** | Indefinite — overwritten on each `!score` |
| **Controller** | Manual: edit or delete |

## 5. Analysis Documents

| Property | Value |
|----------|-------|
| **Location** | `docs/mejoras/*.md` |
| **Format** | Markdown |
| **Content** | Improvement analyses, gap analyses, implementation reports |
| **Retention** | Git-tracked |
| **Controller** | Manual: edit or delete |

## 6. Configuration

| Property | Value |
|----------|-------|
| **Location** | `.gentleman-mode`, `sdd-config.yaml`, `opencode.json` |
| **Format** | Text/YAML/JSON |
| **Content** | Permission mode, SDD config, agent permissions |
| **Retention** | Git-tracked |
| **Controller** | Manual: edit or delete |

## 7. SDD Registry

| Property | Value |
|----------|-------|
| **Location** | `docs/sdd/registry.yaml` |
| **Format** | YAML |
| **Content** | Change log, timestamps, files changed |
| **Retention** | Git-tracked |
| **Controller** | Manual: edit or delete |

## 8. MCP / Tool Execution Logs

| Property | Value |
|----------|-------|
| **Location** | Session context (ephemeral) |
| **Format** | Conversation context |
| **Content** | Tool calls, command output, file reads/writes |
| **Retention** | Ephemeral — lost when session ends or context is compacted |
| **Controller** | None (not persisted) |

## Summary

| Store | Personal Data? | Persistent? | Git-tracked? | User Export? | User Delete? |
|-------|---------------|-------------|--------------|--------------|--------------|
| Engram | Session content | Yes | Optional (`engram sync`) | `ctx purge` | `ctx purge` |
| BITACORA.md | Session descriptions | Yes | Yes | File copy | File edit |
| Git history | Commits | Yes | Yes | `git clone` | `git filter-branch` |
| .project.json | Scores | Yes | Yes | File copy | File delete |
| docs/mejoras/ | Analysis | Yes | Yes | File copy | File delete |
| .gentleman-mode | Mode preference | Yes | Yes | File copy | File edit |
| docs/sdd/registry.yaml | Change log | Yes | Yes | File copy | File edit |
| MCP logs | Full tool calls | No | No | N/A | N/A |
