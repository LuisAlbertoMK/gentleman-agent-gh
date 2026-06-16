---
name: gentle-ai-issue-creation
description: "Create Gentle AI issues with issue-first checks. Trigger: creating GitHub issues, bug reports, or feature requests."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Gentle AI — Issue Creation Skill

## When to Use

Load when reporting bugs in `gga`, requesting features, or opening GitHub issues on [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai).

## Critical Rules

1. **Blank issues DISABLED** — MUST use a template (bug report or feature request).
2. **`status:needs-review` auto-applied** — do NOT add manually.
3. **`status:approved` required before ANY work** — maintainer must label before opening PR.
4. **Questions → GitHub Discussions**, not issues.
5. **No `Co-Authored-By`** trailers.

## Workflow

1. Search existing issues (confirm not duplicate)
2. Choose template: Bug (`bug_report.yml`) or Feature (`feature_request.yml`)
3. Submit → `status:needs-review` auto-applied
4. **STOP** — wait for maintainer to add `status:approved`
5. Only then open a PR referencing the issue

## Bug Report

Template: `.github/ISSUE_TEMPLATE/bug_report.yml` — Auto-labels: `bug`, `status:needs-review`

**Required**: pre-flight checklist, description, steps, expected/actual, `gga version`, OS, agent, area

```bash
gh issue create --repo Gentleman-Programming/gentle-ai --template bug_report.yml --title "fix(<scope>): <desc>"
```

## Feature Request

Template: `.github/ISSUE_TEMPLATE/feature_request.yml` — Auto-labels: `enhancement`, `status:needs-review`

**Required**: pre-flight checklist, affected area, problem statement, proposed solution (include example `gga` command). Optional: alternatives, context.

```bash
gh issue create --repo Gentleman-Programming/gentle-ai --template feature_request.yml --title "feat(<scope>): <desc>"
```

## Label System

**Issues**: `status:needs-review` (auto) → `status:approved` (maintainer) → `status:in-progress` → `status:blocked` / `status:wont-fix`
**Types**: `bug` (issue) · `enhancement` (issue) · `type:*` (PRs: bug/feature/docs/refactor/chore/breaking-change)
**Priority**: `priority:critical` · `high` · `medium` · `low`

Scopes: `tui` · `cli` · `installer` · `catalog` · `system` · `agent` · `e2e` · `ci` · `docs`

## Commands

```bash
# Search existing issues
gh issue list --repo Gentleman-Programming/gentle-ai --state open --search "<keywords>"
gh issue list --repo Gentleman-Programming/gentle-ai --state all --search "<keywords>"

# Create issue
gh issue create --repo Gentleman-Programming/gentle-ai --template bug_report.yml --title "fix(<scope>): <desc>"
gh issue create --repo Gentleman-Programming/gentle-ai --template feature_request.yml --title "feat(<scope>): <desc>"

# Check status
gh issue view <N> --repo Gentleman-Programming/gentle-ai
```
