---
name: sdd-init
description: > Initialize SDD: detect stack/testing, bootstrap persistence.
  Trigger: "sdd init", "openspec init".
license: MIT
metadata: author: gentleman-programming, version: "3.0"
---

## CONTEXT
- Detect: package.json/go.mod/pyproject.toml, CI/linters, arch patterns
- Test runner: package.json→vitest/jest, go.mod→go test, pyproject.toml→pytest
- Layers: Unit/Integration/E2E · Coverage: vitest--coverage/pytest-cov/go test -cover
- Quality: eslint/ruff/golangci-lint (linter), tsc/mypy/go vet (types), prettier/black (format)

## TDD MODE
Priority: (1) system prompt `strict-tdd-mode` marker, (2) openspec/config.yaml, (3) test runner?→true, (4) no runner→false

## FILES (openspec)
```
openspec/
├── config.yaml        ← project SDD config
├── specs/           ← source of truth
└── changes/archive/  ← completed
```

## CONFIG
```yaml
schema: spec-driven
context: | Tech {stack} | Arch {patterns} | Testing {framework} | Style {lint}
strict_tdd: {true/false}
rules:
  proposal: [rollback, affected modules]
  specs: [Given/When/Then, RFC 2119]
  design: [seq diagrams, ADR]
  tasks: [phase grouping, hierarchical, 1-session]
  apply: [existing patterns, load skills]
  verify: [run tests, compare vs specs]
  archive: [warn destructive]
```

## SKILL REGISTRY
Scan: ~/.config/opencode/skills/*/, ~/.claude/skills/, projectskills/
Skip: sdd-*, _shared, skill-registry
Write: `.atl/skill-registry.md` + `mem_save` to engram

## STEPS
1. Detect ctx → stack, conventions, testing
2. TDD mode → resolve per priority chain
3. Init dirs (openspec mode)
4. Generate config
5. Persist testing capabilities → engram/config.yaml
6. Build skill registry
7. Persist project ctx → engram/config
8. Return summary

## RETURN
```
SDD INIT
Project: {name} | Stack: {detected} | Mode: {engram/openspec/hybrid/none}
Strict TDD: {enabled/disabled/unavailable}
Caps: {table of test runner, layers, coverage, quality tools}
Saved: {engram IDs / file paths}
```
ENT: engram-only=no openspec/ | openspec=write dirs | hybrid=both | none=no file ops