# Contributing to gentleman-agent-gh

## Before you start

1. **Check existing issues** — search open/closed issues for your topic
2. **Open an issue first** for bugs or feature requests before submitting PRs

## Development workflow

1. Fork the repo and create a branch from `master`
2. Make changes using conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`, `cycle:`)
3. Ensure quality gate passes locally: run the checks in `.github/workflows/quality-gate.yml`
4. Open a PR with a clear description and link to the related issue

## Commit conventions

- `feat:` — new feature or skill
- `fix:` — bug fix
- `docs:` — documentation only
- `refactor:` — code change with no functional difference
- `cycle:` — self-improvement cycle
- `chore:` — maintenance, deps, CI

## Code style

- PowerShell scripts: `#requires -Version 7.6`, `Set-StrictMode -Version Latest`, `$ErrorActionPreference = "Stop"`
- Shell scripts: `set -euo pipefail`, POSIX-compatible
- Skills: keep `SKILL.md` under 3KB, one concern per skill

## Review expectations

- PRs under 400 lines are reviewed faster
- Changes to scripts/ or skills/ get extra CI attention
- If your PR fixes an issue, include "Closes #N" in the description
