# vision-analyze — Reference Materials

> **Externalized from** .agents/skills/vision-analyze/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains setup, usage, model selection, and test steps.

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

## Model Selection (RAM-aware auto)
| Free RAM | Model | Size | Speed | Quality |
|---|---|---|---|---|
| ≥2GB | moondream:latest | 1.7GB | ~75-90s | Basic |
| ≥8GB | llava:7b | 4.7GB | ~70-224s | Good |

Auto: script checks `os.freemem()` → largest that fits. Override: `--model llava:7b`.

## Integration
Code Review: capture→analyze→code-review-agent · Self-Improvement: before/after score delta · External Audit: production screenshots → a11y.

## Testing
1. Server up: `/api/version` → `{"version":"0.x.x"}`. 2. Models: `ollama list` → both listed. 3. Capture-only: `ap http://localhost:4200 -NoAnalysis` → screenshot.png, NO Ollama call.
