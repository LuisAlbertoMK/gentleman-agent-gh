# image-pipeline — Reference Materials

> **Externalized from** .agents/skills/image-pipeline/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
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
