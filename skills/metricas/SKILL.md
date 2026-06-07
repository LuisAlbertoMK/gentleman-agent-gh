---
name: metricas
description: >
  On-demand before/after comparison w/ % improvement.
  Trigger: "metricas", "métricas", "comparar", "mejora", "delta", "token", "tokenizar".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.2", changelog: "1.1->1.2 (sprint 1: 85->57 lines, -32.9%, removed Anti-patterns table duplicate)"
---

## Flow
1. Capture baseline (before)
2. Apply change
3. Capture new state (after)
4. Display: **Before | After | Δ | Δ%** (green ↑, red ↓, — if no change)

## Two modes
| Mode | Usage |
|------|-------|
| **Git diff** | `metricas` → compare HEAD vs main (or last bookmark) |
| **Bookmark** | `metricas init` → work → `metricas show` |

## Metric dimensions
| Metric | Source | Direction |
|--------|--------|-----------|
| Files | `git diff --stat` | context |
| Lines ± | `git diff --shortstat` | ↓ refactors |
| Tests pass | `go test` / `npm test` / `pytest` | ↑ |
| Coverage % | `-cover` / `--coverage` / `--cov` | ↑ |
| Lint errs | `go vet` / `eslint` / `flake8` | ↓ |
| Compile errs | build output | ↓ |
| Complexity | `gocyclo` / `lizard` | ↓ |
| Exec time | `time cmd` / benchmark | ↓ |
| File count | `git ls-files` / `Get-ChildItem` | ↓ |

## Tokenization dimension (text/UI/docs)
3 tiers — auto-select best available:

| Tier | Method | Accuracy | Dep |
|------|--------|----------|-----|
| 1 — Words | `Split()` / `wc -w` | Low (~2x over) | 0 |
| 2 — Chars/3.5 | `Length` / heuristic | Med (±20%) | 0 |
| 3 — tiktoken | `cl100k_base` encode | High (±1-2) | python |

**Heuristic**: chars/3.5 works for Spanish natural lang. UNDERestimates on symbols (`/`, `-`, `.`).
**Key finding**: word count OVERestimates compression 2x vs real tokens. Palabras -66.7% vs Tokens -36.4%.

Usage: `metricas token "antes" "después"` | `metricas token file1 file2` | `metricas token` (vs bookmark)
Script: `assets/tokenize.ps1` — `powershell -File assets/tokenize.ps1 "v" "c"` · `pip install tiktoken` for Tier 3

## Bookmark
`.metricas/bookmark.json`: `{ "version": 1, "git_ref": "...", "timestamp": "...", "metrics": {...} }`
Corrupt → warn "Bookmark corrupted, starting fresh" → delete + re-init
Commands: `metricas clear` / `metricas list`

## Auto-detect project
- `go.mod` → Go: `go test -cover`, `go vet`
- `package.json` → Node: `npm test`, `eslint`
- `pyproject.toml` / `requirements.txt` → Python: `pytest`, `flake8`
- Otherwise → git metrics only

## Rules
1. Show ALL 4 cols: Before / After / Δ / Δ%
2. Δ = After - Before. Δ% = Δ/Before × 100. Before=0 → "new" not ∞
3. Coverage Δ% = absolute pp change
4. Verify EACH metric with tool output. No self-assessment
5. No bookmark + no git base → ask user what to compare
6. Anti-pattern: claim without evidence · unrelated baselines · skip "too complex" · Δ% without absolute
