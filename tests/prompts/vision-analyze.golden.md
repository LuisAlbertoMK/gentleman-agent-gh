# vision-analyze golden prompt

## Skill
vision-analyze (local vision via Ollama: UI, error, design, a11y, perf analysis)

## Trigger
vision, capture, analyze-ui

## Input
Vision-analyze the checkout page screenshot for UI errors and accessibility gaps, offline via Ollama (llava).

## Expected Output
VISION:checkout.png--2026-08-21 MODE:ui MODEL:llava ISSUES:2 TOP:button-misaligned VERIFY:[screenshot|ollama]->ok

## Assertion
- Response matches VISION:<target>--<date> MODE:<ui|error|a11y|perf> ISSUES:<n> contract
- Catches: UI misalignment, contrast issues, missing alt text in screenshot
- Within token_budget 1900
- NOTE: requires Ollama at localhost:11434; offline-first fallback logs unavailable
