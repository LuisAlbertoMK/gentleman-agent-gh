# image-pipeline golden prompt

## Skill
image-pipeline (Image optimization: compress, convert WebP/AVIF, resize, describe)

## Trigger
compress, convert WebP/AVIF, resize, describe

## Input
Convert hero.png to WebP, resize to 1200w, strip EXIF, verify SSIM >= 0.95.

## Expected Output
IMG-PIPELINE:hero.png STATUS:ok FORMAT:webp SIZE:48000->8000 RATIO:83 CHANGES:1

## Assertion
- Response matches IMG-PIPELINE:<file> STATUS:<ok|warn|error> contract
- Catches: EXIF not stripped, wrong format, SSIM below threshold
- Within token_budget 2200
