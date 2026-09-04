---
name: ci-cd
description: "CI/CD pipeline setup — GitHub Actions, local pre-push quality gate, auto-detect test runner, SDD spec coverage"
triggers: "CI/CD pipeline, GitHub Actions, quality gate"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2886
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

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "pipeline sin auto-detect de test runner" | Pipeline hardcode go test/npm sin Test-Path | Verificar CI Pipeline: if(Test-Path go.mod){go test ./...} elseif(Test-Path package.json){npm test} auto-detect |
| "specs SDD sin cobertura en CI" | PR checks sin spec coverage si SDD | Verificar Rules: SDD CI valida spec coverage + PR→CI→quality gate→tests→lint + Integration SDD file:line |
| "gate después de tests o push-only" | Gate después de tests o triggers solo push | Verificar LOCAL PRE-PUSH: quality gate before tests + on:[push,pull_request] + workflow_dispatch + Lint advisory |


## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: quality-gate | triple-verify | security-scanner | project-mapper | execution-mode | infra-audit | testing-strategy


## Anti-Patterns
Gate after tests·Block lint·Ignore monorepo·Hardcode runner·Hardcode OS·Skip coverage·Push-only triggers
## Reference
> docs/skills/ci-cd/reference.md

