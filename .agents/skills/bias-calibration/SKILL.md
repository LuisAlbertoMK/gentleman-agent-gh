---
name: bias-calibration
description: "Calibrate self-scoring bias against external audits. Run with !audit or during !score."
license: Apache-2.0
metadata:
  tags: [engineering, quality]
  author: gentleman-vMK
  version: "1.0"
triggers: "!audit, bias calibration, bias correction, calibration offset"
---
## DATA
Stored in `.learnings/bias-calibration.json` — rolling window of last 3 audits.
Format: `{ "offsets": { "Correctness": +1.5, ... }, "samples": 3 }`

## FLOW
1. **Check bitácora** for today's audit entry (`[audit] {date}`)
2. **If no audit**: skip correction, warn "no audit today"
3. **If audit exists**: subtract avg offset per dim from self-score BEFORE threshold checks
4. **Log** each correction: "Bias corrected: {dim}={offset}"
5. **Check thresholds**: <7→immune, ≥9→mem_save
6. **Update** calibration: append today's (self, audit) pair, keep rolling 3

## NOTES
- No data → OK (not enough samples)
- Offsets beyond ±3.0 → flag for review (calibration drift)
- Only runs during `!score` or `!audit`, never automatically
