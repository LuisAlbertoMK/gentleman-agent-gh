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

Common protocol: `{file:sdd/references/sdd-phase-common.md}`

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

## EXAMPLE OUTPUT
```
SDD INIT | Project: my-api | Stack: Go 1.22 + Chi | Mode: engram
Strict TDD: enabled | Caps: go test, unit+integration, -cover, golangci-lint
```

## EDGE CASES
- No project files detected → manual mode, prompt user for stack
- Missing test runner → default to "no tests detected", strict TDD disabled
- Existing openspec/ dir → detect and note, don't overwrite
