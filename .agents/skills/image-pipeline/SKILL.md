---
name: image-pipeline
description: "Image optimization — compress, convert WebP/AVIF, resize, describe. Single-file atomic edits, batch processing, metadata extraction."
triggers: "compress, convert WebP/AVIF, resize, describe"
changelog: docs/ciclos/cycle28-20260816.md
token_budget: 1782
---

## When to Use
Image optimization — compress, convert WebP/AVIF, resize, describe. Single-file atomic edits, batch processing, metadata extraction.
**NOT**: visual regression (`visual-testing`) · LLM image description of UI screens (`vision-analyze`) · page screenshot capture (`visual-testing`).

## Pipeline Stages

```
Input → [Validate] → [Transform] → [Optimize] → [Verify] → Output
```

| Stage | Tools | Purpose |
|-------|-------|---------|
| Validate | `file`, `identify` (ImageMagick) | MIME, dimensions, corruption check |
| Transform | `magick convert`, `cwebp`, `avifenc` | Resize, format convert, color space |
| Optimize | `mozjpeg`, `oxipng`, `svgo` | Lossless/lossy compression |
| Verify | `compare` (SSIM/PSNR), `identify` | Quality gates, regression detection |

---

## 5 Examples

### 1. Batch WebP Conversion (lossy, quality 80)
```bash
#!/usr/bin/env bash
# convert-to-webp.sh — Batch convert JPEG/PNG → WebP
set -euo pipefail
SRC="${1:-.}"; DEST="${2:-./webp-out}"; Q="${3:-80}"
mkdir -p "$DEST"
find "$SRC" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
  -exec bash -c 'cwebp -q "$Q" "$1" -o "${2}/${1##*/%.*}.webp"' _ {} "$DEST" \;
```

### 2. AVIF Encode with Speed/Quality Tradeoff
```bash
#!/usr/bin/env bash
# encode-avif.sh — AVIF with configurable speed (0=slow/best, 10=fast/worst)
set -euo pipefail
SRC="$1"; DEST="${2:-./avif-out}"; SPEED="${3:-4}"; Q="${4:-50}"
mkdir -p "$DEST"
for f in "$SRC"/*.{jpg,jpeg,png,webp}; do
  [ -f "$f" ] || continue
  avifenc --speed "$SPEED" --quality "$Q" "$f" "${DEST}/${f##*/%.*}.avif"
done
```

### 3. Responsive Image Set (srcset Generation)
```bash
#!/usr/bin/env bash
# responsive-set.sh — Generate 3 breakpoints + WebP/AVIF variants
set -euo pipefail
SRC="$1"; OUT="${2:-./responsive}"; WIDTHS=(400 800 1200)
mkdir -p "$OUT"
for w in "${WIDTHS[@]}"; do
  magick "$SRC" -resize "${w}x>" -quality 80 "${OUT}/${w}w.webp"
  magick "$SRC" -resize "${w}x>" -quality 50 "${OUT}/${w}w.avif"
done
# Output HTML fragment
echo "<picture>"
for w in "${WIDTHS[@]}"; do
  echo "  <source srcset=\"${w}w.avif\" type=\"image/avif\" media=\"(min-width: ${w}px)\">"
  echo "  <source srcset=\"${w}w.webp\" type=\"image/webp\" media=\"(min-width: ${w}px)\">"
done
echo "  <img src=\"${WIDTHS[1]}w.webp\" alt=\"\">"
echo "</picture>"
```

### 4. Lossless PNG Optimization Pipeline
```bash
#!/usr/bin/env bash
# optimize-png.sh — oxipng + zopfli for maximum lossless compression
set -euo pipefail
SRC="${1:-.}"; DEST="${2:-./png-opt}"
mkdir -p "$DEST"
find "$SRC" -type f -iname "*.png" -exec bash -c '
  oxipng --opt max --strip all "$1" -o "${2}/${1##*/}"
  advpng -z -4 "${2}/${1##*/}"
' _ {} "$DEST" \;
```

### 5. Image Description via Local LLM (Ollama + LLaVA)
```bash
#!/usr/bin/env bash
# describe-image.sh — Generate alt-text/description using local vision model
set -euo pipefail
IMG="$1"; MODEL="${2:-llava:13b}"
# Encode to base64 for Ollama API
B64=$(base64 -w0 "$IMG")
curl -s http://localhost:11434/api/generate \
  -d "{\"model\":\"$MODEL\",\"prompt\":\"Describe this image in one sentence for accessibility.\",\"images\":[\"$B64\"],\"stream\":false}" \
  | jq -r '.response'
```

---

## 3 Testing Patterns

### Pattern 1: Golden File Regression (SSIM Threshold)
```bash
# test-regression.sh — Compare output against golden master
set -euo pipefail
GOLDEN="tests/golden/out.webp"; ACTUAL="out.webp"
SSIM=$(magick compare -metric SSIM "$GOLDEN" "$ACTUAL" null: 2>&1 | awk '{print $2}')
THRESHOLD=0.995
awk "BEGIN {exit !($SSIM >= $THRESHOLD)}" || { echo "SSIM $SSIM < $THRESHOLD"; exit 1; }
```

