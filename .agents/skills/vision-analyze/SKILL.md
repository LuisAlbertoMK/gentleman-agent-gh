---
name: vision-analyze
description: "Local vision analysis — screenshots, UI review, error detection via Ollama. Zero cost, 100% local. NOT visual regression — for Playwright VRT use visual-testing."
triggers: [screenshot, capture, vision, analyze-ui, visual-review, captura, analizar-imagen]
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
