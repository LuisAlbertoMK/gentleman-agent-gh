---
name: image-pipeline
description: "Image optimization — compress, convert WebP/AVIF, resize, describe"
triggers: "compress image, optimize image, resize image, convert webp, convert avif, describe image, image too heavy, slow images, image bug"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Image optimization — compress, convert WebP/AVIF, resize, de


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

## Examples

### Example 1: Batch WebP Conversion (Photos)
```bash
# Convert all JPGs to WebP q80, keep originals
Get-ChildItem -Recurse *.jpg | ForEach-Object {
  $out = $_.FullName -replace '\.jpg$', '.webp'
  node -e "require('sharp')('$($_.FullName)').webp({quality:80}).toFile('$out')"
  Write-Host "$($_.Name) → $([math]::Round((Get-Item $out).Length / $_.Length * 100))%"
}
```

### Example 2: AVIF for Graphics/UI Assets
```bash
# PNG icons → AVIF q60 (best for flat colors)
Get-ChildItem icons/*.png | ForEach-Object {
  $out = $_.FullName -replace '\.png$', '.avif'
  node -e "require('sharp')('$($_.FullName)').avif({quality:60}).toFile('$out')"
}
```

### Example 3: Responsive Image Set (Multiple Widths)
```bash
# Generate srcset variants: 400w, 800w, 1200w, 1600w
$widths = @(400, 800, 1200, 1600)
Get-ChildItem hero.jpg | ForEach-Object {
  foreach ($w in $widths) {
    $out = $_.FullName -replace '\.jpg$', "-${w}w.webp"
    node -e "require('sharp')('$($_.FullName)').resize($w).webp({quality:80}).toFile('$out')"
  }
}
```

### Example 4: Describe Visual Bug via Vision API
```bash
# Screenshot + local LLaVA (free)
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "llava",
  "prompt": "Analyze this screenshot for: broken aspect ratio, text overlap, missing alt, layout shift. Return CSS fixes.",
  "images": ["base64_screenshot"],
  "stream": false
}' | jq -r .response
```

### Example 5: Pipeline with Savings Report
```bash
#!/usr/bin/env node
const sharp = require('sharp');
const fs = require('fs');

async function optimize(dir, {quality=80, format='webp'}={}) {
  const files = fs.readdirSync(dir).filter(f => /\.(jpg|png)$/i.test(f));
  let totalIn = 0, totalOut = 0;
  
  for (const file of files) {
    const inPath = `${dir}/${file}`;
    const outPath = inPath.replace(/\.(jpg|png)$/i, `.${format}`);
    const statsIn = fs.statSync(inPath);
    
    await sharp(inPath)[format]({quality}).toFile(outPath);
    const statsOut = fs.statSync(outPath);
    
    totalIn += statsIn.size;
    totalOut += statsOut.size;
    console.log(`${file}: ${((1 - statsOut.size/statsIn.size)*100).toFixed(1)}% saved`);
  }
  console.log(`\nTotal: ${((1 - totalOut/totalIn)*100).toFixed(1)}% (${(totalIn/1e6).toFixed(2)}MB → ${(totalOut/1e6).toFixed(2)}MB)`);
}

optimize(process.argv[2] || '.', JSON.parse(process.argv[3] || '{}'));
```

---

## Testing Patterns

### Pattern 1: Regression Test — Visual Diff
```bash
# Compare before/after with ImageMagick (fuzzy match < 1%)
magick compare -metric AE -fuzz 1% before.webp after.webp diff.png
# Exit code 0 = identical within threshold
```

### Pattern 2: Quality Gate — File Size Budget
```bash
# Fail if any optimized image > budget (e.g., 100KB for thumbnails)
Get-ChildItem *.webp | Where-Object { $_.Length -gt 100KB } | ForEach-Object {
  Write-Error "$($_.Name) exceeds 100KB budget ($([math]::Round($_.Length/1KB))KB)"
  exit 1
}
```

### Pattern 3: Format Correctness — Magic Bytes
```bash
# Verify WebP/AVIF headers (not just extension)
Get-ChildItem *.webp | ForEach-Object {
  $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
  if ($bytes[0..3] -join '' -ne 'RIFF' -or $bytes[8..11] -join '' -ne 'WEBP') {
    Write-Error "$($_.Name): Invalid WebP magic bytes"
  }
}
```

---

## Edge Cases

| Edge Case | Handling |
|-----------|----------|
| **Animated GIF/WebP** | `sharp` drops animation → use ImageMagick: `magick convert in.gif -coalesce out.webp` |
| **CMYK JPEGs** | Sharp fails silently → pre-convert: `magick in.jpg -colorspace sRGB out.jpg` |
| **EXIF Orientation** | Sharp auto-rotates by default → disable if preserving: `.rotate()` before resize |
| **Alpha on JPEG input** | JPEG has no alpha → convert to PNG first: `sharp(in.jpg).png().toBuffer()` then process |

---

## Anti-Patterns

1. **Compress before resize** — Wastes CPU on pixels you'll discard. Always resize first.
2. **Over-compress photos (q<60)** — Visible artifacts. Photos: q75-85. Graphics: q50-65 AVIF.
3. **Describe every image via Vision API** — Expensive/slow. Reserve for visual bugs only.
4. **Skip format verification** — Extension ≠ content. Validate magic bytes in CI.

## Refs
performance · web-quality-audit · visual-testing · baseline-ui
