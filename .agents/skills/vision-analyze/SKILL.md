---
name: vision-analyze
description: "Local vision analysis — screenshots, UI review, error detection via Ollama. Zero cost, 100% local."
triggers: [screenshot, capture, vision, analyze-ui, visual-review, captura, analizar-imagen]
---

# Vision Analyze — Local Screenshot Analysis

## Setup (This Machine)
1. **Ollama installed**: `$env:USERPROFILE\scoop\apps\ollama\current\ollama.exe`
2. **Model pulled**: `moondream:latest` (1.7GB) — run `ollama pull moondream:latest`
3. **Server**: `ollama serve` (default: localhost:11434)

### Verify Setup
```powershell
# Check Ollama running
Invoke-RestMethod -Uri "http://localhost:11434/api/version"

# List available models
& "$env:USERPROFILE\scoop\apps\ollama\current\ollama.exe" list
```

## Usage

### PowerShell — Capture + Analyze
```powershell
# Auto-capture screenshot + analyze (error mode)
& "$env:GENTLEMAN_AGENT_ROOT\scripts\analyze-screenshot.ps1" -Mode error -SaveScreenshot

# Analyze existing image
& "$env:GENTLEMAN_AGENT_ROOT\scripts\analyze-screenshot.ps1" -ImagePath "C:\path\to\image.png" -Mode ui

# Compare before/after
& "$env:GENTLEMAN_AGENT_ROOT\scripts\analyze-screenshot.ps1" -ImagePath "before.png" -Compare "after.png"
```

### Quick Ollama API Test
```powershell
$body = @{ model = "moondream:latest"; prompt = "Describe this image"; stream = $false } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $body -ContentType "application/json"
```

### Python — Analyze Existing Images
```bash
# Single image analysis
py scripts/analyze-image.py screenshot.png --mode error

# Compare before/after
py scripts/analyze-image.py before.png after.png --compare

# Custom prompt
py scripts/analyze-image.py screenshot.png --prompt "What fonts are used?"

# JSON output (for programmatic use)
py scripts/analyze-image.py screenshot.png --mode ui --json
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

## Model Selection
| RAM | Model | Speed | Status |
|-----|-------|-------|--------|
| <4GB | moondream:latest | ~75s | ✅ Installed & tested |
| 8GB+ | llava:7b | ~5s | Not installed |
| 16GB+ | qwen3-vl:8b | ~10s | Not installed (slow download) |

## Integration
- **Code Review**: capture UI → analyze → feed to code-review-agent
- **Self-Improvement**: before/after comparison → score delta
- **External Audit**: production screenshots → accessibility analysis

## Output
```json
{"mode":"ui","model":"moondream","findings":[{"severity":"critical","category":"layout","description":"...","fix":"..."}]}
```

## Security
100% local via localhost:11434. No external API calls. No data leaves machine.
