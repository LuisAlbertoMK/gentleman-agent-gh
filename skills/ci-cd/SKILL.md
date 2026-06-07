---
name: ci-cd
description: > GitHub Actions CI + quality gate + tests + lint (#27).
  Trigger: CI setup, failed PR checks, pipeline config.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.1"
---

## CI PIPELINE
```yaml
name: ci
on: [push, pull_request]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |  # auto-detect test runner: go.mod → go test, package.json → npm test, *.csproj → dotnet test
          if (Test-Path go.mod) { go test ./... }
          elseif (Test-Path package.json) { npm test }
```

## RULES
Quality gate before tests (fail fast) · Tests on every push (catch regressions) · Lint advisory, not blocking · CI must pass before merge · PR checks include spec coverage if SDD

## LOCAL PRE-PUSH
1. Quality gate (secrets, commit format)
2. Tests (auto-detect runner)
3. Lint (if available)

## INTEGRATION
PR → CI → quality gate → tests → lint → merge if green
SDD mode: CI validates spec coverage (tests vs specs)
Auto-gen `.github/workflows/ci.yml` if missing
