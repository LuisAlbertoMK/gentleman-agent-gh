# Web Style Clone Tools — 2026 Survey

> **Date**: 2026-07-01
> **Source**: Internet research + GitHub + npm registry
> **Context**: Copy complete CSS/design system from any live URL

## Tier 1: CLI / npx (programmatic, no browser)

| Tool | Install | What | Verdict |
|------|---------|------|---------|
| **designmaxxing** | `npx designmaxxing extract <url>` | UI reverse engineering: visual, typography, layout, components, animations, 5 breakpoints. Claude Code integration. v0.1.0 | ⭐ MUST |
| **designlang** | `npx designlang <url>` / `npm i -g designlang` | 17+ files: DTCG tokens, Tailwind, shadcn, Figma vars, motion, anatomy, brand voice. MCP + CLI + Chrome Ext. 44 releases, 895 weekly downloads. Latest: Jun 14 2026 | ⭐ MUST |
| **extract-design-system** | `npx extract-design-system <url>` | Colors, typography, spacing, radii, shadows → tokens.json + tokens.css. MCP server + CLI | ⭐ MUST |

## Tier 2: Chrome Extensions (one-click)

| Tool | What | Verdict |
|------|------|---------|
| **Yoink** | Click element → copy HTML+DeepCSS+Tailwind+JSX+fonts+screenshot | ⭐ MUST |
| **ClonePage** | One click → DESIGN.md with tokens, layout tree, components | ⭐ MUST |
| **Step1** (step1.dev) | Chrome extension, one-click clone, design tokens, React+Tailwind output. Free tier (3 clones), Pro $20/mo | NICE |

## Tier 3: MCP Servers

| Tool | Install | Tools | Risk | Verdict |
|------|---------|-------|------|---------|
| **designlang** (same as CLI) | `npx designlang` | ~5-8 | 🟢 | MUST (also CLI) |
| **extract-design-system** | `npx extract-design-system` | ~3-5 | 🟢 | MUST |
| **@agent360/browser-mcp** | `npx @agent360/browser-mcp` | Full HTML+CSS+assets | 🟡 | NICE (scoped pkg) |

## Recommendation

```
# Programmatic (best for agent workflow)
npx designmaxxing extract https://example.com --modules all
npx designlang https://example.com

# One-click (best for manual use)
→ Install Yoink + ClonePage Chrome Extensions
```

The ecosystem matured rapidly between Mar-Jun 2026. **designmaxxing** and **designlang** are the open-source winners. Both produce design tokens, Tailwind configs, and component specs from any URL.

**Priority for agent**: designmaxxing (CLI, no browser needed) + designlang (MCP integration) complement each other.
