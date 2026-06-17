---
name: sdd-init
description: "Bootstrap SDD project context — detect stack, init config structure, build skill registry, and persist testing capabilities"
triggers: "SDD init, bootstrap"
license: MIT
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "3.2"
---

Trigger: "sdd init", "openspec init".
## DETECT- **Stack**: package.json/go.mod/pyproject.toml- **Test**: vitest/jest/go test/pytest- **Layers**: Unit/Integration/E2E- **Coverage**: --coverage/-cover/pytest-cov- **Quality**: eslint/ruff/golangci-lint (lint) · tsc/mypy/go vet (types) · prettier/black (fmt)
## TDD MODEPriority: (1) system `strict-tdd-mode` · (2) openspec/config.yaml · (3) runner exists?→true · (4) no runner→false
## FILES (openspec)
```openspec/ → config.yaml · specs/ (source) · changes/archive/ (done)```
## CONFIG
```yamlschema: spec-drivencontext: Tech {stack} | Arch {patterns} | Test {framework} | Style {lint}strict_tdd: {true/false}```
## SKILL REGISTRYScan: ~/.config/opencode/skills/*/, ~/.claude/skills/, project skills/Skip: sdd-*, _shared, skill-registryWrite: `.atl/skill-registry.md` + `mem_save`
## STEPS1. Detect ctx (stack, conventions, test)2. Resolve TDD mode per priority3. Init dirs (openspec)4. Generate config5. Persist testing caps → engram/config.yaml6. Build skill registry7. Persist project ctx → engram/config8. Return summary
## RETURN
```SDD INIT | Project: {name} | Stack: {detected} | Mode: {engram/openspec/hybrid/none}Strict TDD: {enabled/disabled}Caps: {runner, layers, coverage, quality tools}Saved: {engram IDs / paths}```
