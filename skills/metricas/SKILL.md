---
name: metricas
description: >
  On-demand before/after comparison w/ % improvement.
  Trigger: "metricas", "métricas", "comparar", "mejora", "delta", "token", "tokenizar".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.3", changelog: "1.2->1.3 (sprint 5: 67->58 lines, -13.4%, tightened tables)"
---

## Flow
1. Capture baseline (before) → 2. Apply change → 3. Capture (after)
4. Display: **Before | After | Δ | Δ%** (green↑ red↓ — if 0)

## Two modes
| Mode | Usage |
|------|-------|
| **Git diff** | `metricas` → compare HEAD vs main (or last bookmark) |
| **Bookmark** | `metricas init` → work → `metricas show` |

## Metrics
| Metric | Source | Direction |
|--------|--------|-----------|
| Files | `git diff --stat` | ctx |
| Lines ± | `git diff --shortstat` | ↓ refactor |
| Tests pass | `go test`/`npm test`/`pytest` | ↑ |
| Coverage % | `-cover`/`--coverage`/`--cov` | ↑ |
| Lint errs | `go vet`/`eslint`/`flake8` | ↓ |
| Compile errs | build output | ↓ |
| Complexity | `gocyclo`/`lizard` | ↓ |
| Exec time | `time cmd`/benchmark | ↓ |
| File count | `git ls-files`/`Get-ChildItem` | ↓ |

## Tokenization (text/UI/docs)

| Tier | Method | Accuracy | Dep |
|------|--------|----------|-----|
| 1 | `Split()` / `wc -w` | Low (~2x over) | 0 |
| 2 | `Length`/heuristic (chars/3.5) | Med (±20%) | 0 |
| 3 | `tiktoken cl100k_base` | High (±1-2) | python |

**Heuristic**: chars/3.5 works for Spanish. UNDERestimates symbols (`/`, `-`, `.`).
**Key finding**: word count OVERestimates compression 2x vs real tokens (-66.7% words vs -36.4% tokens).
Usage: `metricas token "antes" "después"` | `metricas token file1 file2` | `metricas token` (vs bookmark)
Script: `assets/tokenize.ps1` — `powershell -File assets/tokenize.ps1 "v" "c"`

## Bookmark
`.metricas/bookmark.json`: `{version, git_ref, timestamp, metrics}`
Corrupt → warn + delete/re-init. Commands: `metricas clear` / `metricas list`

## Auto-detect
- `go.mod` → Go: `go test -cover`, `go vet`
- `package.json` → Node: `npm test`, `eslint`
- `pyproject.toml`/`requirements.txt` → Python: `pytest`, `flake8`
- Otherwise → git metrics only

## Rules
1. Show ALL 4 cols: Before / After / Δ / Δ%
2. Δ = After - Before. Δ% = Δ/Before × 100. Before=0 → "new" not ∞
3. Coverage Δ% = absolute pp change
4. Verify EACH metric with tool output. No self-assessment
5. No bookmark + no git base → ask user
6. Anti-pattern: claim w/o evidence · unrelated baselines · skip "too complex" · Δ% w/o absolute
