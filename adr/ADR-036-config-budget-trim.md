# ADR-036: Config Context Budget Trim — opencode.json 89.7% → 63.6%

- **Status**: Applied (C3 cycle)
- **Date**: 2026-08-19
- **Deciders**: gentleman-quick (autonomous C3 task)

## Context

`opencode.json` was 58,626B (89.7% of 65,536B limit). Approaching ceiling risks:
- Runtime parsing failures on edge-case JSON decoders
- Reduced headroom for future config additions
- Token overhead when config is loaded into agent context

## Decision

Remove 6 unused `-semi` agents + clean up redundant config entries to bring file under 85% threshold.

### What was trimmed

| Category | Items removed | Bytes saved |
|----------|--------------|-------------|
| 6 `-semi` agents | `gentleman-{deep,quick,codex,implementer,aem,vMK}-semi` | ~15,500B |
| Disabled MCP servers | `headroom`, `chrome-devtools-mcp` | ~250B |
| Top-level `tools` disables | Redundant per-agent overrides | ~40B |
| **Total** | | **~16,468B** |

### Why these were safe to remove

1. **Semi agents**: ADR-033 documented semi mode as unused (H7: `.gentleman-mode` permanently `auto`). These 6 agents had identical ~100-line bash permission blocks — pure boilerplate. `remove-semi-agents.ps1` already existed for this migration.

2. **Disabled MCP servers**: `headroom` and `chrome-devtools-mcp` had `"enabled": false`. No runtime impact.

3. **Top-level `tools` disables**: `codebase-memory*` and `engram*` set to `false` at top level, but overridden to `true` per-agent where needed. The top-level block was dead config.

### What was NOT touched

- Routing instructions (`gentle-orchestrator` bridge)
- Permission rules (global bash/read/write/edit)
- Mode settings (manual/auto agents)
- Active MCP servers (codebase-memory-mcp, context7, engram)
- Agent prompts, descriptions, or tool configurations
- All 42 functional agents preserved

## Result

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| File size | 58,626B | 41,704B | −16,922B (−28.9%) |
| % of 65,536B limit | 89.7% | 63.6% | −26.1pp |
| Agent count | 55 | 49 | −6 (semi only) |
| Cross-ref check | 9/9 OK | 9/9 OK | = |

## Verification

- `score-auto -Json`: SE=7.0, PA=8.0, overall=8.8
- `cross-ref-check`: 9/9 OK
- `Pester cross-ref.Tests.ps1`: 9/9 passed
- JSON validity: confirmed via `JSON.parse()` + key agent presence check

## References

- ADR-033: Simplificar modos de permiso — eliminar `semi` (proposed, this ADR applies it)
- `docs/mejoras/2026-07-30-auto-permission-analysis.md` H2: 960 líneas boilerplate
- `scripts/remove-semi-agents.ps1`: migration tool (backup + delete)
