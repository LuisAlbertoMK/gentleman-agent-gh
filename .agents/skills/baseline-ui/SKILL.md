---
name: baseline-ui
description: "Anti-slop UI — layout, typography, responsive, animation, tokens. Use for cleanup or polish."
triggers: "ui cleanup, polish interface, fix layout, ui slop, generic ui, design review, anti-slop, ui polish, polish ui"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2300
---
## When to Use
Anti-slop audit&cleanup: layout·typography·responsive·animation·tokens. **Stack**: CSS/Tailwind·`cn()`(clsx+tw-merge)·React. Audit→**ui-engine**. **Flow**: Scan→❌→fix→verify→a11y→perf. Review:`/baseline-ui <file>`.
## Typography
`text-balance`h·`text-pretty`body·`tabular-nums`data·Page→`clamp(1rem,1.5vw+.5rem,1.5rem)`
## Tokens OKLCH→Var
1 Pick OKLCH `oklch(55% .18 255)`→2 primitive `--blue-500`→3 semantic `--primary:var(--blue-500)`→4 component `--btn-bg`→5 theme `:root{color-scheme:light dark}`→6 verify ≥4.5:1.
## Hard Rules
- Animate `transform`+`opacity` only — NEVER w/h/top/left/margin/padding; 120/200/300ms, NEVER >500ms, <200ms/element
- ALWAYS `@media(prefers-reduced-motion:reduce)` → `.01ms` override
- Colors: OKLCH only, 3-tier chain (primitive→semantic→component), contrast ≥4.5:1 — NEVER HSL/RGB hex
- No fixed widths: `repeat(auto-fit,minmax())` + `clamp()` + `min-height:100dvh` (never `h-screen`/fixed px)
- `cqi` ONLY inside a container; MQ=page, CQ=components
- Verify contrast, reduced-motion, dark mode before done
## Output
`UI-CLEANUP:<file>—<date> CRITICAL:[a11y|contrast]<issue>→<fix> HIGH:[layout|responsive]<issue>→<fix> MEDIUM:[tokens|anim]<issue>→<fix> VERIFY:[a11y|perf]→<pass/fail>`
## Anti-Patterns
Fixed width·h-screen·dense interactive·Fixed font·transition:all·>500ms·No reduced-motion·HSL/RGB·No contrast·cqi outside container
## Cross-Refs: ui-engine | accessibility | performance | web-quality-audit
> docs/skills/baseline-ui/reference.md

## Verification
- Output: response matches the ## Output contract format exactly
- token_budget: total tokens within frontmatter token_budget
- frontmatter: name, description, triggers, token_budget present and stable
- cross-refs: each referenced skill exists
- anti-patterns: none of the listed anti-patterns reintroduced
