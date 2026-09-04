---
name: performance
description: "Web performance — CWV/INP, compositor animation, scroll-driven, content-visibility. NOT app scoring (see performance-tracker)"
triggers: "performance, speed up, load time, slow loading, page speed, performance audit, INP, animation performance, scroll performance, compositor"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2704
---
<!-- karpathy-compressed: 2026-07-10 -->
## CWV Checklist (core)
LCP<2.5s · FCP<1.8s · TBT<200ms · CLS<0.1 (explicit w/h or aspect-ratio) · INP<200ms · Budgets: Total<1.5MB JS(gz)<300KB CSS<100KB Images<500KB Fonts<100KB 3rd<200KB — detalla tablas Budget/INP/Compositor → reference.md
## Critical Path + Caching
TTFB<800ms · Brotli · HTTP/2+ · Edge · preload LCP · defer · code-split · tree-shake
`HTML: no-cache` · `Static: public,max-age=31536000,immutable` · `API: private,no-cache`
## Media + Runtime
AVIF→WebP→PNG→SVG, `<picture>` srcset, LCP `fetchpriority="high"`, lazy. Fonts: `font-display:swap`, preload .woff2, unicode-range, variable.
Batch DOM reads · debounce scroll≥100ms · rAF · virtualize >100 · View Transitions · 3rd-party: async/IObserver/Facade
## INP + Compositor (summary)
INP<200ms: Input<50ms + Processing<100ms (`scheduler.yield()`) + Presentation<50ms (compositor). Animate ONLY `transform`+`opacity` (GPU) — NEVER w/h/top/left/margin/padding (Main thread). Detalles → reference.md
## Output
`PERF-AUDIT:<url>—<date> CRITICAL:[LCP|CLS|FCP|TBT|INP]<actual>/<budget>→<fix> HIGH:[img|font|JS|CSS]<kb>→<fix> INP:<ms>→<proc>/<present> VERIFY:[lighthouse|web-vitals]→PASS/FAIL`
## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Optimizar sin medir" | No baseline Lighthouse | benchmark-core.ps1 -Gate before/after |
| "INP<200ms solo en mobile" | Main thread bloqueado | `scheduler.yield()` + compositor-only verify (DevTools) |
| "Animar width/height da igual" | Layout trashing | Animate `transform`+`opacity` only, verifica compositor |
## Red Flags
- No baseline measurement → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone
## Verification
- benchmark-core.ps1 -Gate before/after
- cross-ref-check.ps1 → SKILL.md OK
## Cross-Refs: performance-tracker | baseline-ui | ui-engine | web-quality-audit | accessibility
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-048).
Consult these when the skill needs detailed worked examples or guardrails:

- **Budget/INP/Compositor tables, Worked Examples, Testing Patterns, Edge Cases**
  → docs/skills/performance/reference.md

---
