---
name: issue-creation
description: "Create Gentle AI issues with issue-first checks. Trigger: creating GitHub issues, bug reports, or feature requests."
triggers: "create issue, GitHub issue, bug report, feature request, issue template"
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
  changelog: "1.1: karpathy compress (7.3→3.0KB)"
---

# Gentle AI — Issue Creation Skill

## When to Use
Report bugs / request features on [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai). Load before opening issues.

## Critical Rules
1. **Blank issues DISABLED** — MUST use `.github/ISSUE_TEMPLATE/` (bug_report.yml or feature_request.yml).
2. **`status:needs-review` auto-applied** — don't add manually.
3. **`status:approved` REQUIRED before work** — wait for maintainer.
4. **Questions → [Discussions](https://github.com/Gentleman-Programming/gentle-ai/discussions)**, not issues.
5. **No `Co-Authored-By`** trailers in commits.

## Workflow
```
Search duplicates → choose template (bug/feat) → submit → status:needs-review(auto) → wait for status:approved → open PR referencing issue
```

## Bug Report
Template: `.github/ISSUE_TEMPLATE/bug_report.yml`. Auto-labels: `bug`, `status:needs-review`.

Required: Pre-flight checklist · description · steps · expected vs actual · gga version · OS · AI agent/client · affected area (CLI/TUI/Installation/Agent Detection/System Detection/Catalog/Steps/Docs/Other)

## Feature Request
Template: `.github/ISSUE_TEMPLATE/feature_request.yml`. Auto-labels: `enhancement`, `status:needs-review`.

Required: Pre-flight · affected area · problem statement · proposed solution. Optional: alternatives, context.

## Labels
| Category | Labels |
|----------|--------|
| **Status** | `needs-review`(auto) → `approved`(maintainer) → `in-progress` / `blocked` → `wont-fix` |
| **Type** | `bug`, `enhancement`, `type:{bug,feature,docs,refactor,chore,breaking-change}` |
| **Priority** | `critical`, `high`, `medium`, `low` |

## Maintainer Flow
```
Issue → needs-review(auto) → maintainer reviews → approved (work begins) / closed (invalid/dup)
```

## Decision Tree
```
Question? → Discussions · Defect? → Bug template · Feature? → Feature template · Duplicate? → Comment on existing · Else → Submit → wait for approved
```

## Commands
```bash
gh issue list --repo Gentleman-Programming/gentle-ai --state open --search "keywords"  # search
gh issue create --repo Gentleman-Programming/gentle-ai --template bug_report.yml --title "fix(<scope>): desc"
gh issue create --repo Gentleman-Programming/gentle-ai --template feature_request.yml --title "feat(<scope>): desc"
gh issue view <N> --repo Gentleman-Programming/gentle-ai  # check status
```

Valid scopes: `tui`, `cli`, `installer`, `catalog`, `system`, `agent`, `e2e`, `ci`, `docs`
