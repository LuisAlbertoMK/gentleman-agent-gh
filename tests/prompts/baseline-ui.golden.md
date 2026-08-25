# baseline-ui golden prompt

## Skill
baseline-ui (Anti-slop UI: layout, typography, responsive, animation, tokens)

## Trigger
ui cleanup / polish interface / design review

## Input
```tsx
// slop.tsx -- multiple UI slop violations
import React from "react"
export default function Button() {
  return (
    <button
      className="h-screen absolute w-120 bg-[#1a73e8] transition-all 500ms"
      style={{ width: "120px", height: "100vh" }}>
      Click me
    </button>
  )
}
```

## Expected Output
UI-CLEANUP:slop.tsx--2026-08-21 CRITICAL:[a11y]no prefers-reduced-motion on 500ms anim -> add @media(prefers-reduced-motion:reduce){transition:none} HIGH:[layout]absolute+h-screen+w-120px -> clamp(1rem,5vw,1.5rem) min-height:100dvh MEDIUM:[tokens]hex #1a73e8 -> oklch(0.6 0.18 255) VERIFY:[a11y|perf]->pass|perf:reduced-motion

## Assertion
- Response matches UI-CLEANUP:<file>--<date> contract
- Catches: transition-all, 500ms anim, h-screen, absolute positioning, hardcoded px width, hex color, no reduced-motion
- Within token_budget 1870
