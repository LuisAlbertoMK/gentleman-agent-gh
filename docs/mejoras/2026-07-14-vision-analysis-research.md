# Research: Vision Analysis for Error Detection via Screenshots

**Date**: 2026-07-14
**Goal**: Enable the agent to analyze screenshots for error detection when the user can't describe the error textually
**Model Constraint**: big-pickle is TEXT-ONLY — cannot process images natively

---

## Executive Summary

**The problem is real and solvable.** There are 4 viable approaches, ranked by effort/impact:

| # | Approach | Effort | Cost | Quality | Privacy |
|---|----------|--------|------|---------|---------|
| 1 | **Ollama + local vision model** | Medium | Free | Good | 100% local |
| 2 | **MCP server (agent-vision-mcp)** | Low | ~$0.10/1K images | Excellent | External API |
| 3 | **OCR-only (Tesseract/PaddleOCR)** | Low | Free | Text only | 100% local |
| 4 | **Hybrid: OCR + LLM reasoning** | Medium | Free | Excellent | 100% local |

**Recommendation**: Option 1 (Ollama) as primary, Option 3 (OCR) as lightweight fallback.

---

## Current State

### What exists in the project
- **Skill**: `vision-analyze` — complete SKILL.md with modes (ui, error, design, accessibility, performance)
- **Script**: `scripts/analyze-screenshot.ps1` — fully functional PowerShell script that:
  - Captures screenshots or uses existing images
  - Sends to Ollama API (localhost:11434)
  - Supports 5 analysis modes
  - Supports before/after comparison
- **Skills**: `visual-testing`, `image-pipeline` — related but separate concerns

### What's MISSING
- **Ollama is NOT installed** on this machine (`ollama` command not found)
- **No vision model pulled** — even if Ollama were installed, no model available
- **analyze-image.py** — referenced in SKILL.md but DOES NOT EXIST
- **Peek-MCP** — not configured in opencode.json (was mentioned in session history but never set up)

### The core limitation
big-pickle (the current model) is **text-only**. When you paste an image:
- The `Read` tool CAN display images as attachments
- But the model CANNOT process/understand the image content
- Result: image is visible in the UI but the agent is blind to it

---

## Deep Research: All Viable Approaches

### Approach 1: Ollama + Local Vision Model ⭐ RECOMMENDED

**How it works**: Install Ollama, pull a vision model, use the existing `analyze-screenshot.ps1` script.

**Model options (2026 landscape)**:

| Model | RAM | Speed | Quality | Best For |
|-------|-----|-------|---------|----------|
| **moondream** | 4GB | ~2s | Basic | Quick error detection |
| **qwen2.5vl:7b** | 8GB | ~5s | Good | Documents + charts |
| **llava:7b** | 8GB | ~5s | Good | General purpose |
| **qwen3-vl:8b** | 8GB | ~5s | Very Good | OCR + screenshot analysis |
| **llama3.2-vision:11b** | 16GB | ~8s | Excellent | Best overall quality |
| **minicpm-v** | 6GB | ~4s | Good | Document OCR specialist |

**For this machine (Ryzen 7 3700U)**:
- 8-16GB RAM available → **qwen3-vl:8b** or **llava:7b** are ideal
- moondream too basic for error detection
- llama3.2-vision:11b might be tight on RAM

**Setup steps**:
```powershell
# 1. Install Ollama
winget install Ollama.Ollama

# 2. Pull vision model
ollama pull qwen3-vl:8b    # ~5GB download

# 3. Start Ollama (runs as service)
ollama serve

# 4. Test
& "$env:GENTLEMAN_AGENT_ROOT\scripts\analyze-screenshot.ps1" -Mode error
```

**Pros**: Zero cost, 100% local, no API keys, already have script
**Cons**: ~5GB download, uses RAM, setup required

---

### Approach 2: MCP Server (agent-vision-mcp)

**How it works**: An MCP server that routes images through an external vision API (Gemini, OpenAI, Qwen-VL) and returns text to the text-only model.

