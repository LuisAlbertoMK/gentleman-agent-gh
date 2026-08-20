---
name: vision-analyze
description: "Local vision analysis - screenshots, UI review, error detection via Ollama. 100% local. NOT visual regression."
triggers: [capture, vision, analyze-ui, visual-review, captura, analizar-imagen]
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
Local vision analysis — screenshots, UI review, error detection.
## Modes
`ui` layout/alignment/contrast/broken components | `error` messages+affected components | `design` spacing/typography/color/balance | `accessibility` WCAG 2.2 contrast/touch/focus | `performance` CLS/missing images/loading.
## Security
100% local via 127.0.0.1:11434. No external API calls.
## Hard Rules
- NEVER for visual regression/pixel diffing — that is `visual-testing` (`toHaveScreenshot`); Ollama slow + non-deterministic
- NEVER force `--model llava:7b` with <8GB free RAM — RAM-aware auto-select prevents OOM
- 100% local ONLY — never route screenshots through external APIs (data leak)
- Verify server + models before any run
## Output
`VISION:<target>—<date> MODE:[ui|error|design|a11y|perf] MODEL:<name> ISSUES:<n> TOP:<issue> VERIFY:[screenshot|ollama]→<ok/fail>`
## Cross-Refs: visual-testing | performance | accessibility | code-review-agent | self-improvement
## Anti-Patterns
Use for pixel diffing/regression (visual-testing's job) · Force llava:7b with <8GB RAM (OOM) · Route screenshots through external APIs (leak)
> docs/skills/vision-analyze/reference.md