---
name: baseline-ui
description: "Anti-slop UI — layout, typography, responsive, animation, tokens. Use for cleanup or polish."
triggers: "ui cleanup, polish interface, fix layout, ui slop, generic ui, design review, anti-slop, ui polish, polish ui"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2200
---
## Typography
`text-balance` headings · `text-pretty` body · `tabular-nums` data · Page→`clamp(1rem,1.5vw+.5rem,1.5rem)`

## Tokens OKLCH→Var
1 OKLCH →2 primitive `--blue-500` →3 semantic `--primary` →4 component `--btn-bg` →5 theme `:root{color-scheme}` →6 verify ≥4.5:1.

## Hard Rules
- Animate `transform`+`opacity` ONLY — NEVER w/h/top/left; 120/200/300ms, NEVER >500ms
- ALWAYS `@media(prefers-reduced-motion:reduce)` → `.01ms`
- OKLCH only, 3-tier chain, contrast ≥4.5:1 — NEVER HSL/RGB/hex
- No fixed widths: `repeat(auto-fit,minmax())` + `clamp()` + `min-height:100dvh`
- `cqi` ONLY inside container; MQ=page, CQ=components

## Output
`UI-CLEANUP:<file>—<date> CRITICAL:<issue>→<fix> HIGH:<issue>→<fix> MEDIUM:<issue>→<fix> VERIFY:<pass/fail>`

## Anti-Patterns
Fixed width · h-screen · transition:all · >500ms · No reduced-motion · HSL/RGB · No contrast · cqi outside container

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "AI can do UI" | Generic slop (no tokens, no @layer) | Check OKLCH + Grid/Flex + CQ |
| "One CSS file is fine" | 500+ line without @layer | @layer + compositor-only + OKLCH |
| "Responsive is optional" | Fixed px widths | CQ + Flex/Grid + spacing tokens |

## Red Flags
- Hardcoded `#fff`/`#000`/px without tokens → slop — reject the diff until tokenized
- Animation on `width`/`height` → compositor violation — STOP ship until compositor-only

## Example
`/baseline-ui src/components/Button.tsx` → `UI-CLEANUP:Button—2026-08-27 CRITICAL:[contrast]→ HIGH:[layout]→ VERIFY:[axe]`

## Verification
- Verify contrast, reduced-motion, dark mode before done
- `vision-analyze` or Playwright screenshot before ship
- Offline-first: NO network/Ollama required for audit
- Output matches ## Output contract; cross-refs exist; no anti-patterns

→ docs/skills/baseline-ui/reference.md · Cross-Refs: ui-engine | accessibility | performance | web-quality-audit
