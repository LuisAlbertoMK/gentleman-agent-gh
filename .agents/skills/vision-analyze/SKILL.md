---
name: vision-analyze
description: "Local vision analysis - screenshots, UI review, error detection via Ollama. 100% local. NOT visual regression."
triggers: [capture, vision, analyze-ui, visual-review, captura, analizar-imagen]
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2664
---
## When to Use
Local vision analysis — screenshots, UI review, error detection. Offline: if 127.0.0.1:11434 unreachable → degraded graceful, no crash (perf-offline-fallback.ps1).
## Modes
`ui` layout/contrast/broken | `error` msgs+components | `design` spacing/typo/color | `accessibility` WCAG contrast/touch | `performance` CLS/images/loading
## Security
Default: 100% local via 127.0.0.1:11434. Cloud allowed only if VISION_ANALYZE_OLLAMA_CLOUD=1 and OllamaApiKey set and screenshot sanitized (no PII) — see RUNBOOK.md and docs/mejoras/2026-08-27-ollama-cloud-investigation.md (G8 Option 1).
## Hard Rules
- NEVER for visual regression/pixel diffing — that is `visual-testing` (`toHaveScreenshot`); Ollama slow + non-deterministic
- NEVER force `--model llava:7b` with <8GB free RAM — RAM-aware auto-select prevents OOM
- Default: 100% local via 127.0.0.1:11434. Cloud allowed only if VISION_ANALYZE_OLLAMA_CLOUD=1 and OllamaApiKey set and screenshot sanitized (no PII)
- Offline-first fallback: if Ollama not reachable or allowlist blocks, degrade gracefully — no crash; verify server + models before any run
## Output
`VISION:<target>—<date> MODE:[ui|error|design|a11y|perf] MODEL:<name> ISSUES:<n> TOP:<issue> VERIFY:[screenshot|ollama]→<ok/fail>`
## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Ollama caído → inventar análisis" | Offline sin check, hallucina | Verifica 127.0.0.1:11434 antes; si down → degraded graceful |
| "Usar para regression en vez de feel" | Pixel diff con Ollama no determinístico | Solo feel ui/error/design/a11y/perf; regression=visual-testing |
| "Sin fallback offline documentado" | Crash si Ollama bloqueado | Offline-first per perf-offline-fallback.ps1, no crash |
## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence → force RED zone
## Verification
- Output matches ## Output contract + file:line
- cross-ref-check.ps1 → SKILL.md OK
## Cross-Refs: visual-testing | performance | accessibility | baseline-ui | ui-engine | web-quality-audit | seo | code-review-agent | self-improvement
## Anti-Patterns
Use for pixel diff (visual-testing) · Force llava:7b <8GB (OOM) · Route unsanitized via external without VISION_ANALYZE_OLLAMA_CLOUD=1
> docs/skills/vision-analyze/reference.md
