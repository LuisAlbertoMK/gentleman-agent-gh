---
name: image-pipeline
description: "Image optimization — compress, convert WebP/AVIF, resize, describe"
triggers: "compress image, optimize image, resize image, convert webp, convert avif, describe image, image too heavy, slow images, image bug"
license: Apache-2.0
metadata:
  tags: [performance, images, optimization]
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.1: Karpathy compression (<2.5KB)"
  dependencies: [command-wrapper, performance]
  env:
    GENTLEMAN_AGENT_ROOT: "Repo root"
---

## Tools
| Tool | Use | Install |
|------|-----|---------|
| **Sharp** | Compress/convert (60 imgs/sec) | `npm i sharp` |
| **ImageMagick** | Fallback batch | `magick convert` |
| **Vision API** | Describe bugs | API call |

## Mode 1: Compress
```bash
# Single: node -e "require('sharp')('in.jpg').webp({quality:80}).toFile('out.webp')"
# Batch: Get-ChildItem *.jpg | % { node -e "require('sharp')($_.FullName).webp({q:80}).toFile($_.FullName-replace'\.jpg$','.webp')" }
```

## Mode 2: Convert
```bash
# PNG→WebP: sharp('in.png').webp({quality:85}).toFile('out.webp')
# JPG→AVIF: sharp('in.jpg').avif({quality:60}).toFile('out.avif')
# Resize+compress: sharp('in.jpg').resize(1200).webp({q:80}).toFile('out.webp')
```

## Mode 3: Describe (Visual Bugs)
```
User: "La imagen se ve rara"
→ Screenshot via Peek-MCP → Vision API
→ "broken aspect ratio, text overlapping, missing alt"
→ Correlate CSS → propose fix
```
**Best APIs**: Claude (actionable CSS fixes) · GPT-4V (accessibility) · Local LLaVA (free)

## Decision Tree
```
Image heavy? → Sharp q80 → WebP/AVIF → report savings
Visual bug unclear? → screenshot → Vision API → fix
Batch? → Sharp pipeline → report total savings
```

## Targets
| Metric | Target |
|--------|--------|
| Photo compression | 60-80% smaller (WebP q80) |
| Graphic compression | 70-90% smaller (AVIF q60) |
| Resize | <100ms/image |
| Description | <2s/image |

## Anti-Patterns
Compress before resize · Over-compress photos (q<60) · Describe every image (expensive)

## Refs
performance · web-quality-audit · visual-testing · baseline-ui
