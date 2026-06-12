---
name: sdd-init
description: >
  sdd-init skill
triggers: "SDD init, bootstrap"
  Trigger: "sdd init", "openspec init".
license: MIT
metadata: author: gentleman-vMK, version: "3.2"
---

## DETECT
- **Stack**: package.json/go.mod/pyproject.toml
- **Test**: vitest/jest/go test/pytest
- **Layers**: Unit/Integration/E2E
- **Coverage**: --coverage/-cover/pytest-cov
- **Quality**: eslint/ruff/golangci-lint (lint) · tsc/mypy/go vet (types) · prettier/black (fmt)

## TDD MODE
Priority: (1) system `strict-tdd-mode` · (2) openspec/config.yaml · (3) runner exists?→true · (4) no runner→false

## FILES (openspec)
```
openspec/ → config.yaml · specs/ (source) · changes/archive/ (done)
```

## CONFIG
```yaml
schema: spec-driven
context: Tech {stack} | Arch {patterns} | Test {framework} | Style {lint}
strict_tdd: {true/false}
```

## SKILL REGISTRY
Scan: ~/.config/opencode/skills/*/, ~/.claude/skills/, project skills/
Skip: sdd-*, _shared, skill-registry
Write: `.atl/skill-registry.md` + `mem_save`

## STEPS
1. Detect ctx (stack, conventions, test)
2. Resolve TDD mode per priority
3. Init dirs (openspec)
4. Generate config
5. Persist testing caps → engram/config.yaml
6. Build skill registry
7. Persist project ctx → engram/config
8. Return summary

## RETURN
```
SDD INIT | Project: {name} | Stack: {detected} | Mode: {engram/openspec/hybrid/none}
Strict TDD: {enabled/disabled}
Caps: {runner, layers, coverage, quality tools}
Saved: {engram IDs / paths}
```

