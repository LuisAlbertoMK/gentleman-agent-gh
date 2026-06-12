---
name: issue-creation
description: >
  issue-creation skill
triggers: "Issue creation"
  Trigger: Creating GitHub issue, bug report, feature request.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

## RULES
- Blank issues disabled — template required
- status:needs-review auto
- status:approved → PR can open
- Questions → Discussions NOT issues

## TEMPLATES
Bug: steps to repro, expected/actual, logs, OS/agent/shell
Feature: problem, proposed solution, affected area

## WORKFLOW
1.Search duplicates
2.Choose template
3.Fill ALL required
4.Submit → needs-review auto
5.Wait status:approved
6.Open PR linking issue
