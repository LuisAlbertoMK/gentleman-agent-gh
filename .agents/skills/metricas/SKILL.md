---
name: metricas
description: "On-demand before/after comparison with delta and % improvement — git diff or bookmark mode, tokenization, multi-language auto-detect. NOT self-evaluation — that's auto-metrics (!score/!metrics)."
triggers: "Metricas, before/after, % improvement, tokenization, delta"
---

## When to Use
On-demand before/after comparison with delta and % improveme

Before/after comparison w/ %. Trigger: "metricas", "métricas", "comparar", "mejora", "delta", "token", "tokenizar". (Nota: "!score"/"!metrics" → auto-metrics, no esta skill.)
## Flow: Capture baseline → Apply change → Capture after → Display: **Before | After | Δ | Δ%** (green↑ red↓)
## Modes: **Git diff** (HEAD vs main or bookmark) | **Bookmark** (`metricas init` → work → `metricas show`)
## Metrics
| Metric | Source | Direction |
|--------|--------|-----------|
| Files | `git diff --stat` | context |
| Lines ± | `git diff --shortstat` | ↓ refactor |
| Tests pass | `go test`/`npm test`/`pytest` | ↑ |
| Coverage % | `-cover`/`--coverage`/`--cov` | ↑ pp change |
| Lint errs | `go vet`/`eslint`/`flake8` | ↓ |
| Compile errs | build output | ↓ |
| Exec time | `time cmd`/benchmark | ↓ |
| File count | `git ls-files`/`Get-ChildItem` | ↓ |
## Tokenization
T1: `Split()`/`wc -w` (Low ~2x over, 0 dep) · T2: chars/3.5 heuristic (Med ±20%, 0 dep) · T3: `tiktoken cl100k_base` (High ±1-2, python)
Heuristic: chars/3.5 for Spanish. UNDERestimates symbols. Usage: `metricas token "antes" "después"` / `file1 file2` / (vs bookmark)
Script: `. agents/skills/metricas/assets/tokenize.ps1`
## Bookmark
`.metricas/bookmark.json`: `{version, git_ref, timestamp, metrics}`. Corrupt → warn + re-init. `clear` / `list`
## Auto-detect: `go.mod`→Go · `package.json`→Node · `pyproject.toml`→Python · else→git only
## Rules
1. Show ALL 4 cols: Before / After / Δ / Δ%
2. Δ = After - Before. Δ% = Δ/Before×100. Before=0 → "new"
3. Coverage Δ% = absolute pp change
4. Verify EACH metric with tool output. No self-assessment
5. No bookmark + no git base → ask user
6. Anti-pattern: claim w/o evidence · unrelated baselines · skip "too complex" · Δ% w/o absolute

## Anti-Patterns
Claim improvement without evidence · Compare unrelated baselines · Skip metrics because "too complex" · Report Δ% without absolute values · Use before=0 without "new" marker

## Refs
auto-metrics · performance-tracker · karpathy-loop · lean-context · quality-gate
