---
name: gentle-ai-issue-creation
description: "Create GitHub issues with templates — bug reports, feature requests, triage workflow"
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## Use
Creating GitHub issues (bug/feature) · helping contributors file issues · triaging as maintainer.

## Rules
1. **Blank issues disabled** — MUST use template (bug_report.yml or feature_request.yml)
2. **Every issue gets `status:needs-review`** automatically on creation
3. **Maintainer MUST add `status:approved`** before any PR can be opened
4. **Questions → Discussions, not issues**

## Workflow
1. Search duplicates → choose template → fill all required fields → check pre-flight boxes → submit (gets `status:needs-review`) → maintainer adds `status:approved` → open PR linking this issue

## Bug Report
Template: `.github/ISSUE_TEMPLATE/bug_report.yml` — auto-labels: `bug`, `status:needs-review`

### Required
- Pre-flight: no duplicate + understands approval workflow
- Bug description · steps to reproduce · expected vs actual behavior
- OS (macOS/Linux/Windows/WSL) · Agent (Claude Code/OpenCode/Gemini CLI/Cursor/Windsurf/Codex/Other) · Shell (bash/zsh/fish/Other)

### Optional
Relevant logs · screenshots · workarounds

## Feature Request
Template: `.github/ISSUE_TEMPLATE/feature_request.yml` — auto-labels: `enhancement`, `status:needs-review`

### Required
- Pre-flight: no duplicate + understands approval workflow
- Problem description · proposed solution · affected area (Scripts/Skills/Examples/Docs/CI/Other)

### Optional
Alternatives considered · mockups/references

## Labels
| Stage | Labels |
|-------|--------|
| Auto on create | Bug: `bug`, `status:needs-review` · Feature: `enhancement`, `status:needs-review` |
| Maintainer | `status:approved` · `priority:high/medium/low` |

## Maintainer Workflow
Issue arrives with `status:needs-review` → review validity/scope/clarity → if YES: add `status:approved` · if NO: comment + close → contributor opens PR linking issue

## Commands
```bash
# Search duplicates
gh issue list --search "keyword"
# Create bug report
gh issue create --template "bug_report.yml" --title "fix(scope): description"
# Create feature request
gh issue create --template "feature_request.yml" --title "feat(scope): description"
# Approve
gh issue edit <number> --add-label "status:approved"
# Add priority
gh issue edit <number> --add-label "priority:high"
```
