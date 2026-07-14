#!/usr/bin/env python3
"""
Local image analysis via Ollama multimodal models.
Zero cost, 100% local — wraps moondream/llava for UI/error/design review.

Usage:
    python analyze-image.py screenshot.png --mode error
    python analyze-image.py before.png after.png --compare
    python analyze-image.py screenshot.png --prompt "What fonts are used?"
"""
import argparse
import base64
import json
import sys
from pathlib import Path

import requests

OLLAMA_URL = "http://localhost:11434"
DEFAULT_MODEL = "moondream:latest"

MODE_PROMPTS = {
    "ui": "Analyze this UI screenshot. Identify: layout issues, alignment problems, contrast failures, missing elements, broken components, accessibility concerns. Be specific about what's wrong and where. Rate severity: critical/major/minor for each finding.",
    "error": "What error or issue does this screenshot show? Identify the exact error message, affected component, and suggested fix. If no error is visible, describe what you see.",
    "design": "Compare this UI against best practices: spacing, typography hierarchy, color consistency, visual balance, whitespace usage, visual weight distribution. List specific improvements with references to visible elements.",
    "accessibility": "Analyze this screenshot for WCAG 2.2 issues: contrast ratios (minimum 4.5:1 for text), text size (minimum 16px body), touch targets (minimum 44x44px), focus indicators, semantic structure, color independence. Rate each: critical/major/minor.",
    "performance": "What performance issues can you infer from this screenshot? Look for: layout shift indicators, missing images, loading spinners, render blocking artifacts, CLS issues, slow-loading content patterns.",
}


def encode_image(path: str) -> str:
    """Read image file and return base64-encoded string."""
    return base64.b64encode(Path(path).read_bytes()).decode("utf-8")


def check_ollama() -> bool:
    """Verify Ollama server is running."""
    try:
        r = requests.get(f"{OLLAMA_URL}/api/version", timeout=5)
        return r.status_code == 200
    except requests.ConnectionError:
        return False


def check_model(model: str) -> bool:
    """Check if model is available locally."""
    try:
        r = requests.get(f"{OLLAMA_URL}/api/tags", timeout=5)
        models = [m["name"] for m in r.json().get("models", [])]
        return any(model in m for m in models)
    except Exception:
        return False


def analyze(image_path: str, prompt: str, model: str = DEFAULT_MODEL) -> dict:
    """Send image to Ollama for analysis."""
    img_b64 = encode_image(image_path)

    payload = {
        "model": model,
        "prompt": prompt,
        "images": [img_b64],
        "stream": False,
    }

    r = requests.post(f"{OLLAMA_URL}/api/generate", json=payload, timeout=120)
    r.raise_for_status()

    return {
        "model": model,
        "image": Path(image_path).name,
        "prompt": prompt,
        "response": r.json().get("response", ""),
    }


def main():
    parser = argparse.ArgumentParser(description="Analyze images via local Ollama")
    parser.add_argument("images", nargs="+", help="Image path(s)")
    parser.add_argument("--mode", choices=MODE_PROMPTS.keys(), default="ui")
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--compare", action="store_true", help="Compare two images")
    parser.add_argument("--prompt", help="Custom prompt (overrides mode)")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    # Verify setup
    if not check_ollama():
        print("ERROR: Ollama not running. Start with: ollama serve", file=sys.stderr)
        sys.exit(1)

    if not check_model(args.model):
        print(f"ERROR: Model '{args.model}' not found. Pull it: ollama pull {args.model}", file=sys.stderr)
        sys.exit(1)

    # Determine prompt
    if args.compare and len(args.images) >= 2:
        prompt = "Compare these two UI screenshots (before and after). Identify: what changed, what improved, what regressed, what still needs work. Be specific about visual differences."
    elif args.prompt:
        prompt = args.prompt
    else:
        prompt = MODE_PROMPTS[args.mode]

    # Analyze
    results = []
    for img in args.images:
        if not Path(img).exists():
            print(f"ERROR: Image not found: {img}", file=sys.stderr)
            sys.exit(1)
        result = analyze(img, prompt, args.model)
        results.append(result)

    # Output
    if args.json:
        print(json.dumps(results, indent=2, ensure_ascii=False))
    else:
        for r in results:
            print(f"\n{'='*60}")
            print(f"  Image: {r['image']} | Model: {r['model']}")
            print(f"{'='*60}")
            print(r["response"])
            print()


if __name__ == "__main__":
    main()
