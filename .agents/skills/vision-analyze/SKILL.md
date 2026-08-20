---
name: vision-analyze
description: "Local vision analysis - screenshots, UI review, error detection via Ollama. 100% local. NOT visual regression."
triggers: [capture, vision, analyze-ui, visual-review, captura, analizar-imagen]
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1036
---

## When to Use
Local vision analysis — screenshots, UI review, error detection.

## Setup
1. **Ollama**: `$env:USERPROFILE\scoop\apps\ollama\current\ollama.exe`. 2. **Models**: `moondream:latest` (1.7GB) + `llava:7b` (4.7GB). 3. **Server**: `ollama serve` (127.0.0.1:11434). 4. **Playwright**: project `node_modules`. 5. **Alias**: `ap` in `$PROFILE`.

### Verify
```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/version"
& "$env:USERPROFILE\scoop\apps\ollama\current\ollama.exe" list
```

## Usage
```powershell
node scripts/analyze-page.js http://localhost:4200 --mode ui
node scripts/analyze-page.js http://localhost:4200 --model llava:7b
node scripts/analyze-page.js http://localhost:4200 --no-analysis -o screenshot.png
ap http://localhost:4200              # alias: auto model + ui mode
ap http://localhost:4200 -Mode error  # error mode
ap http://localhost:4200 -NoAnalysis  # capture only
& "$env:GENTLEMAN_AGENT_ROOT\scripts\analyze-screenshot.ps1" -Mode error -SaveScreenshot  # desktop
```

## Modes
`ui` layout/alignment/contrast/broken components | `error` messages+affected components | `design` spacing/typography/color/balance | `accessibility` WCAG 2.2 contrast/touch/focus | `performance` CLS/missing images/loading.

## Model Selection (RAM-aware auto)
| Free RAM | Model | Size | Speed | Quality |
|---|---|---|---|---|
| ≥2GB | moondream:latest | 1.7GB | ~75-90s | Basic |
| ≥8GB | llava:7b | 4.7GB | ~70-224s | Good |

Auto: script checks `os.freemem()` → largest that fits. Override: `--model llava:7b`.

## Integration
Code Review: capture→analyze→code-review-agent · Self-Improvement: before/after score delta · External Audit: production screenshots → a11y.

## Security
100% local via 127.0.0.1:11434. No external API calls.

## Hard Rules
- NEVER for visual regression/pixel diffing — that is `visual-testing` (`toHaveScreenshot`); Ollama slow + non-deterministic
- NEVER force `--model llava:7b` with <8GB free RAM — RAM-aware auto-select prevents OOM
- 100% local ONLY — never route screenshots through external APIs (data leak)
- Verify server + models before any run

## Output
`VISION:<target>—<date> MODE:[ui|error|design|a11y|perf] MODEL:<name> ISSUES:<n> TOP:<issue> VERIFY:[screenshot|ollama]→<ok/fail>`

## Testing
1. Server up: `/api/version` → `{"version":"0.x.x"}`. 2. Models: `ollama list` → both listed. 3. Capture-only: `ap http://localhost:4200 -NoAnalysis` → screenshot.png, NO Ollama call.

## Cross-Refs: visual-testing | performance | accessibility | code-review-agent | self-improvement

## Anti-Patterns
Use for pixel diffing/regression (visual-testing's job) · Force llava:7b with <8GB RAM (OOM) · Route screenshots through external APIs (leak)