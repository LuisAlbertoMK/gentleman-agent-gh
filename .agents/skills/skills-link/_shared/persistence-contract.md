# Persistence Contract (shared across all SDD skills)

## Mode Resolution
Orchestrator passes `artifact_store.mode`: `engram | openspec | hybrid | none`.
Asked at first `/sdd-new|ff|continue` per session. Default: `engram` if available, else `none`.

| Mode | Role | Cross-session | Team-shareable | Iteration history | Project files |
|------|------|:---:|:---:|:---:|:---:|
| `engram` | Working memory | ✅ | ❌ | ❌ (upsert) | Never |
| `openspec` | Source of truth | ❌ (needs git) | ✅ | ✅ (git) | Yes |
| `hybrid` | Both | ✅ | ✅ (files) | ✅ (files+git) | Yes |
| `none` | Ephemeral | ❌ | ❌ | ❌ | Never |

**Hybrid**: Engram (primary read) + Filesystem (fallback read). Write to BOTH. Both writes MUST succeed.

**Limitation**: Engram upserts overwrite — no revision history. Archive saves a summary, not full artifacts.

## State Persistence (orchestrator)
`engram` → `mem_save(topic_key: "sdd/{change}/state")` | `openspec` → `openspec/changes/{change}/state.yaml` | `hybrid` → both | `none` → warn

## Sub-Agent Rules
- Non-SDD: orchestrator searches engram, passes summary. Sub-agent saves discoveries via `mem_save`.
- SDD (with deps): reads artifacts from backend, saves its artifact.
- SDD (no deps): saves its artifact only.
Orchestrator reads for non-SDD (knows what's relevant). Sub-agents read for SDD (artifacts too large for orchestrator prompt). Sub-agents always write.

## Orchestrator Prompt Templates
Non-SDD: `PERSISTENCE: mem_save(title, type, project, content). Do NOT return without saving.`
SDD (with deps): `Read: mem_search → mem_get_observation. Then mem_save(title: "sdd/{change}/{type}", topic_key: ..., type: "architecture", content: "..."). Pipeline BREAKS if you don't save.`
SDD (no deps): Same mem_save as above without the read steps.

## Skill Registry
Orchestrator injects compact rules as `## Project Standards (auto-resolved)`. Sub-agents do NOT read registry or individual SKILL.md. Generate/update: `skill-registry` skill or `sdd-init`.

## Detail Level
`concise | standard | deep` — affects output verbosity, NOT what gets persisted. Always persist full artifact.
