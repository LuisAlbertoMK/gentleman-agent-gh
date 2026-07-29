---
name: issue-creation
description: "Create Gentle AI issues with issue-first checks."
triggers: "create issue, GitHub issue, bug report, feature request, open issue, issue creation, report bug"
---

## When to Use
- Report a bug in `gga`
- Request feature/enhancement
- Open issue on Gentleman-Programming/gentle-ai
- Triaging or approving issues

## Critical Rules
1. **Blank issues DISABLED** — MUST use `.github/ISSUE_TEMPLATE/bug_report.yml` or `feature_request.yml`.
2. **`status:needs-review` auto-applied** — do NOT add manually.
3. **`status:approved` REQUIRED** before ANY PR.
4. **Questions → [GitHub Discussions](https://github.com/Gentleman-Programming/gentle-ai/discussions)**, not issues.
5. **No `Co-Authored-By`** trailers.

## Decision Tree
```
Bug?                  → Bug Report template
New feature?          → Feature Request template
Question?             → Discussions (not issues)
Duplicate?            → Link existing, close
```

## Workflow
```
1. Search existing issues for duplicates
2. Choose template (Bug Report or Feature Request)
3. Fill ALL required fields
4. Submit → gets status:needs-review (auto)
5. Wait for status:approved
6. Only after approved → PR with Closes #<N>
```

## Issue Templates

### Bug Report
Template: `.github/ISSUE_TEMPLATE/bug_report.yml` | Labels: `bug`, `status:needs-review`
Areas: `CLI` · `TUI` · `Installation` · `Agent Detection` · `System Detection` · `Catalog/Steps` · `Documentation` · `Other`

| Field | Required | Notes |
|-------|----------|-------|
| Pre-flight Checks | ✓ | No duplicate + understands approval |
| Bug Description | ✓ | Clear description |
| Steps to Reproduce | ✓ | Numbered steps |
| Expected vs Actual | ✓ | What should happen vs what happened |
| gga version | ✓ | Version string |
| Operating System | ✓ | OS name/version |
| Agent / Client | ✓ | AI agent used |
| Relevant Logs | — | Auto-formatted code block |
| Additional Context | — | Screenshots, workarounds |

### Feature Request
Template: `.github/ISSUE_TEMPLATE/feature_request.yml` | Labels: `enhancement`, `status:needs-review`

| Field | Required | Notes |
|-------|----------|-------|
| Pre-flight Checks | ✓ | No duplicate + understands approval |
| Affected Area | ✓ | Dropdown |
| Problem Statement | ✓ | Pain point this solves |
| Proposed Solution | ✓ | User-facing behavior |
| Alternatives Considered | — | Other approaches |
| Additional Context | — | Mockups, references |

## Label System

| Template | Auto Labels |
|----------|-------------|
| Bug Report | `bug`, `status:needs-review` |
| Feature Request | `enhancement`, `status:needs-review` |

**Status flow**: `needs-review` → `approved` → `in-progress` → `blocked`|`wont-fix`
**Type** (issues): `bug`|`enhancement` · (PRs): `type:bug`|`type:feature`|`type:docs`|`type:refactor`|`type:chore`|`type:breaking-change`
**Priority**: `critical`|`high`|`medium`|`low`

## Maintainer Workflow
```
1. Issue arrives → status:needs-review
2. Valid & clear? → add status:approved
3. Not clear? → comment, request info
4. Invalid/duplicate? → close with reason
5. Contributor opens PR linking the issue
```

## Commands
```bash
gh issue list -R Gentleman-Programming/gentle-ai --state all -s "keywords"
gh issue create -R Gentleman-Programming/gentle-ai --template bug_report.yml -t "fix(<scope>): <desc>"
gh issue create -R Gentleman-Programming/gentle-ai --template feature_request.yml -t "feat(<scope>): <desc>"
gh issue view <N> -R Gentleman-Programming/gentle-ai
```

Valid scopes: `tui`, `cli`, `installer`, `catalog`, `system`, `agent`, `e2e`, `ci`, `docs`

## Refs
branch-pr · commit-crafter · quality-gate · work-unit-commits · opencode-skill-creator

## Anti-Patterns
Create issue without searching duplicates · Skip template · Work before approved · Use issue for questions · Start PR without Closes #N