### Pattern 2: Property-Based Size/Quality Invariant
```python
# test_invariants.py — Property tests: size reduction, dimension bounds
import subprocess, os, pytest
from PIL import Image

@pytest.mark.parametrize("src", ["tests/fixtures/photo.jpg", "tests/fixtures/graphic.png"])
def test_size_reduction(src):
    out = f"/tmp/{os.path.basename(src)}.webp"
    subprocess.run(["cwebp", "-q", "80", src, "-o", out], check=True)
    assert os.path.getsize(out) < os.path.getsize(src) * 0.9  # ≥10% reduction

def test_dimension_preserved():
    src = "tests/fixtures/photo.jpg"
    out = "/tmp/photo_800w.webp"
    subprocess.run(["magick", src, "-resize", "800x>", out], check=True)
    with Image.open(src) as im, Image.open(out) as om:
        assert om.width <= 800
        assert abs(om.height / om.width - im.height / im.width) < 0.01  # aspect ratio
```

### Pattern 3: Contract Test — CLI Interface Stability
```bash
# test_cli_contract.sh — Verify CLI flags, exit codes, stdout schema
set -euo pipefail
# Happy path
./convert-to-webp.sh tests/fixtures/ /tmp/out 80
# Invalid quality → non-zero exit
! ./convert-to-webp.sh tests/fixtures/ /tmp/out 101
# Missing source → non-zero exit, stderr contains usage
! ./convert-to-webp.sh /nonexistent /tmp/out 80 2>&1 | grep -q "Usage:"
# Output directory created
rm -rf /tmp/cli-test && ./convert-to-webp.sh tests/fixtures/ /tmp/cli-test 80
[ -d /tmp/cli-test ] && [ "$(ls /tmp/cli-test | wc -l)" -gt 0 ]
```

---

## 4 Edge Cases

| # | Edge Case | Handling |
|---|-----------|----------|
| 1 | **Corrupted/Truncated Input** | `identify -verbose` pre-check → skip + log, never crash pipeline |
| 2 | **ICC Profile Mismatch** | Strip profiles (`-strip`) unless `--preserve-icc`; convert to sRGB for web |
| 3 | **Animated WebP/AVIF** | Detect frames (`identify -format %n`); preserve animation or extract first frame per flag |
| 4 | **Extreme Dimensions (>32K px)** | Downscale to max 16K before encode (encoder limits); warn in metadata |

---

## Anti-Patterns

| # | Anti-Pattern | Why It Fails | Correct Approach |
|---|--------------|--------------|------------------|
| 1 | **Re-encoding Lossy → Lossy** | Generational quality loss (artifacts compound) | Always encode from **source/original**; keep lossless master |
| 2 | **Single-Quality Global Setting** | Over-compresses simple graphics; under-compresses photos | Per-image heuristic: `quality = 85 - (entropy * 15)` or content-aware presets |

---

## Quality Gates (CI Integration)

```yaml
# .github/workflows/image-pipeline.yml
- name: Image Pipeline Quality Gate
  run: |
    # 1. No regressions vs golden
    ./test-regression.sh
    # 2. Size budgets per breakpoint
    find responsive -name "*.webp" -exec bash -c '
      sz=$(stat -c%s "$1"); max=$2
      [ $sz -le $max ] || { echo "$1: $sz > $max"; exit 1; }
    ' _ {} 50000 \;
    # 3. All outputs valid
    find out -type f -exec file --mime-type {} \; | grep -vE "image/(webp|avif|jpeg|png)" && exit 1
```

---

## Hard Rules
- ALWAYS encode from source/original or lossless master — NEVER re-encode lossy→lossy (generational quality loss)
- Validate input first (`identify`) — corrupted/truncated → skip + log, never crash the pipeline
- Per-image quality heuristic (`quality = 85 − entropy×15`) — never one global setting
- Strip ICC unless `--preserve-icc`; convert to sRGB for web
- Downscale >32K px to ≤16K before encode (encoder limits); animated formats → preserve or extract first frame per flag
- Verify every output: SSIM ≥0.995 vs golden + valid MIME + size budget (Quality Gates)

## Output
`IMG-PIPE:<input>—<date> STAGE:[validate|transform|optimize|verify] OUT:<format> SIZE:<B→B> REDUCTION:<%> SSIM:<n> VERIFY:[tests|file-mime]→<pass/fail>`

## Quick Reference

| Task | Command |
|------|---------|
| Convert dir to WebP (q80) | `./convert-to-webp.sh src/ dest/ 80` |
| AVIF batch (speed 4, q50) | `./encode-avif.sh src/ dest/ 4 50` |
| Responsive set (400/800/1200) | `./responsive-set.sh hero.jpg ./out` |
| Lossless PNG max compression | `./optimize-png.sh src/ dest/` |
| Describe image (Ollama) | `./describe-image.sh photo.jpg llava:13b` |
| Run all tests | `bash test-regression.sh && python -m pytest test_invariants.py && bash test_cli_contract.sh` |

## Cross-Refs: performance | accessibility | web-quality-audit | visual-testing | vision-analyze

