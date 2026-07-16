---
name: vision-analyze
description: "Local vision analysis — screenshots, UI review, error detection via Ollama. Zero cost, 100% local."
triggers: [screenshot, capture, vision, analyze-ui, visual-review, captura, analizar-imagen]
---

# Vision Analyze — Local Screenshot Analysis

## Setup (This Machine)
1. **Ollama installed**: `$env:USERPROFILE\scoop\apps\ollama\current\ollama.exe`
2. **Models pulled**: `moondream:latest` (1.7GB) + `llava:7b` (4.7GB)
3. **Server**: `ollama serve` (default: 127.0.0.1:11434)
4. **Playwright**: installed in project `node_modules` (dev dependency)
5. **PowerShell alias**: `ap` function in `$PROFILE` (see Usage below)

### Verify Setup
```powershell
# Check Ollama running
Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/version"

# List available models
& "$env:USERPROFILE\scoop\apps\ollama\current\ollama.exe" list
```

## Usage

### Playwright + Ollama (recommended — automated page capture)
```powershell
# Auto-select model by RAM + capture + analyze
node scripts/analyze-page.js http://localhost:4200 --mode ui

# Force a specific model (overrides RAM check)
node scripts/analyze-page.js http://localhost:4200 --model llava:7b

# Capture only (no analysis)
node scripts/analyze-page.js http://localhost:4200 --no-analysis -o screenshot.png

# Full page capture
node scripts/analyze-page.js http://localhost:5173 --full --mode design
```

### PowerShell alias `ap` (from any directory)
```powershell
# Must restart terminal or . $PROFILE after profile edit
ap http://localhost:4200              # auto model + ui mode
ap http://localhost:4200 -Mode error  # error mode
ap http://localhost:4200 -NoAnalysis  # capture only
```

### PowerShell — Capture desktop screenshot + Analyze
```powershell
# Auto-capture desktop screenshot + analyze (error mode)
& "$env:GENTLEMAN_AGENT_ROOT\scripts\analyze-screenshot.ps1" -Mode error -SaveScreenshot

# Analyze existing image
& "$env:GENTLEMAN_AGENT_ROOT\scripts\analyze-screenshot.ps1" -ImagePath "C:\path\to\image.png" -Mode ui

# Compare before/after
& "$env:GENTLEMAN_AGENT_ROOT\scripts\analyze-screenshot.ps1" -ImagePath "before.png" -Compare "after.png"
```

### Fallback (No Ollama)
Use `Read` tool to view image directly, then analyze visually.

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
| ≥2GB | moondream:latest | 1.7GB | ~75-90s | Basic — general description |
| ≥8GB | llava:7b | 4.7GB | ~70-224s | Good — detailed UI analysis |
| ≥10GB | qwen3-vl:8b | 5GB | ~40s | Very good (not installed) |

**Auto-select**: script checks `os.freemem()` and picks the largest model that fits.
**Manual override**: `--model llava:7b` forces a specific model regardless of RAM.

### Gotcha: llava:7b + low RAM
llava:7b needs ~8GB FREE (model + inference overhead). If RAM < 8GB free, it swap-thrashes
and takes 200s+ instead of ~70s. The script auto-selects moondream in this case. Force with
`--model llava:7b` only if you know what you're doing.

## Integration
- **Code Review**: capture UI → analyze → feed to code-review-agent
- **Self-Improvement**: before/after comparison → score delta
- **External Audit**: production screenshots → accessibility analysis

## Output
```json
{"mode":"ui","model":"moondream","analysis":"...","elapsed_seconds":75.9}
```

## Security
100% local via 127.0.0.1:11434. No external API calls. No data leaves machine.
