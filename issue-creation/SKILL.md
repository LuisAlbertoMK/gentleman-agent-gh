---
name: issue-creation
description: >
  Issue creation workflow for Agent Teams Lite (issue-first enforcement).
  Trigger: Creating GitHub issue, reporting bug, requesting feature.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When
GitHub issue (bug/feature) · Help contributor file issue · Triaging/approving

## Critical Rules
1. Blank issues disabled — MUST use template
2. `status:needs-review` auto-applied on creation
3. Maintainer MUST add `status:approved` before PR
4. Questions → Discussions, not issues

## Workflow
1. Search existing issues (no duplicates)
2. Choose template (Bug Report / Feature Request)
3. Fill ALL required fields
4. Submit → `status:needs-review` auto
5. Wait for `status:approved`
6. Open PR linking this issue

## Issue Templates

### Bug Report
Auto-labels: `bug`, `status:needs-review`

**Required:** Pre-flight checks · Bug description · Steps to reproduce · Expected behavior · Actual behavior (errors/logs) · OS · Agent/Client · Shell

**Optional:** Relevant logs · Additional context

```bash
gh issue create --template "bug_report.yml" \
  --title "fix(scripts): setup.sh fails on zsh with glob error"
```

### Feature Request
Auto-labels: `enhancement`, `status:needs-review`

**Required:** Pre-flight checks · Problem description · Proposed solution · Affected area

**Optional:** Alternatives considered · Additional context

```bash
gh issue create --template "feature_request.yml" \
  --title "feat(scripts): add Codex support to setup.sh"
```

## Label System

### Auto-Applied
| Template | Labels |
|----------|--------|
| Bug Report | `bug`, `status:needs-review` |
| Feature Request | `enhancement`, `status:needs-review` |

### Maintainer-Applied
| Label | When |
|-------|------|
| `status:approved` | Issue accepted → PRs can open |
| `priority:high` | Critical/urgent |
| `priority:medium` | Important, not blocking |
| `priority:low` | Nice to have |

## Approval Workflow
```
New issue (status:needs-review) → Review: valid/clear/in-scope?
  → YES: add status:approved
  → NO: comment + reason, close if needed
```

## Decision Tree
Bug → Bug Report template
New feature → Feature Request template
Question → Discussions
Duplicate → Link existing, close

## Commands
```bash
gh issue list --search "keyword"              # Search before creating
gh issue create --template "bug_report.yml"   # Bug
gh issue create --template "feature_request.yml"  # Feature
gh issue edit <number> --add-label "status:approved"  # Approve
gh issue edit <number> --add-label "priority:high"    # Prioritize
```
