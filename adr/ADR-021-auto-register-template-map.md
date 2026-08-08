# ADR-021: Auto-Register Template Map via detectTemplate()

| Field | Value |
|-------|-------|
| **Status** | Proposed (Cycle #5) |
| **Date** | 2026-08-07 |
| **Deciders** | Gentleman Agent v3 |
| **Tags** | template-map, drift, auto-registration, fail-closed |

## Context

`generate-opencode-config.js` and `use-gentleman.ps1` each maintain a
**manual hashtable** mapping agent names to permission template names
(`TEMPLATE_MAP` / `$templateMap`). This SSoT has **drifted** between the two
generators:

1. **Missing entries** — PowerShell `$templateMap` was missing
   `gentleman-codex-sub` and `gentleman-reviewer-sub` that exist in JS
   `TEMPLATE_MAP`.
2. **Wrong template values** — PowerShell mapped four `*-sub-auto` agents
   to `'auto'` instead of `'auto-sub'`, producing zero-ask permission
   gaps.
3. **Manual maintenance** — every new agent requires editing **both** files;
   if one is missed, the generators silently produce different configs.

## Decision

Introduce a `detectTemplate()` function (JavaScript) and `Detect-Template`
(PowerShell) that **mirror each other exactly**. The logic:

1. **Explicit lookup** in the manual map — always wins (SSOT anchor).
2. **Suffix auto-registration**:
   - `-sub-auto` → `'auto-sub'` (zero-ask subagent)
   - `-auto` → `'auto'`
   - `-semi` → `'semi'`
   - `-sub` → strip suffix, recurse on parent (mirrors parent's template).
3. **Role keyword matching**:
   - `security`, `infra`, `docs`, `seo`, `frontend`, `performance`,
     `datascience` → `'readonly'`
   - `reviewer` → `'reviewer'`
   - `vMK` → `'orchestrator'`
4. **Fail-closed** — throw if no match.

### Changes

| File | Change |
|------|--------|
| `scripts/lib/generate-opencode-config.js` | Add `detectTemplate()` + helper tables. Replace `TEMPLATE_MAP[agentName]` lookup with `detectTemplate(agentName)`. |
| `scripts/use-gentleman.ps1` | Add `Detect-Template` + helper tables. Fix `-sub-auto` drift (`'auto'` → `'auto-sub'`). Add missing `-sub` entries. Replace `$templateMap[$name]` lookup with `Detect-Template`. |
| `scripts/tests/generate-config.Tests.ps1` | New `R10` describe block: auto-registration + fail-closed regression. |

### Consequences

- **Positive**: New agents following naming conventions are auto-registered
  in both generators — zero manual map edits. Eliminates JS↔PS drift.
- **Negative**: Slight indirection cost (function call vs direct hashtable
  lookup) — negligible (microseconds).
- **Migration**: Existing explicit entries are kept as SSOT anchors. The
  auto-detection only fires for agents **not** in the explicit map.

## Alternatives Considered

| Alternative | Rejected because |
|-------------|-----------------|
| Remove explicit map entirely, rely only on auto-detection | Explicit map documents known agents and allows overrides for non-conventional names. |
| Generate `$templateMap` from a single JSON source | Would require a new build step; current generators already diverge from JSON. |

## Related

- ADR-008 (v3): auto-sub permission merge safety — the `'auto-sub'` template
  this ADR ensures is correctly assigned.
- ADR-015 (v2): write-scope fail-closed — this ADR applies the same
  fail-closed principle to template resolution.

## Status History

- **Proposed** — 2026-08-07 (Cycle #5 planning)
