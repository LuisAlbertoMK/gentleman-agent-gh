---
name: gentle-ai-issue-creation
description: "Create Gentle AI issues with issue-first checks. Trigger: creating GitHub issues, bug reports, or feature requests."
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
3. **`status:approved` REQUIRED** before ANY work (maintainer adds it).
4. **Questions → GitHub Discussions**, not issues.
5. **No `Co-Authored-By`** trailers.

## Workflow
```
1. Search: gh issue list --repo Gentleman-Programming/gentle-ai --state all --search "keywords" → confirm no duplicate
2. Pick template: bug → bug_report.yml | feat → feature_request.yml
3. Submit → status:needs-review auto-applied → STOP
4. Wait for maintainer → status:approved (or closed)
5. ONLY after approved → PR with Closes #<N>
```

## Bug Report (.github/ISSUE_TEMPLATE/bug_report.yml)
Auto-labels: `bug`, `status:needs-review`
Fields: Pre-flight check, Bug Description, Steps to Reproduce, Expected/Actual Behavior, gga version, OS, AI Agent/Client, Affected Area.
Areas: `CLI` · `TUI` · `Installation` · `Agent Detection` · `System Detection` · `Catalog/Steps` · `Documentation` · `Other`

## Feature Request (.github/ISSUE_TEMPLATE/feature_request.yml)
Auto-labels: `enhancement`, `status:needs-review`
Fields: Pre-flight check, Affected Area, Problem Statement, Proposed Solution (incl. example command/output), Alternatives (optional), Context (optional)

## Labels
**Status**: `needs-review`(auto) → `approved`(maintainer) → `in-progress`(contributor) → `blocked`|`wont-fix`
**Type** (issues): `bug`|`enhancement`. **Type** (PRs): `type:bug`|`type:feature`|`type:docs`|`type:refactor`|`type:chore`|`type:breaking-change`
**Priority**: `critical`|`high`|`medium`|`low`

## Commands
```bash
# Search
gh issue list --repo Gentleman-Programming/gentle-ai --state open --search "keywords"
gh issue list --repo Gentleman-Programming/gentle-ai --state all --search "keywords"

# Create bug
gh issue create --repo Gentleman-Programming/gentle-ai --template bug_report.yml --title "fix(<scope>): <desc>"

# Create feature
gh issue create --repo Gentleman-Programming/gentle-ai --template feature_request.yml --title "feat(<scope>): <desc>"

# Check status
gh issue view <N> --repo Gentleman-Programming/gentle-ai

# Web forms
https://github.com/Gentleman-Programming/gentle-ai/issues/new?template=bug_report.yml
https://github.com/Gentleman-Programming/gentle-ai/issues/new?template=feature_request.yml
```

Valid scopes: `tui`, `cli`, `installer`, `catalog`, `system`, `agent`, `e2e`, `ci`, `docs`
