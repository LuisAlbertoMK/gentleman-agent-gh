---
name: ci-cd
description: "CI/CD pipeline setup — GitHub Actions, local pre-push quality gate, auto-detect test runner, SDD spec coverage"
triggers: "CI/CD pipeline, GitHub Actions, quality gate"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

Trigger: CI setup, failed PR checks, pipeline config.
## CI PIPELINE
```yamlname: cion: [push, pull_request]jobs:  quality:    runs-on: ubuntu-latest    steps:      - uses: actions/checkout@v4      - run: |  # auto-detect test runner: go.mod â†’ go test, package.json â†’ npm test, *.csproj â†’ dotnet test          if (Test-Path go.mod) { go test ./... }          elseif (Test-Path package.json) { npm test }```
## RULESQuality gate before tests (fail fast) Â· Tests on every push (catch regressions) Â· Lint advisory, not blocking Â· CI must pass before merge Â· PR checks include spec coverage if SDD
## LOCAL PRE-PUSH1. Quality gate (secrets, commit format)2. Tests (auto-detect runner)3. Lint (if available)
## INTEGRATIONPR â†’ CI â†’ quality gate â†’ tests â†’ lint â†’ merge if greenSDD mode: CI validates spec coverage (tests vs specs)Auto-gen `.github/workflows/ci.yml` if missing
