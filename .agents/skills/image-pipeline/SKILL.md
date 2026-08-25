---
name: image-pipeline
description: "Image optimization — compress, convert WebP/AVIF, resize, describe. Single-file atomic edits, batch processing, metadata extraction."
triggers: "compress, convert WebP/AVIF, resize, describe"
changelog: docs/ciclos/cycle28-20260816.md
token_budget: 2200
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

## Hard Rules
- Match format: WebP (lossy photo) / AVIF (high crunch) / PNG (lossless) / SVG (vector)
- Preserve aspect ratio: no upscale beyond source
- Strip EXIF metadata unless describe needs it
- Responsive width units only; no hardcoded w/h px
- Quality gate: SSIM/PSNR >= 0.95 vs source; reject on regression

## Output
IMG-PIPELINE:<file> STATUS:<ok|warn|error> FORMAT:<fmt> SIZE:<before->after> RATIO:<pct> CHANGES:<n>

## Anti-Patterns
Upscaling beyond source | hardpx width on responsive | metadata not stripped | lossy on SVG | no SSIM gate | missing alt-text

## Cross-Refs: visual-testing | vision-analyze | web-quality-audit | performance

## Verification
- Output: response matches the ## Output contract format exactly
- token_budget: total tokens within frontmatter token_budget
- frontmatter: name, description, triggers, token_budget present and stable
- cross-refs: each referenced skill exists
- anti-patterns: none of the listed anti-patterns reintroduced

---

> See [reference.md](docs/skills/image-pipeline/reference.md) for extended details, examples, and detailed patterns.
