---
name: gentle-ai-issue-creation
description: "Create Gentle AI issues with issue-first checks. Trigger: creating GitHub issues, bug reports, or feature requests."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Gentle AI — Issue Creation Skill

Reporting bugs, requesting features on [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai).

## Rules
1. **Blank issues DISABLED** — MUST use template.
2. **`status:needs-review` auto-applied** — do NOT add manually.
3. **`status:approved` REQUIRED** before any PR work.
4. **Questions → Discussions** ([link](https://github.com/Gentleman-Programming/gentle-ai/discussions)), not issues.
5. **No `Co-Authored-By` trailers**.

## Workflow
1. Search existing issues → confirm no duplicate
2. Choose template: `bug_report.yml` (bug) or `feature_request.yml` (feature)
3. Submit → `status:needs-review` auto-applied
4. Wait for maintainer → `status:approved` or closed
5. Only after approval → open PR referencing issue

## Bug Report
Template: `.github/ISSUE_TEMPLATE/bug_report.yml` · Labels: `bug`, `status:needs-review`
**Fields**: Pre-flight Checklist, Bug Description, Steps to Reproduce, Expected Behavior, Actual Behavior, `gga version`, OS, AI Agent/Client, Affected Area.
**Areas**: `CLI`·`TUI`·`Installation`·`Agent Detection`·`System Detection`·`Catalog/Steps`·`Docs`·`Other`

## Feature Request
Template: `.github/ISSUE_TEMPLATE/feature_request.yml` · Labels: `enhancement`, `status:needs-review`
**Required**: Pre-flight Checklist, Affected Area, Problem Statement, Proposed Solution.
**Optional**: Alternatives Considered, Additional Context.

## Labels
**Status**: `needs-review`(auto) · `approved`(maintainer) · `in-progress`(contributor) · `blocked`(maintainer/contributor) · `wont-fix`(maintainer)
**Type**: `bug`/`enhancement`(issues) · `type:bug`/`:feature`/`:docs`/`:refactor`/`:chore`/`:breaking-change`(PRs)
**Priority**: `critical`(blocking/security) · `high`(many users) · `medium`(normal) · `low`(nice to have)

## Decision Flow
Question/idea? → **Discussions** · Bug in `gga`? → **Bug Report** · Otherwise → **Feature Request** · Duplicate? → Comment on existing · New → Submit + wait for `status:approved`

## Commands
```bash
# Search
gh issue list --repo Gentleman-Programming/gentle-ai --state open --search "keywords"
# Create bug
gh issue create --repo Gentleman-Programming/gentle-ai --template bug_report.yml --title "fix(<scope>): <desc>"
# Create feature
gh issue create --repo Gentleman-Programming/gentle-ai --template feature_request.yml --title "feat(<scope>): <desc>"
# Check status
gh issue view <N> --repo Gentleman-Programming/gentle-ai
```

**Valid scopes**: `tui`, `cli`, `installer`, `catalog`, `system`, `agent`, `e2e`, `ci`, `docs`

## References
- [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.yml)
- [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.yml)
