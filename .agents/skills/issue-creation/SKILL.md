---
name: issue-creation
description: "Create Gentle AI issues with issue-first checks."
triggers: "create issue, GitHub issue, bug report, feature request, open issue, issue creation, report bug"
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When
- Report a bug in `gga`
- Request feature/enhancement
- Open issue on Gentleman-Programming/gentle-ai

## Rules
1. **Blank issues DISABLED** — MUST use `.github/ISSUE_TEMPLATE/bug_report.yml` or `feature_request.yml`.
2. **`status:needs-review` auto-applied** — do NOT add manually.
3. **`status:approved` REQUIRED** before ANY work.
4. **Questions → GitHub Discussions**, not issues.
5. **No `Co-Authored-By`** trailers.

## Workflow
1. Search: `gh issue list -R Gentleman-Programming/gentle-ai --state all -s "keywords"` → confirm no dup
2. Pick template: bug → `bug_report.yml` | feat → `feature_request.yml`
3. Submit → `status:needs-review` auto → STOP
4. Wait for `status:approved` (or closed)
5. ONLY after approved → PR with `Closes #<N>`

## Bug Report
Auto-labels: `bug`, `status:needs-review`
Fields: Pre-flight, Bug Description, Steps to Reproduce, Expected/Actual, gga version, OS, AI Agent/Client, Affected Area.
Areas: `CLI` · `TUI` · `Installation` · `Agent Detection` · `System Detection` · `Catalog/Steps` · `Documentation` · `Other`

## Feature Request
Auto-labels: `enhancement`, `status:needs-review`
Fields: Pre-flight, Affected Area, Problem Statement, Proposed Solution, Alternatives, Context

## Labels
**Status**: `needs-review` → `approved` → `in-progress` → `blocked`|`wont-fix`
**Type** (issues): `bug`|`enhancement` · (PRs): `type:bug`|`type:feature`|`type:docs`|`type:refactor`|`type:chore`|`type:breaking-change`
**Priority**: `critical`|`high`|`medium`|`low`

## Commands
```bash
gh issue list -R Gentleman-Programming/gentle-ai --state all -s "keywords"
gh issue create -R Gentleman-Programming/gentle-ai --template bug_report.yml -t "fix(<scope>): <desc>"
gh issue create -R Gentleman-Programming/gentle-ai --template feature_request.yml -t "feat(<scope>): <desc>"
gh issue view <N> -R Gentleman-Programming/gentle-ai
```

Valid scopes: `tui`, `cli`, `installer`, `catalog`, `system`, `agent`, `e2e`, `ci`, `docs`

## Refs
branch-pr · commit-crafter · quality-gate · work-unit-commits · skill-creator

## Anti-Patterns
Create issue without searching duplicates · Skip template · Work before approved · Use issue for questions · Start PR without Closes #N
