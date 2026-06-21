---
name: caveman
description: "Ultra-minimal compressed context mode — L3 emergency compression, 1-liner/topic format, used when context >60% or error rate 2+"
triggers: "caveman, ultra-lean, compression, minimal context, emergency mode"
license: Apache-2.0
metadata:
  tags: [compression, optimization]
  author: gentleman-vMK
  version: "1.0"
  changelog: "1.0: created from references in AGENTS.md + lean-context triggers"
---
## Purpose
Extreme compression when context is critically high (YELLOW >60% or RED zone). 1-liner per topic, strip all narrative, preserve only decisions + file paths.

## When
- Context >60% YELLOW → L2 compression (decisions only)
- Context >80% RED → L3 emergency (1-liner/file, skip verify)
- Error rate 2+ in last 5 turns → immediate L3

## Format
```
topic: 1-liner | Ref: engram-obs-{id}
file: purpose | status
decision: what was chosen | why
```

## Rules
- No explanations. No examples. No greetings.
- Every line must carry unique information.
- If a line doesn't add decision/signal → delete it.
- Reference Engram IDs instead of repeating context.
