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

### Changed
- `install.sh` refactored: now calls setup-machine.sh (matching install.ps1 pattern)
- AGENTS.md portability sections now reference both .ps1 and .sh
- README installation section: Linux/macOS uses `./scripts/install.sh`
- README score synced to .project.json (9.3/10), script count to actual (56)
