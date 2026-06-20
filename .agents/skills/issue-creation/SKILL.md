---
name: gentle-ai-issue-creation
description: "Create GitHub issues with templates — bug reports, feature requests, triage workflow"
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
triggers: "Creating GitHub issues (bug/feature), helping contributors file issues, triaging as maintainer"
---
## RULES
1. Blank issues disabled — MUST use template
2. Every issue gets `status:needs-review` on creation
3. Maintainer MUST add `status:approved` before PR
4. Questions → Discussions, not issues
## WORKFLOW
Search duplicates → choose template → fill required fields → check pre-flight boxes → submit (gets `status:needs-review`) → maintainer adds `status:approved` → open PR linking issue
## BUG REPORT
Template: `.github/ISSUE_TEMPLATE/bug_report.yml` — auto-labels: `bug`, `status:needs-review`
**Required**: Pre-flight (no dup + approval understood) · Description · Steps · Expected vs actual · OS + Agent + Shell
**Optional**: Logs · Screenshots · Workarounds
## FEATURE REQUEST
Template: `.github/ISSUE_TEMPLATE/feature_request.yml` — auto-labels: `enhancement`, `status:needs-review`
**Required**: Pre-flight · Problem · Proposed solution · Affected area (Scripts/Skills/Examples/Docs/CI/Other)
**Optional**: Alternatives · Mockups
## LABELS
Auto: Bug→`bug`,`status:needs-review` · Feature→`enhancement`,`status:needs-review` | Maintainer: `status:approved` · `priority:high/medium/low`
## COMMANDS
```bash
gh issue list --search "keyword"                                                    # search duplicates
gh issue create --template "bug_report.yml" --title "fix(scope): description"         # bug
gh issue create --template "feature_request.yml" --title "feat(scope): description"   # feature
gh issue edit <number> --add-label "status:approved"                                  # approve
gh issue edit <number> --add-label "priority:high"                                    # priority
```
