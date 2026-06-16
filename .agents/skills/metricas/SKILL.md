---
name: metricas
description: "On-demand before/after comparison with delta and % improvement — git diff or bookmark mode, tokenization, multi-language auto-detect"
triggers: "Metricas, before/after, % improvement, tokenization, delta"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.3"
  changelog: "1.2->1.3 (sprint 5: 67->58 lines
---

On-demand before/after comparison w/ % improvement.Trigger: "metricas", "mÃ©tricas", "comparar", "mejora", "delta", "token", "tokenizar".
## Flow1. Capture baseline (before) â†’ 2. Apply change â†’ 3. Capture (after)4. Display: **Before | After | Î” | Î”%** (greenâ†‘ redâ†“ â€” if 0)
## Two modes| Mode | Usage ||------|-------|| **Git diff** | `metricas` â†’ compare HEAD vs main (or last bookmark) || **Bookmark** | `metricas init` â†’ work â†’ `metricas show` |
## Metrics| Metric | Source | Direction ||--------|--------|-----------|| Files | `git diff --stat` | ctx || Lines Â± | `git diff --shortstat` | â†“ refactor || Tests pass | `go test`/`npm test`/`pytest` | â†‘ || Coverage % | `-cover`/`--coverage`/`--cov` | â†‘ || Lint errs | `go vet`/`eslint`/`flake8` | â†“ || Compile errs | build output | â†“ || Complexity | `gocyclo`/`lizard` | â†“ || Exec time | `time cmd`/benchmark | â†“ || File count | `git ls-files`/`Get-ChildItem` | â†“ |
## Tokenization (text/UI/docs)| Tier | Method | Accuracy | Dep ||------|--------|----------|-----|| 1 | `Split()` / `wc -w` | Low (~2x over) | 0 || 2 | `Length`/heuristic (chars/3.5) | Med (Â±20%) | 0 || 3 | `tiktoken cl100k_base` | High (Â±1-2) | python |**Heuristic**: chars/3.5 works for Spanish. UNDERestimates symbols (`/`, `-`, `.`).**Key finding**: word count OVERestimates compression 2x vs real tokens (-66.7% words vs -36.4% tokens).Usage: `metricas token "antes" "despuÃ©s"` | `metricas token file1 file2` | `metricas token` (vs bookmark)Script: `assets/tokenize.ps1` â€” `powershell -File assets/tokenize.ps1 "v" "c"`
## Bookmark`.metricas/bookmark.json`: `{version, git_ref, timestamp, metrics}`Corrupt â†’ warn + delete/re-init. Commands: `metricas clear` / `metricas list`
## Auto-detect- `go.mod` â†’ Go: `go test -cover`, `go vet`- `package.json` â†’ Node: `npm test`, `eslint`- `pyproject.toml`/`requirements.txt` â†’ Python: `pytest`, `flake8`- Otherwise â†’ git metrics only
## Rules1. Show ALL 4 cols: Before / After / Î” / Î”%2. Î” = After - Before. Î”% = Î”/Before Ã— 100. Before=0 â†’ "new" not âˆž3. Coverage Î”% = absolute pp change4. Verify EACH metric with tool output. No self-assessment5. No bookmark + no git base â†’ ask user6. Anti-pattern: claim w/o evidence Â· unrelated baselines Â· skip "too complex" Â· Î”% w/o absolute
