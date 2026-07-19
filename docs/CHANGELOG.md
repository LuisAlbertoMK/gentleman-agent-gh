# Changelog

All notable changes to gentleman-agent-gh are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/)
once releases begin.

## [Unreleased]

### Added
- `scripts/setup-machine.sh` — bash equivalent of setup-machine.ps1 for Linux/macOS (#portability)
- Linux/macOS install via `./scripts/install.sh` (wrapper around setup-machine.sh)
- Issue templates: bug report + feature request + config
- CONTRIBUTING.md with commit conventions and workflow
- CHANGELOG.md following Keep a Changelog format
- CI step to validate install.sh on ubuntu-latest
- `docs/ciclos/cycle19-*.md` — closing the gap with gentle-ai
- `prompts/gentleman-implementer.md` — extracted from inline prompt in opencode.json
- `docs/ARCHITECTURE.md` — system design, module boundaries, data flow diagrams
- `docs/METRICS.md` — success metrics beyond 13-dimension scoring
- `Dockerfile` — reproducible dev environment (PowerShell 7.6+, Node.js 20, Python 3)
- `.devcontainer/devcontainer.json` — VS Code dev container configuration
- `.dockerignore` — exclude .git, node_modules, .learnings from Docker build
- `scripts/data-pipeline.ps1` — orchestrator connecting scoring, metrics, and learning

### Changed
- `install.sh` refactored: now calls setup-machine.sh (matching install.ps1 pattern)
- AGENTS.md portability sections now reference both .ps1 and .sh
- README installation section: Linux/macOS uses `./scripts/install.sh`
- README score synced to .project.json (9.3/10), script count to actual (56)
- `opencode.json` security hardening: all 22 agents now have granular bash deny objects (17 dangerous commands blocked)
- `opencode.json`: global bash/write/edit deny rules for sensitive paths
- `gentleman-implementer` prompt moved from inline (2K chars) to file reference (`{file:prompts/gentleman-implementer.md}`)
- `score-auto.ps1`: now writes computed scores to `.project.json` (single source of truth)
- `build-skill-registry.ps1`: strips tags/dependencies from output (compact format)
- `skill-registry.json`: compacted from 32.8KB to 17.8KB (-45.8%)

### Fixed
- `.github/workflows/quality-gate.yml`: added `permissions: contents: read`
- `opencode.json`: reverted broken sequential-thinking MCP path change
- `score-auto.ps1`: removed obsolete `restore-project-score.ps1` call (now writes .project.json directly)
- `score-auto.ps1`: preserves bias_adjusted/bias_note fields when writing to .project.json
- `score-auto.ps1`: adds validation guard before writing (score 0-10, >=11 dims)
- `score-auto.ps1`: try/finally around skip-worktree toggle prevents index corruption