**Key project**: [agent-vision-mcp](https://github.com/kitlau86/agent-vision-mcp)
- Gives text-only models "eyes" via MCP
- Supports: Gemini Flash (free tier), Qwen-VL, OpenAI, self-hosted
- Auto-caches results (1h TTL)
- npm install: `npm install -g @kitlau/agent-vision-mcp`

**Configuration for OpenCode**:
```json
{
  "mcp": {
    "agent-vision": {
      "type": "local",
      "command": ["npx", "-y", "@kitlau/agent-vision-mcp"],
      "environment": {
        "VISION_PROVIDER": "gemini",
        "GEMINI_API_KEY": "your-key-here"
      }
    }
  }
}
```

**Other MCP options**:
- **ai-vision-mcp** (tan-yong-sheng) — 63⭐, Gemini/Vertex AI, video support
- **opencode-vision** (DavidEasden) — OpenCode-specific plugin
- **vision-mcp-server** (Loveacup) — 13⭐, OpenAI-compatible, video support
- **z_ai/mcp-server** — Z.AI's official vision MCP with specialized tools

**Pros**: Low setup, excellent quality (uses cloud models), works immediately
**Cons**: External API calls, potential cost, privacy concern

---

### Approach 3: OCR-Only (Tesseract/PaddleOCR)

**How it works**: Extract text from screenshots using traditional OCR, then the LLM processes the extracted text.

**Options**:
- **Tesseract OCR** — 60K⭐, 100+ languages, 99%+ accuracy, free
- **PaddleOCR** — PP-OCRv5, SOTA, 109 languages, ~15MB model
- **EasyOCR** — Python, 80+ languages, easy setup

**For error detection specifically**:
```python
# Simple Tesseract approach
import pytesseract
from PIL import Image

text = pytesseract.image_to_string(Image.open('error_screenshot.png'))
# Feed text to LLM for analysis
```

**Pros**: Fast, tiny footprint, no GPU needed, 100% local
**Cons**: Text only (no layout understanding), can't detect visual issues

---

### Approach 4: Hybrid (OCR + LLM) ⭐ BEST QUALITY

**How it works**: Two-stage pipeline:
1. **OCR stage**: Extract text + layout from screenshot
2. **LLM stage**: Analyze extracted content for errors, suggest fixes

**Implementation via existing tools**:
- **text-extract-api** (3K⭐) — Docker-based, FastAPI + Celery + Redis + Ollama
- **langchain-ocr-lib** — Python library, Ollama + Tesseract
- **opencode-vision PyPI** — `pip install opencode-vision[paddle]`

**Pipeline for error detection**:
```
Screenshot → PaddleOCR (text extraction) → LLM (error analysis) → Structured output
```

**Pros**: Best accuracy, structured output, understands context
**Cons**: More complex setup, two models needed

---

## The Read Tool Workaround

**Important discovery**: The `Read` tool CAN display images as file attachments in the conversation. This means:

1. User pastes/saves screenshot
2. Agent uses `Read` tool on the image file
3. Image appears as attachment in the conversation
4. **But big-pickle cannot process it** — the model is text-only

**This is NOT a solution** — it just makes the image visible in the UI without the agent being able to understand it.

---

## Comparison: What Solves What

| Capability | Ollama | MCP Server | OCR Only | Hybrid |
|------------|--------|------------|----------|--------|
| Read error messages | ✅ | ✅ | ✅ | ✅ |
| Detect UI layout issues | ✅ | ✅ | ❌ | ✅ |
| Understand visual context | ✅ | ✅ | ❌ | ✅ |
| Before/after comparison | ✅ | ✅ | ❌ | ✅ |
| Zero cost | ✅ | ❌ | ✅ | ✅ |
| 100% local/privacy | ✅ | ❌ | ✅ | ✅ |
| Works offline | ✅ | ❌ | ✅ | ✅ |
| Easy setup | ⚠️ | ✅ | ✅ | ⚠️ |
| RAM usage | High | Low | Low | High |

---

## Recommendation for This Project

### Primary: Ollama + qwen3-vl:8b
- Already have `analyze-screenshot.ps1` script ready
- Just needs Ollama installed + model pulled
- 100% local, zero cost, good quality
- Perfect for error detection use case

### Fallback: Tesseract OCR
- Lightweight, always available
- Good for text-only error messages
- Can be used when RAM is tight

### Future: MCP Server
- If Ollama RAM usage is problematic
- Or if you need cloud-level accuracy
- Gemini Flash has free tier

---

## Implementation Plan

### Phase 1: Install Ollama (5 min)
```powershell
winget install Ollama.Ollama
```

### Phase 2: Pull Vision Model (10 min)
```powershell
ollama pull qwen3-vl:8b
```

### Phase 3: Test Existing Script (2 min)
```powershell
& "$env:GENTLEMAN_AGENT_ROOT\scripts\analyze-screenshot.ps1" -Mode error -ImagePath "test_error.png"
```

### Phase 4: Create analyze-image.py (15 min)
- Python wrapper for Ollama vision API
- Support for batch processing
- Structured JSON output

### Phase 5: Update vision-analyze skill (5 min)
- Update SKILL.md with actual working setup
- Add troubleshooting section
- Document model selection guide

---

## Key Learnings

1. **big-pickle is text-only** — this is a fundamental limitation, not a configuration issue
2. **Read tool shows images but model can't process them** — the image appears as attachment but agent is blind
3. **Ollama is the best local solution** — already have script, just needs installation
4. **2026 vision models are excellent** — qwen3-vl, llama3.2-vision rival cloud APIs
5. **OCR alone is insufficient** — text extraction misses visual context (layout, colors, alignment)
6. **Hybrid approach is gold standard** — OCR + LLM gives best accuracy for error detection

---

## References

- [Best Ollama Vision Models 2026](https://www.serverman.co.uk/ai/ollama/best-ollama-models-for-vision/)
- [agent-vision-mcp](https://github.com/kitlau86/agent-vision-mcp)
- [ai-vision-mcp](https://github.com/tan-yong-sheng/ai-vision-mcp)
- [opencode-vision](https://github.com/DavidEasden/opencode-vision)
- [text-extract-api](https://github.com/CatchTheTornado/text-extract-api)
- [langchain-ocr-lib](https://github.com/a-klos/langchain-ocr)
- [Tesseract OCR](https://tesseractocr.org/)
