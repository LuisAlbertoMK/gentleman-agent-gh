---
name: vision-analyze
description: "Local vision analysis - screenshots, UI review, error detection via Ollama. 100% local. NOT visual regression."
triggers: [capture, vision, analyze-ui, visual-review, captura, analizar-imagen]
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1945
---
## When to Use
Local vision analysis — screenshots, UI review, error detection.
Offline: if Ollama 127.0.0.1:11434 unreachable, returns degraded output gracefully, no crash — caller decides fallback per perf-offline-fallback.ps1
## Modes
`ui` layout/alignment/contrast/broken components | `error` messages+affected components | `design` spacing/typography/color/balance | `accessibility` WCAG 2.2 contrast/touch/focus | `performance` CLS/missing images/loading.
## Security
100% local via 127.0.0.1:11434. No external API calls.
## Hard Rules
- NEVER for visual regression/pixel diffing — that is `visual-testing` (`toHaveScreenshot`); Ollama slow + non-deterministic
- NEVER force `--model llava:7b` with <8GB free RAM — RAM-aware auto-select prevents OOM
- 100% local ONLY — never route screenshots through external APIs (data leak)
- Never route screenshots through external APIs (data leak) — see docs/mejoras/2026-08-27-ollama-cloud-investigation.md for cloud options (rule unchanged; offline-first via caller).
- Verify server + models before any run
## Output
`VISION:<target>—<date> MODE:[ui|error|design|a11y|perf] MODEL:<name> ISSUES:<n> TOP:<issue> VERIFY:[screenshot|ollama]→<ok/fail>`
## Cross-Refs: visual-testing | performance | accessibility | code-review-agent | self-improvement
## Anti-Patterns
Use for pixel diffing/regression (visual-testing's job) · Force llava:7b with <8GB RAM (OOM) · Route screenshots through external APIs (leak)
> docs/skills/vision-analyze/reference.md

## Verification
- Output: response matches the ## Output contract format exactly
- token_budget: total tokens within frontmatter token_budget
- frontmatter: name, description, triggers, token_budget present and stable
- cross-refs: each referenced skill exists
- anti-patterns: none of the listed anti-patterns reintroduced
