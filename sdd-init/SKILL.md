---
name: sdd-init
description: >
  Initialize SDD context: detect stack, conventions, testing, bootstrap persistence backend.
  Trigger: "sdd init", "iniciar sdd", "openspec init".
license: MIT
metadata:
  author: gentleman-programming
  version: "3.0"
---

## Purpose
Initialize SDD context. Detect project stack, conventions, testing capabilities. Bootstrap persistence backend. EXECUTOR — not orchestrator.

## Persistence Contract
- **engram**: NO `openspec/` dir. `mem_save(title: "sdd-init/{project}", topic_key: same, type: "architecture")` + testing-capabilities observation
- **openspec**: Run full bootstrap, write `openspec/config.yaml` + dir structure
- **hybrid**: BOTH — openspec bootstrap + engram persist
- **none**: Return context, no file ops

## Steps

### 1: Detect Project Context
Check: `package.json`, `go.mod`, `pyproject.toml`, CI configs, linters, architecture patterns.

### 2: Detect Testing
```
Test Runner → package.json/pyproject.toml/go.mod/Cargo.toml/Makefile → {framework, command}
Layers:
  Unit: test runner exists? → ✅
  Integration: @testing-library/httpx/httptest/WebApplicationFactory? → ✅
  E2E: playwright/cypress/selenium/chromedp? → ✅
Coverage: vitest/pytest-cov/go test -cover/coverlet → {command}
Quality: eslint/ruff/golangci-lint (linter), tsc/mypy/go vet (types), prettier/black/gofmt (format)
```

### 3: Resolve Strict TDD
Priority chain (first match wins):
1. System prompt / agent config `strict-tdd-mode` marker → enabled/disabled
2. `openspec/config.yaml` → `strict_tdd` field
3. Test runner detected? → `strict_tdd: true` (can do TDD)
4. No test runner → `strict_tdd: false`, note in summary

**No interactive questions.** User changes via TUI or config.

### 4: Init Persistence (openspec mode)
```
openspec/
├── config.yaml
├── specs/
└── changes/archive/
```

### 5: Generate Config (openspec)
```yaml
schema: spec-driven
context: |
  Tech stack: {detected}
  Architecture: {detected}
  Testing: {detected}
  Style: {detected}
strict_tdd: {true/false}
rules:
  proposal: [Include rollback plan, Identify affected modules]
  specs: [Given/When/Then, RFC 2119 keywords]
  design: [Sequence diagrams, ADR rationale]
  tasks: [Phase grouping, Hierarchical numbering, Small enough for one session]
  apply: [Follow existing patterns, Load relevant skills]
  verify: [Run tests, Compare vs spec scenarios]
  archive: [Warn on destructive deltas]
```

### 6: Persist Testing Capabilities
```
mem_save(title: "sdd/{project}/testing-capabilities", topic_key: same, type: "config")
Format:
  Strict TDD Mode: {enabled/disabled}
  Test Runner: {command, framework}
  Layers: Unit ✅/❌ | Integration ✅/❌ | E2E ✅/❌
  Coverage: {command} ✅/❌
  Quality: Linter ✅/❌ | Type checker ✅/❌ | Formatter ✅/❌
```
openspec/hybrid → also write as `testing:` section in `openspec/config.yaml`.

### 7: Build Skill Registry
Follow `skill-registry` SKILL.md: scan user + project skills, conventions, write `.atl/skill-registry.md`, save to engram.

### 8: Persist Project Context
engram/hybrid → `mem_save(title: "sdd-init/{project}", topic_key: same, type: "architecture")`
openspec/hybrid → config already written in Step 5.

### 9: Return Summary
```
## SDD Initialized
**Project**: {name} | **Stack**: {detected} | **Persistence**: {mode}
**Strict TDD Mode**: {enabled ✅ / disabled ❌ / unavailable}

### Testing Capabilities
| Capability | Status |
| Test Runner | {tool} ✅/❌ |
| Unit | ✅/❌ | Integration | {tool} ✅/❌ |
| E2E | {tool} ✅/❌ | Coverage | ✅/❌ |
| Linter | {tool} ✅/❌ | Type Checker | {tool} ✅/❌ |

### Context Saved
{Engram IDs / File paths}

### ⚠️ Engram Limitations
Solo dev, fast iteration. No iteration history. Not shareable. Partial audit trail.
For teams: use openspec or hybrid.

### Next
Ready for /sdd-explore or /sdd-new.
```

## Rules
- NO placeholder specs
- Detect real tech stack, don't guess
- Execute directly, not orchestrator behavior
- Existing `openspec/` → report + ask orchestrator if update
- Config context ≤10 lines
- Testing detection + persist: MANDATORY
- Return envelope: `status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`
