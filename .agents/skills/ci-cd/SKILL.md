---
name: ci-cd
description: "CI/CD pipeline setup — GitHub Actions, local pre-push quality gate, auto-detect test runner, SDD spec coverage"
triggers: "CI/CD pipeline, GitHub Actions, quality gate"
---
## When to Use
CI setup, failed PR checks, pipeline config.

## Rules
Quality gate before tests(fail fast)·Tests on every push·Lint advisory·CI pass before merge·PR checks include spec coverage if SDD

## LOCAL PRE-PUSH: 1.Quality gate(secrets,commit format) 2.Tests(auto-detect) 3.Lint(if available)

## INTEGRATION: PR→CI→quality gate→tests→lint→merge if green. SDD:CI validates spec coverage. Auto-gen `.github/workflows/ci.yml` if missing.

## CI Pipeline
```yaml
name:ci on:[push,pull_request] jobs:quality{runs-on:ubuntu-latest steps:{uses:actions/checkout@v4;run:if(Test-Path go.mod){go test./...}elseif(Test-Path package.json){npm test}}}
```
## Single Project(Go): `go test ./... -race -cover`

## Monorepo
```yaml
strategy:{matrix:{dir:[api,web,worker],os:[ubuntu,windows]-latest}}
steps:{uses:actions/checkout@v4;working-directory:${{matrix.dir}};run:if(Test-Path go.mod){go test./...-race}elseif(Test-Path package.json){npm test}else{echo"No runner in ${{matrix.dir}}"}}
```

## Multi-OS with workflow_dispatch
```yaml
on:{push:{branches:[main]},pull_request,workflow_dispatch:{inputs:{skip_tests:{type:boolean,default:false}}}}
strategy:{matrix:{os:[ubuntu,windows,macos]-latest}}
steps:{uses:actions/checkout@v4;run:./scripts/quality-gate.ps1;if:${{!inputs.skip_tests}},run:go test./...-race-cover}
```

## Edge Cases
No tests→skip "No test files—skip"(not fail)|Monorepo→detect per dir;fallback"no runner"|SDD missing specs dir→skip coverage check|skip_tests→lint+quality only|Matrix partial→"api/windows:PASS|web/linux:FAIL|..."|No go.mod/pkg.json→"Run `project-mapper` first"|Timeout→"Check deadlocks"—use--timeout 5m|Coverage below→"Coverage X%<threshold Y%"|Runner offline→"Check status/fallback to ubuntu-latest"|Branch protection→"PR merge blocked—requires CI pass"

## Refs
quality-gate·triple-verify·security-scanner·project-mapper·execution-mode·infra-audit

## Anti-Patterns
Gate after tests·Block lint·Ignore monorepo·Hardcode runner·Hardcode OS·Skip coverage·Push-only triggers
