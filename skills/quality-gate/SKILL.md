---
name: quality-gate
description: >  quality-gate skill
triggers: "Quality gate, pre-commit"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

Trigger: Before any "git commit", "git push", "gh pr create".
## WhenBefore `git commit` Â· `git push` Â· `gh pr create` â€” MUST run BEFORE these commands.
## Gates (ALL must pass)
### 1. TDD Gate â€” tests MUST passDetect runner: go.modâ†’`go test`, package.jsonâ†’`npm/pnpm/yarn/bun test`, Cargo.tomlâ†’`cargo test`, pyproject.tomlâ†’`pytest`.Fail â†’ DO NOT commit. Report file:line:error. Fix or ask user.
### 2. Secrets Scan â€” diff MUST be cleanScan staged diff: `git diff --cached` for patterns:
```(api[_-]?key|secret|token|password|credential|private[_-]?key|-----BEGIN)\b[A-Za-z0-9_-]{20,}\b\b(?:AKIA|ASIA)[A-Z0-9]{16}\bghp_[A-Za-z0-9]{36,}\b```Match â†’ BLOCK commit. Report file:line. NEVER commit secrets.
### 3. Conventional Commit â€” message MUST be validRegex: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`Invalid â†’ BLOCK. Show format + example.
## Decision Tree
```Tests fail?â”œâ”€â”€ Pre-existing (not your changes)? â†’ report, allow ONLY with user OKâ””â”€â”€ New failures? â†’ fix or revert â†’ re-runSecret found?â”œâ”€â”€ False positive (test data)? â†’ allow with user OKâ””â”€â”€ Real secret? â†’ remove from code â†’ use env/vault â†’ re-scanCommit invalid? â†’ Show: feat(scope): desc | fix(scope): desc | chore: desc```
## Commands
```bashgo test ./...                    # Gonpm test / pnpm test / yarn test # Nodecargo test                       # Rustpytest                           # Pythongit diff --cached | Select-String -Pattern '(api[_-]?key|secret|token|-----BEGIN)'echo "{message}" | Select-String -Pattern '^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+'```
