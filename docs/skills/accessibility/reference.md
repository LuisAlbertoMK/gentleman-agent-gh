# accessibility — Reference Materials

> **Externalized from** .agents/skills/accessibility/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Testing Patterns (3)

### 1. Color Contrast — Automated + Manual
- **Automated**: axe-core color-contrast rule + custom per-theme script above
- **Manual**: Verify getComputedStyle contrast in **every theme** (light/dark/high-contrast) for: text, UI borders, focus rings, disabled states
- **Threshold**: AA = 4.5:1 (normal), 3:1 (large/UI); AAA = 7:1 / 4.5:1

### 2. ARIA & Semantic Structure — Lint + Screen Reader
- **Lint**: eslint-plugin-jsx-a11y + axe-core (rules: aria-*, role, scope, landmark)
- **Screen reader**: NVDA/VoiceOver walk-through — verify landmark announcements, form label association, live region behavior
- **Check**: No duplicate IDs, aria-describedby points to existing element, aria-live not overused

### 3. Keyboard Navigation — Tab Flow + Focus Visible
- **Automated**: Playwright page.keyboard.press('Tab') loop → screenshot each focus state
- **Manual**: Tab through entire page — every interactive reachable, focus order matches visual, :focus-visible ring visible (2px solid + 2px offset)
- **Regression**: Test every responsive breakpoint (mobile/tablet/desktop) — grid reorder must not break tab order

---

## Edge Cases (4)

### 1. When NOT to Use ARIA
- **Native HTML exists**: <button> not <div role="button">, <nav> not <div role="navigation">
- **Over-engineering**: Simple links/buttons need no ARIA — native semantics win
- **Rule**: ARIA is a **last resort** when native cannot express the pattern (e.g., complex tree, custom slider)

### 2. Cognitive Disabilities (WCAG 2.2 3.3.8 + 2.3.3)
- **Auth**: No puzzle CAPTCHAs — allow copy-paste, autofill, WebAuthn/passkeys, magic links
- **Timeouts**: Extendable (aria-live warning + extend button) — no auto-logout without notice
- **Language**: Simple, consistent terminology; avoid jargon; provide glossary for complex flows

### 3. Dynamic Content & Live Regions
- **Polite vs Assertive**: aria-live="polite" for updates (toast, cart count); role="alert" (assertive) for errors only
- **Atomic updates**: Wrap changed region in aria-atomic="true" to prevent full re-read
- **Race conditions**: Debounce rapid updates — batch into single announcement

### 4. Internationalization & RTL
- **lang attribute**: html lang="es-AR" + per-section lang changes
- **RTL focus order**: Logical (DOM) order must match visual RTL — test keyboard tab in RTL mode
- **Number/date formats**: Screen readers announce per locale — test with NVDA Spanish, VoiceOver Arabic
- **Font scaling**: Support rem + @media (prefers-reduced-motion) — no fixed px on text containers

---

## Anti-Patterns (2) — STOP Doing These

### ❌ 1. outline: none / outline: 0 Without Focus-Visible Replacement
`css
/* NEVER */
button:focus { outline: none; }

/* ALWAYS — visible focus for keyboard users */
button:focus-visible { outline: 2px solid var(--clr-focus); outline-offset: 2px; }
button:focus:not(:focus-visible) { outline: none; } /* mouse click = no ring */
`

### ❌ 2. grid-auto-flow: dense on Interactive Grids
`css
/* NEVER — breaks DOM tab order (WCAG 2.4.3) */
.grid { display: grid; grid-auto-flow: dense; }

/* ALWAYS — preserve source order */
.grid { display: grid; }
/* If reordering needed: use order ONLY on non-interactive items, or restructure DOM */
`

---

## Output
`A11Y:<page>—<date> CRITICAL:[wcag-2.x]<violation>→<fix> HIGH:... MEDIUM:... VERIFY:[axe|nvda|tab]→<pass/fail>`

## Quick Reference Card

| Check | Tool/Method | Pass Criteria |
|-------|-------------|---------------|
| Contrast (all themes) | axe + getComputedStyle script | ≥4.5:1 text, ≥3:1 UI/focus |
| Focus visible | Keyboard tab + :focus-visible CSS | 2px solid + 2px offset on all interactive |
| Touch targets | DevTools element inspector | ≥44×44px (24×24px dense only) |
| ARIA validity | eslint-plugin-jsx-a11y + axe | Zero violations |
| Screen reader | NVDA/VoiceOver walk-through | Landmarks, labels, live regions announced |
| Keyboard order | Tab through all breakpoints | DOM order = visual order |
| Reduced motion | @media (prefers-reduced-motion) | Animations disabled/near-zero |
| Language | html lang + section lang | Matches content language |
