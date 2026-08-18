---
name: issue-creation
description: "Create Gentle AI issues with issue-first checks."
triggers: "create issue, GitHub issue, bug report, feature request, open issue, issue creation, report bug"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
Bug in `gga`·Feature/enhancement·Gentleman-Programming/gentle-ai·Triaging

## Rules
1.Blank issues❌—MUST use `.github/ISSUE_TEMPLATE/bug_report.yml` or `feature_request.yml`
2.`status:needs-review` auto—do NOT add manually
3.`status:approved` REQUIRED before ANY PR
4.Questions→[Discussions](https://github.com/Gentleman-Programming/gentle-ai/discussions)
5.No `Co-Authored-By`

## Workflow
1.Search dupes 2.Choose template 3.Fill required 4.Submit→`status:needs-review`(auto) 5.Wait `status:approved` 6.PR with `Closes #<N>`

## Bug Report
Template:`.github/ISSUE_TEMPLATE/bug_report.yml` Labels:`bug`,`status:needs-review`
Areas:CLI·TUI·Installation·Agent Detection·System Detection·Catalog/Steps·Docs·Other
Required:Pre-flight+Bug Desc+Steps+Expected vs Actual+gga version+OS+Agent/Client
Optional:Logs+Context

## Feature Request
Template:`.github/ISSUE_TEMPLATE/feature_request.yml` Labels:`enhancement`,`status:needs-review`
Required:Pre-flight+Area+Problem+Proposed Solution. Optional:Alternatives+Context

## Labels
Bug→`bug`+`needs-review`|Feature→`enhancement`+`needs-review`
Status:`needs-review`→`approved`→`in-progress`→`blocked`/`wont-fix`
Issue type:`bug`/`enhancement`. PR type:`type:bug`/`feature`/`docs`/`refactor`/`chore`/`breaking-change`
Priority:`critical`/`high`/`medium`/`low`
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/issue-creation/reference.md

---
