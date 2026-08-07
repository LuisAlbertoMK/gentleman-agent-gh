# Contributing to gentleman-agent-gh

## Before you start

1. **Check existing issues** — search open/closed issues for your topic
2. **Open an issue first** for bugs or feature requests before submitting PRs

## Development workflow

1. Fork the repo and create a branch from `main`
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

## How to create a skill

1. **Run intake** (mandatory): Answer 3-5 questions about behavior, triggers, output quality, workflow, and test cases
2. **Create the directory**: `.agents/skills/{skill-name}/SKILL.md`
3. **Write SKILL.md** with YAML frontmatter:
   ```yaml
   ---
   name: my-skill
   description: "One-line description"
   triggers: "keyword1, keyword2, keyword3"
   license: Apache-2.0
   metadata:
     author: your-name
     version: "1.0"
   ---
   ```
4. **Keep it under 3KB** — use Karpathy compression (rules > tutorial prose)
5. **Register in `data/skills-registry.csv`**: Add a `Name|Triggers|Category|Effort|DependsOn|Related|Description` row (consumed by `skill-graph.ps1`)
6. **Add to SKILLS-INDEX.md**: Add a trigger row in the trigger table
7. **Validate**: Run `scripts/skill-validate.ps1` for a 3-trial benchmark
8. **Test**: Run `scripts/scan-skills.ps1` to verify registration completeness

### Skill structure rules

- **Frontmatter required**: name, description, triggers, license, metadata.version
- **Sections**: `## When to Use`, `## Rules` or `## Critical Rules` (recommended)
- **One concern per skill**: If it does two things, make two skills
- **No TODO/FIXME**: Skills are production code
- **Triggers**: Comma-separated keywords that activate this skill

## How to add a script

1. **Place in `scripts/`** with `.ps1` extension
2. **Add header**: `#requires -Version 7.6` + comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`)
3. **Strict mode**: `Set-StrictMode -Version Latest` + `$ErrorActionPreference = 'Stop'`
4. **Parameters**: Use `[Parameter()]` declarations with validation
5. **Error handling**: Wrap risky operations in `try/catch`
6. **Validate**: Run `scripts/pssa-gate.ps1 -Mode Check` for PSScriptAnalyzer

## Review expectations

- PRs under 400 lines are reviewed faster
- Changes to scripts/ or skills/ get extra CI attention
- If your PR fixes an issue, include "Closes #N" in the description
