---
name: ci-cd
description: "CI/CD pipeline setup — GitHub Actions, local pre-push quality gate, auto-detect test runner, SDD spec coverage"
triggers: "CI/CD pipeline, GitHub Actions, quality gate"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.3"
  changelog: "1.3: enriched with monorepo/matrix/workflow_dispatch examples, multi-OS, edge cases"
  dependencies: [quality-gate]
---

Trigger: CI setup, failed PR checks, pipeline config.

## CI PIPELINE

```yaml
name: ci
on: [push, pull_request]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          # auto-detect test runner:
          # go.mod → go test, package.json → npm test, *.csproj → dotnet test
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

## EXAMPLE WORKFLOW

### Single project (Go)
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

### Monorepo with matrix
```yaml
name: ci
on: [push, pull_request, workflow_dispatch]
jobs:
  test:
    strategy:
      matrix:
        dir: [api, web, worker]
        os: [ubuntu-latest, windows-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Test ${{ matrix.dir }}
        working-directory: ${{ matrix.dir }}
        run: |
          if (Test-Path go.mod) { go test ./... -race }
          elseif (Test-Path package.json) { npm test }
          else { echo "No test runner detected in ${{ matrix.dir }}" }
```

### Multi-OS with workflow_dispatch inputs
```yaml
name: ci
on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:
    inputs:
      skip_tests:
        description: "Skip test step"
        type: boolean
        default: false
jobs:
  quality:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/quality-gate.ps1
      - if: ${{ !inputs.skip_tests }}
        run: go test ./... -race -cover
      - run: echo "CI passed on ${{ runner.os }}"
```

## EDGE CASES
- No test files → skip test step, note in CI output: `"No test files found — skip"` (not a failure)
- Monorepo → detect subproject test runners per directory; fallback to `echo "no runner"` per subproject
- SDD mode requires specs dir exists → if missing, skip spec coverage check with warning
- `workflow_dispatch` with skip_tests=true → lint+quality only, no test run
- Matrix partially fails → report per-entry: `"api/windows: PASS | web/linux: FAIL | web/windows: PASS"`
- No `go.mod` or `package.json` → `"No recognized project detected. Run `project-mapper` first"`
- Tests timeout (racy tests) → `"Test timeout on ${{ matrix.os }}. Check for deadlocks"` — use --timeout 5m
- Coverage drops below threshold → fail with `"Coverage 34% < threshold 50%"`
- Self-hosted runner unavailable → `"Runner offline. Check runner status or fall back to ubuntu-latest"`
- Branch protection required but not set → warn: `"PR merge blocked — branch protection requires CI pass"`

## Refs
quality-gate · triple-verify · security-scanner · project-mapper · execution-mode · infra-audit

## Anti-Patterns
Run quality gate after tests · Block on lint · Ignore monorepo config · Hardcode runner instead of auto-detect · Hardcode OS · Skip coverage threshold · Use push-only triggers for PR workflows
