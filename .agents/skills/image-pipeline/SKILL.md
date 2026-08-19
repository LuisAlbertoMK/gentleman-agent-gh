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

> See [reference.md](docs/skills/image-pipeline/reference.md) for extended details, examples, and detailed patterns.