# image-pipeline — golden prompt

**Trigger**: "compress", "convert WebP/AVIF", "resize", "describe"

```
Optimize the images in src/assets: convert JPG/PNG to WebP (q80) and generate a responsive set
at 400/800/1200 (webp+avif). Always encode from the originals (never lossy→lossy), use per-image
quality, strip ICC to sRGB, downscale anything >32K px, and verify SSIM ≥0.995 + valid MIME.
```

**Expected**: `IMG-PIPE:<input>—<date> STAGE:[validate|transform|optimize|verify] OUT:<format> SIZE:<B→B> REDUCTION:<%> SSIM:<n> VERIFY:[tests|file-mime]→<pass/fail>`
