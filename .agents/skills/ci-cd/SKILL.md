---
name: ci-cd
description: "CI/CD pipeline setup — GitHub Actions, local pre-push quality gate, auto-detect test runner, SDD spec coverage"
triggers: "CI/CD pipeline, GitHub Actions, quality gate"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.2"
  changelog: "1.2: declared dependency on quality-gate"
  dependencies: [quality-gate]
---

Trigger: CI setup, failed PR checks, pipeline config.
## CI PIPELINE
```yamlname: cion: [push, pull_request]jobs:  quality:    runs-on: ubuntu-latest    steps:      - uses: actions/checkout@v4      - run: |  # auto-detect test runner: go.mod → go test, package.json → npm test, *.csproj → dotnet test          if (Test-Path go.mod) { go test ./... }          elseif (Test-Path package.json) { npm test }```
## RULESQuality gate before tests (fail fast) · Tests on every push (catch regressions) · Lint advisory, not blocking · CI must pass before merge · PR checks include spec coverage if SDD
## LOCAL PRE-PUSH1. Quality gate (secrets, commit format)2. Tests (auto-detect runner)3. Lint (if available)
## INTEGRATIONPR → CI → quality gate → tests → lint → merge if greenSDD mode: CI validates spec coverage (tests vs specs)Auto-gen `.github/workflows/ci.yml` if missing
## EXAMPLE WORKFLOW
```yaml
name: ci
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: go test ./... -race -cover
```
## EDGE CASES
- No test files → skip test step, note in CI output
- Monorepo → detect subproject test runners per directory
- SDD mode requires specs dir exists — if missing, skip spec coverage check

## Refs
quality-gate · triple-verify · security-scanner · project-mapper · execution-mode

## Anti-Patterns
Run quality gate after tests · Block on lint · Ignore monorepo config · Hardcode runner instead of auto-detect
