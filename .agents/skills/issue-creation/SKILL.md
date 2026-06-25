---
name: gentle-ai-issue-creation
description: "Create Gentle AI issues with issue-first checks. Trigger: creating GitHub issues or feature requests."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Gentle AI — Issue Creation Skill

## When to Use
Report bugs/request features on [gentle-ai](https://github.com/Gentleman-Programming/gentle-ai). Load before opening issues.

## Critical Rules
1. **Blank issues DISABLED** — MUST use `.github/ISSUE_TEMPLATE/` template.
2. **`status:needs-review` auto-applied** — don't add manually.
3. **`status:approved` REQUIRED before work** — wait for maintainer.
4. **Questions → [Discussions](https://github.com/Gentleman-Programming/gentle-ai/discussions)**, not issues.
5. **No `Co-Authored-By`** in commits.

## Workflow
1. Search existing issues → confirm no duplicate (`gh issue list --repo Gentleman-Programming/gentle-ai --state open --search "keywords"`)
2. Choose template: `bug_report.yml` (bug) or `feature_request.yml` (feat)
3. Submit issue → `status:needs-review` applied automatically
4. **STOP.** Wait for maintainer to add `status:approved`
5. Only then → open a PR referencing this issue

> ⚠️ Do NOT open a PR until the issue has `status:approved`.

## Bug Report
**Template**: `.github/ISSUE_TEMPLATE/bug_report.yml`
**Auto-labels**: `bug`, `status:needs-review`

Required: Pre-flight checklist, description, reproduction steps, expected vs actual behavior, gga version, OS, AI agent/client, affected area (`CLI` · `TUI` · `Installation` · `Agent Detection` · `System Detection` · `Catalog/Steps` · `Documentation` · `Other`).

## Feature Request
**Template**: `.github/ISSUE_TEMPLATE/feature_request.yml`
**Auto-labels**: `enhancement`, `status:needs-review`

Required: Pre-flight checklist, affected area, problem statement, proposed solution.

```bash
gh issue create --repo Gentleman-Programming/gentle-ai --template bug_report.yml --title "fix(<scope>): ..."
gh issue create --repo Gentleman-Programming/gentle-ai --template feature_request.yml --title "feat(<scope>): ..."
```

## Label System (Summary)
- **Status** (issues): `needs-review` (auto) → `approved` (maintainer) → `in-progress` / `blocked` → `wont-fix`
- **Type** (PRs): `type:bug` · `type:feature` · `type:docs` · `type:refactor` · `type:chore` · `type:breaking-change`
- **Priority** (issues): `critical` · `high` · `medium` · `low`

## Decision Tree
```
Question/discussion? → GitHub Discussions (NOT issues)
Defect in gga?       → Bug Report template
New feature?         → Feature Request template
Duplicate exists?    → Comment on existing issue instead
Otherwise            → Submit new issue → wait for status:approved
```

## Commands
```bash
# Search issues
gh issue list --repo Gentleman-Programming/gentle-ai --state open --search "keywords"

# Check issue status
gh issue view <number> --repo Gentleman-Programming/gentle-ai
```

Valid scopes for titles: `tui`, `cli`, `installer`, `catalog`, `system`, `agent`, `e2e`, `ci`, `docs`
