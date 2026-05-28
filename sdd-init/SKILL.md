---
name: sdd-init
description: > Initialize SDD: detect stack/testing, bootstrap persistence.
  Trigger: "sdd init", "openspec init".
license: MIT
metadata: author: gentleman-programming, version: "3.1"
---

## Context Detection
- Stack: package.json/go.mod/pyproject.toml
- Test runner: vitest/jest/go test/pytest
- Layers: Unit/Integration/E2E · Coverage: --coverage/-cover/pytest-cov
- Quality: eslint/ruff/golangci-lint (lint) · tsc/mypy/go vet (types) · prettier/black (fmt)

## TDD Mode
Priority: (1) system prompt `strict-tdd-mode` marker → (2) openspec/config.yaml → (3) runner exists?→true → (4) no runner→false

## Files (openspec)
```
openspec/
├── config.yaml       ← project SDD config
├── specs/           ← source of truth
└── changes/archive/ ← completed
```

## Config
```yaml
schema: spec-driven
context: Tech {stack} | Arch {patterns} | Test {framework} | Style {lint}
strict_tdd: {true/false}
rules:
  proposal: [rollback, affected modules]
  specs: [Given/When/Then, RFC 2119]
  design: [seq diagrams, ADR]
  tasks: [phase grouping, 1-session]
  apply: [existing patterns, load skills]
  verify: [run tests, compare specs]
  archive: [warn destructive]
```

## Skill Registry
Scan: ~/.config/opencode/skills/*/, ~/.claude/skills/, project skills/
Skip: sdd-*, _shared, skill-registry
Write: `.atl/skill-registry.md` + `mem_save`

## Steps
1. Detect ctx → stack, conventions, testing
2. TDD mode → resolve per priority
3. Init dirs (openspec mode)
4. Generate config
5. Persist testing capabilities → engram/config.yaml
6. Build skill registry
7. Persist project ctx → engram/config
8. Return summary

## Return
```
SDD INIT | Project: {name} | Stack: {detected} | Mode: {engram/openspec/hybrid/none}
Strict TDD: {enabled/disabled}
Caps: {runner, layers, coverage, quality tools}
Saved: {engram IDs / paths}
```
