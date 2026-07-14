---
name: vision-analyze
description: "Local vision analysis — screenshots, UI review, error detection via Ollama. Zero cost, 100% local."
triggers: [screenshot, capture, vision, analyze-ui, visual-review, captura, analizar-imagen]
---

# Vision Analyze — Local Screenshot Analysis

## Setup
1. Install Ollama: https://ollama.com/download
2. Pull model: `ollama pull moondream` (1.7GB, fast) or `ollama pull llava:7b` (4.5GB, better)
3. Start: `ollama serve` (default: localhost:11434)

## Usage

### PowerShell — Capture + Analyze
```powershell
& "$env:GENTLEMAN_AGENT_ROOT\scripts\analyze-screenshot.ps1"  # captures screenshot
& "$env:GENTLEMAN_AGENT_ROOT\scripts\analyze-screenshot.ps1" -ImagePath "img.png" -Mode ui
```

### Python — Analyze Existing
```bash
python scripts/analyze-image.py screenshot.png --mode ui
python scripts/analyze-image.py before.png after.png --compare
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
| RAM | Model | Speed |
|-----|-------|-------|
| <4GB | moondream | ~2s |
| 8GB+ | llava:7b | ~5s |
| 16GB+ | llava:13b | ~10s |

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
