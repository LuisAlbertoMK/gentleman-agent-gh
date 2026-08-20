---
name: baseline-ui
description: "Anti-slop UI — layout, typography, responsive, animation, tokens. Use for cleanup or polish."
triggers: "ui cleanup, polish interface, fix layout, ui slop, generic ui, design review, anti-slop, ui polish, polish ui"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1029
---

## When to Use
Anti-slop audit&cleanup: layout·typography·responsive·animation·tokens. **Stack**: CSS/Tailwind·`cn()`(clsx+tw-merge)·React. Audit→**ui-engine**. **Flow**: Scan→❌→fix→verify→a11y→perf. Review:`/baseline-ui <file>`.

## Layout 10 Patterns
1. Sticky sidebar `.pg{display:grid;grid-template-areas:"hd hd""sd mn";grid-template-columns:250px 1fr}.sd{position:sticky;top:1rem;align-self:start}`
2. Card grid `.grid{display:grid;gap:1.5rem;grid-template-columns:repeat(auto-fit,minmax(280px,1fr))}`
3. Responsive nav `.nav{display:flex;flex-wrap:wrap;gap:1rem}.nav>a{flex-shrink:0}`
4. Aspect media `.media{width:100%;aspect-ratio:16/9;object-fit:cover}`❌`padding-top:56.25%`
5. Sticky footer `body{display:grid;grid-template-rows:auto 1fr auto;min-height:100dvh}`
6. Fluid split `.split{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,320px),1fr))}`
7. CQ card `.card{container-type:inline-size}.card-inner{display:grid;gap:1rem}@container(min-width:400px){.card-inner{grid-template-columns:240px 1fr}}`
8. Subgrid `.rows{display:grid}.rows>*{display:grid;grid-template-rows:subgrid;grid-row:span 2}`
9. Stack/center `.stack{display:grid;gap:1rem}.center{place-items:center}`

## Typography
`text-balance`h·`text-pretty`body·`tabular-nums`data·Page→`clamp(1rem,1.5vw+.5rem,1.5rem)`

## Animation
`transform`+`opacity`only·❌w/h/top/left/margin/padding·120/200/300ms·❌>500·<200ms/elem. `@media(prefers-reduced-motion:reduce){*{animation-duration:.01ms!important;transition-duration:.01ms!important}}`

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