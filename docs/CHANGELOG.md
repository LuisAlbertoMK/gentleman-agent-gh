# Changelog

All notable changes to gentleman-agent-gh are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/)
once releases begin.

## [Unreleased]

### Cycle 28 — Security Hardening + Quality Recovery (2026-07-29)

### Added
- `scripts/bash-safe.Tests.ps1` — 83 tests covering 10 injection patterns
- `scripts/validate-write-scope.ps1` — write-scope enforcement for T2+ tasks
- `prompts/gentleman-reviewer.md` — 4R code review agent (claude-sonnet-4-6)
- `data/skills-registry.csv` — skill-graph data extracted from inline table
- `LEARNING.md` — cross-session knowledge capture
- `.gentleman-mode` — permission mode selector (manual/semi/auto)
- `scripts/switch-mode.ps1` — switch between permission modes
- `scripts/permission-gate.ps1` — verify current mode matches expected
- .gitleaks.toml: 3 custom rules (GH_TOKEN, AWS AKIA, PASSWORD)
- engram-validate.ps1: expanded detection set 4→16 patterns + homoglyph detection

### Changed
- `README.md` — score synced to 9.1/10 (was 6.2), cycle 28 active, 123 scripts (was 91)
- `docs/ARCHITECTURE.md` — agent count synced to 24 (was 22), scripts to 123 (was 91)
- `CYCLE.md` — score target updated to 9.1→9.5 (was 6.2→7.5)
- `opencode.json` — -auto agents deny lists synchronized with opencode-base.json
- `.githooks/pre-commit` — secrets scan: removed `-CaseSensitive` flag
- `BITACORA.md` — deduplicated 394→122 lines; close-session guard prevents re-append
- `skill-graph.ps1` — 335→261 lines (data extracted to CSV)
- `.dockerignore` — +8 exclusions for secrets and build artifacts
- SEO skill — compressed from 8.9KB→6.5KB
- `score-auto.ps1` — multiline pipeline bugfix for Clean Code / Best Practices dims
- `scripts/close-session.ps1` — dedup guard prevents BITACORA flooding
- `scripts/engram-validate.ps1` — expanded detection from 4→16 patterns

### Added (pre-Cycle 28)
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

### Changed (pre-Cycle 28)
- `install.sh` refactored: now calls setup-machine.sh (matching install.ps1 pattern)
- AGENTS.md portability sections now reference both .ps1 and .sh
- README installation section: Linux/macOS uses `./scripts/install.sh`
- `opencode.json` security hardening: all 22 agents now have granular bash deny objects (17 dangerous commands blocked)
- `opencode.json`: global bash/write/edit deny rules for sensitive paths
- `gentleman-implementer` prompt moved from inline (2K chars) to file reference (`{file:prompts/gentleman-implementer.md}`)
- `score-auto.ps1`: now writes computed scores to `.project.json` (single source of truth)
- `build-skill-registry.ps1`: strips tags/dependencies from output (compact format)
- `skill-registry.json`: compacted from 32.8KB to 17.8KB (-45.8%)

### Fixed (pre-Cycle 28)
- `.github/workflows/quality-gate.yml`: added `permissions: contents: read`
- `opencode.json`: reverted broken sequential-thinking MCP path change
- `score-auto.ps1`: removed obsolete `restore-project-score.ps1` call (now writes .project.json directly)
- `score-auto.ps1`: preserves bias_adjusted/bias_note fields when writing to .project.json
- `score-auto.ps1`: adds validation guard before writing (score 0-10, >=11 dims)
- `score-auto.ps1`: try/finally around skip-worktree toggle prevents index corruption
