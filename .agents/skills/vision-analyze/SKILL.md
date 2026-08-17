---
name: vision-analyze
description: "Local vision analysis - screenshots, UI review, error detection via Ollama. 100% local. NOT visual regression."
triggers: [capture, vision, analyze-ui, visual-review, captura, analizar-imagen]
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1036
---

## When to Use
Local vision analysis — screenshots, UI review, error detect


# Vision Analyze — Local Screenshot Analysis

## Setup
1. **Ollama**: `$env:USERPROFILE\scoop\apps\ollama\current\ollama.exe`
2. **Models**: `moondream:latest` (1.7GB) + `llava:7b` (4.7GB)
3. **Server**: `ollama serve` (127.0.0.1:11434)
4. **Playwright**: installed in project `node_modules`
5. **Alias**: `ap` function in `$PROFILE`

### Verify
```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/version"
& "$env:USERPROFILE\scoop\apps\ollama\current\ollama.exe" list
```

## Usage

### Playwright + Ollama (recommended)
```powershell
node scripts/analyze-page.js http://localhost:4200 --mode ui
node scripts/analyze-page.js http://localhost:4200 --model llava:7b
node scripts/analyze-page.js http://localhost:4200 --no-analysis -o screenshot.png
```

### PowerShell alias `ap`
```powershell
ap http://localhost:4200              # auto model + ui mode
ap http://localhost:4200 -Mode error  # error mode
ap http://localhost:4200 -NoAnalysis  # capture only
```

### Desktop Screenshot + Analyze
```powershell
& "$env:GENTLEMAN_AGENT_ROOT\scripts\analyze-screenshot.ps1" -Mode error -SaveScreenshot
```

## Modes
| Mode | Use Case |
|------|----------|
| `ui` | Layout, alignment, contrast, broken components |
| `error` | Identify error messages, affected components |
| `design` | Spacing, typography, color, visual balance |
| `accessibility` | WCAG 2.2: contrast, touch targets, focus |
| `performance` | CLS, missing images, loading indicators |

## Model Selection (RAM-aware auto)
| Free RAM | Model | Size | Speed | Quality |
|----------|-------|------|-------|---------|
| ≥2GB | moondream:latest | 1.7GB | ~75-90s | Basic |
| ≥8GB | llava:7b | 4.7GB | ~70-224s | Good |

**Auto-select**: script checks `os.freemem()` and picks largest model that fits.
**Override**: `--model llava:7b` forces specific model.

## Integration
- **Code Review**: capture UI → analyze → feed to code-review-agent
- **Self-Improvement**: before/after comparison → score delta
- **External Audit**: production screenshots → accessibility analysis

## Security
100% local via 127.0.0.1:11434. No external API calls.

## Hard Rules
- NEVER use for visual regression / pixel diffing — that is `visual-testing` (`toHaveScreenshot`); Ollama is slow (~75-224s) and non-deterministic
- NEVER force `--model llava:7b` with <8GB free RAM — RAM-aware auto-select exists to prevent OOM
- 100% local ONLY (127.0.0.1:11434) — never route screenshots through external APIs (data leak)
- Verify server (`/api/version`) + models (`ollama list`) before any run (Setup → Verify)

## Output
`VISION:<target>—<date> MODE:[ui|error|design|a11y|perf] MODEL:<name> ISSUES:<n> TOP:<issue> VERIFY:[screenshot|ollama]→<ok/fail>`

---

## Examples

### Example 1: UI Review of a Local App

**Trigger**: `analyze-ui` (frontmatter triggers: screenshot, analyze-ui, visual-review, captura, analizar-imagen)

```powershell
# Alias `ap` = Playwright capture + Ollama analysis (Setup step 5)
ap http://localhost:4200 -Mode ui
# RAM-aware auto-select: moondream (≥2GB free) / llava:7b (≥8GB free)
```

**Expected output**:

```
[playwright] captured http://localhost:4200 (1440x900) 1.2s
[ollama] model=moondream:latest 92s
[vision] ui: layout OK · contrast OK · 1 issue: hero carousel broken
```

**Result**: issue fed to `code-review-agent` (Integration) — 100% local, no external API (Security).

## Testing

1. **Server up** — before any run:
   ```powershell
   Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/version"
   ```
   Expected: `{"version":"0.x.x"}` JSON, no error.

2. **Models present** — `& "$env:USERPROFILE\scoop\apps\ollama\current\ollama.exe" list`
   Expected: `moondream:latest` and `llava:7b` listed.

3. **Capture-only path** — `ap http://localhost:4200 -NoAnalysis`
   Expected: `screenshot.png` created with NO Ollama call (no ~75-224s wait).


## Cross-Refs: visual-testing | performance | accessibility | code-review-agent | self-improvement
## Anti-Patterns

- **Use it for pixel diffing / visual regression** — that is `visual-testing`'s job (`toHaveScreenshot`); Ollama description is slow (~75-224s) and non-deterministic, not a diff.
- **Force `--model llava:7b` with <8GB free RAM** — model selection is RAM-aware by design; forcing an oversized model OOMs the analysis.
- **Route screenshots through external APIs** — the skill is 100% local (127.0.0.1:11434); external calls leak UI/product data for zero benefit.
