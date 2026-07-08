# OpenCode Ecosystem Research — July 2026

> **Scope**: MCP servers, skills, patterns & tools integrable into gentleman-agent-gh
> **Method**: Web search, GitHub topic scan, npm registry, MCP marketplace
> **Ponytail**: Rungs 0-3 (feasibility, YAGNI, stdlib, dep check)

---

## 1. MCP Servers

### 1.1 codebase-memory-mcp ★ HIGHEST IMPACT

| Field | Value |
|-------|-------|
| **Description** | Indexes codebases into a persistent knowledge graph via tree-sitter AST (158 languages). Single static C binary, zero deps. 14 MCP tools: search code, call chains, HTTP routes, dead code detection, Cypher-like graph queries. **~120× fewer tokens** vs grep/read (3.4K vs 412K for 5 structural queries). |
| **Url** | `https://github.com/DeusData/codebase-memory-mcp` (26K+ stars) |
| **Install** | Download binary → `./codebase-memory-mcp install` (auto-detects OpenCode) |
| **Impact** | **10/10** — Our 69+ skills with cross-references (skill-graph, skill-spector, etc.) would benefit enormously. Instead of re-reading SKILL.md files, the agent queries a graph. The `install` command auto-configures OpenCode. |
| **Effort** | **2/10** — Single binary, `install` does everything. Zero config. |
| **Note** | arXiv paper (arXiv:2603.27277): 83% answer quality, 10× fewer tokens vs file-by-file. |

### 1.2 opencode-browser (Browser MCP)

| Field | Value |
|-------|-------|
| **Description** | Browser automation plugin for OpenCode via Browser MCP. 6 tools: navigate, fill forms, click elements, extract content, execute JS, screenshot. Speed-oriented prompt injection, compaction-safe. |
| **Url** | `https://github.com/michaljach/opencode-browser` (60 ★) / `npm:opencode-browser-mcp` |
| **Install** | `npx opencode-browser init` — auto-creates `opencode.json` entries |
| **Impact** | **7/10** — Can automate browser testing for web-based tools. Could verify GH workflow pages, check skill formatting in web UIs. |
| **Effort** | **3/10** — Requires Browser MCP extension in Chrome/Edge. Otherwise plug-and-play. |

### 1.3 Playwright MCP (@playwright/mcp)

| Field | Value |
|-------|-------|
| **Description** | Microsoft's official Playwright MCP server. Multi-browser (Chromium, Firefox, WebKit). Uses accessibility snapshots (not brittle CSS selectors). |
| **Url** | `https://github.com/microsoft/playwright-mcp` / `npx @playwright/mcp` |
| **Install** | Add to `opencode.json` as local MCP with `npx -y @playwright/mcp@latest` |
| **Impact** | **6/10** — More mature than opencode-browser but not OpenCode-specific. Good for cross-browser testing scripts. |
| **Effort** | **4/10** — Need to install browsers (`npx playwright install chromium`). Context overhead. |

### 1.4 Memory MCP (@modelcontextprotocol/server-memory)

| Field | Value |
|-------|-------|
| **Description** | Knowledge graph-based persistent memory. Entities, relations, observations. SQLite-backed. Lightweight stdio server. |
| **Url** | `https://github.com/modelcontextprotocol/servers/tree/main/src/memory` / `@modelcontextprotocol/server-memory` |
| **Install** | `npx -y @modelcontextprotocol/server-memory` |
| **Impact** | **5/10** — Replaces our engram system partially. Simpler but less sophisticated. Good fallback. |
| **Effort** | **2/10** — One npm package. But engram already does more (session summaries, dreaming, bias calibration). |

### 1.5 MemoryGraph (memory-graph/memory-graph)

| Field | Value |
|-------|-------|
| **Description** | Python-based graph DB MCP memory server. Zero config, 8 backends (SQLite, Neo4j, FalkorDB, SurrealDB, etc.). Auto-memory on git commit/bug fix/release. |
| **Url** | `https://github.com/memory-graph/memory-graph` (213 ★) / `pipx install memorygraphMCP` |
| **Install** | `pipx install memorygraphMCP` then add to OpenCode as local MCP |
| **Impact** | **4/10** — Interesting but Python dependency in a Go/TS/PS1 repo. Engram is already more integrated. |
| **Effort** | **5/10** — Python runtime, pipx, multi-backend config. |

### 1.6 Filesystem MCP (@modelcontextprotocol/server-filesystem)

| Field | Value |
|-------|-------|
| **Description** | Reference filesystem MCP with roots-based dynamic access control. Read/write/search/move files. |
| **Url** | `@modelcontextprotocol/server-filesystem` (314K weekly downloads) |
| **Install** | `npx -y @modelcontextprotocol/server-filesystem /allowed/path` |
| **Impact** | **3/10** — OpenCode already has built-in file ops. Only useful if we want sandboxed access for subagents. |
| **Effort** | **1/10** — Trivial to add. Redundant with built-in tools. |

---

## 2. Memory & Knowledge Plugins

### 2.1 Hindsight (@vectorize-io/opencode-hindsight)

| Field | Value |
|-------|-------|
| **Description** | SOTA persistent memory for OpenCode. 3 tools: `hindsight_retain`, `hindsight_recall`, `hindsight_reflect`. Auto-retain on idle, memory injection on session start, compaction hooks. Self-hosted or cloud. |
| **Url** | `https://github.com/vectorize-io/hindsight` / `npm:@vectorize-io/opencode-hindsight` |
| **Install** | Add `"plugin": ["@vectorize-io/opencode-hindsight"]` to `opencode.json`. 0.2.5 latest. |
| **Impact** | **8/10** — State-of-the-art on LongMemEval. Could replace our hand-rolled engram for memory retrieval while keeping skill logic. Auto-retain + compaction hooks are exactly what we need. |
| **Effort** | **4/10** — Requires Hindsight server (self-host Docker or cloud). Plugin is simple but adds a dependency. Needs migration from current engram format. |

### 2.2 opencode-mem (tickernelz)

| Field | Value |
|-------|-------|
| **Description** | Local-first memory plugin. SQLite + USearch vector index. Zero cloud deps. Auto-builds user profile from interactions. Privacy-first. |
| **Url** | `https://github.com/tickernelz/opencode-mem` / `npm:opencode-mem` |
| **Install** | `"plugin": ["opencode-mem"]` in `opencode.json` |
| **Impact** | **7/10** — Local-only = no server to run. Auto-profile learning is unique. Lightweight. |
| **Effort** | **2/10** — Plugin install, zero infra. |

### 2.3 opencode-supermemory

| Field | Value |
|-------|-------|
| **Description** | Cloud-based persistent memory via Supermemory API. `/supermemory-init` command, keyword detection, smart compaction at 80%. |
| **Url** | `https://github.com/supermemoryai/opencode-supermemory` / `npm:opencode-supermemory` |
| **Install** | `bunx opencode-supermemory@latest install` |
| **Impact** | **4/10** — Cloud dependency, API key needed. Our engram is more self-contained. |
| **Effort** | **4/10** — Requires Supermemory account + API key. |

---

## 3. Skill Collections

### 3.1 opencode-skills-collection (FrancoStino)

| Field | Value |
|-------|-------|
| **Description** | npm plugin bundling 1595+ universal skills. **SkillPointer architecture** — skills organized into ~35 category pointers instead of 1000+ files, saving ~80K tokens at startup. Risk filter, content scanner, vault manager, patcher pipeline. |
| **Url** | `https://github.com/FrancoStino/opencode-skills-collection` / `npm:opencode-skills-collection` (v3.0.39) |
| **Install** | `"plugin": ["opencode-skills-collection"]` in `opencode.json` |
| **Impact** | **9/10** — The SkillPointer pattern solves our token budget problem with 69+ skills. Instead of loading all skills at startup (compaction loops), we'd use pointers. Risk filter + patcher pipeline could replace parts of skill-spector. |
| **Effort** | **6/10** — Would need to adapt our skills to their vault format or implement SkillPointer ourselves. Not drop-in — our skills have cross-references (skill-graph). |

### 3.2 VoltAgent/awesome-agent-skills

| Field | Value |
|-------|-------|
| **Description** | 27K+ stars, 1000+ community skills across categories. Compatible with OpenCode, Claude Code, Codex, Gemini CLI. |
| **Url** | `https://github.com/VoltAgent/awesome-agent-skills` |
| **Install** | Clone to `~/.config/opencode/skills/` |
| **Impact** | **6/10** — Signal-to-noise ratio unknown. Many skills may conflict with our curated set. Could cherry-pick specific ones (code review, testing, devops). |
| **Effort** | **5/10** — Review + curation effort. Need to check for quality and conflicts. |

### 3.3 weisser-dev/awesome-opencode

| Field | Value |
|-------|-------|
| **Description** | 108 agents, 15 skills, 18 curated MCP servers, smart model detection. Interactive CLI: `npx @weisser-dev/awesome-opencode`. |
| **Url** | `https://github.com/weisser-dev/awesome-opencode` (13 ★) |
| **Install** | `npx @weisser-dev/awesome-opencode` |
| **Impact** | **5/10** — Interesting init/setup workflow. MCP server list could supplement our config. |
| **Effort** | **2/10** — Just run the CLI. But value per skill is lower than our curated set. |

### 3.4 open-hax/opencode-skills

| Field | Value |
|-------|-------|
| **Description** | DevSecOps-focused skills collection: free infrastructure discovery across cloud, CI/CD, security, monitoring, DNS, storage, auth. |
| **Url** | `https://github.com/open-hax/opencode-skills` (5 ★) |
| **Install** | Symlink `.opencode/skills/` into workspace |
| **Impact** | **4/10** — Niche DevSecOps skills. Useful if we want to automate free-tier infra discovery during setup. |
| **Effort** | **3/10** — Clone + symlink. |

### 3.5 jshsakura/awesome-opencode-skills

| Field | Value |
|-------|-------|
| **Description** | Auto-synced port of 136+ Codex subagents → OpenCode SKILL.md format. Weekly sync from VoltAgent upstream. |
| **Url** | `https://github.com/jshsakura/awesome-opencode-skills` |
| **Install** | `irm ...install.ps1 | iex` (Windows) or clone to skills dir |
| **Impact** | **4/10** — 1:1 port may miss OpenCode-specific patterns. Auto-sync is nice but quality varies. |
| **Effort** | **3/10** — One-liner install. |

---

## 4. Developer Tools

### 4.1 PSScriptAnalyzer (Microsoft)

| Field | Value |
|-------|-------|
| **Description** | Official PowerShell static analysis/linter. 60+ built-in rules: uninitialized vars, Invoke-Expression detection, PSCredential usage, code formatting. v1.25.0 (13M+ downloads). We already use limited rules via `pssa-gate.ps1`. |
| **Url** | `https://github.com/PowerShell/PSScriptAnalyzer` / PSGallery: `Install-Module PSScriptAnalyzer` |
| **Install** | `Install-Module -Name PSScriptAnalyzer -Force` |
| **Impact** | **8/10** — We already use it but should formalize: custom ruleset `gentleman-standard.psd1`, CI integration via `PSModule/Invoke-ScriptAnalyzer@v2` GH Action, and enforce in pre-commit gate. |
| **Effort** | **3/10** — Already installed. Need to write custom ruleset and wire CI. |

### 4.2 Invoke-ScriptAnalyzer GitHub Action

| Field | Value |
|-------|-------|
| **Description** | GH Action wrapping PSScriptAnalyzer. Runs lint on push/PR. MIT license. |
| **Url** | `https://github.com/PSModule/Invoke-ScriptAnalyzer` (v4.1.3) |
| **Install** | Add step to `.github/workflows/` workflow |
| **Impact** | **7/10** — Formal CI linting gate. Catches issues before they reach `pssa-gate.ps1`. |
| **Effort** | **2/10** — Add 10 lines to existing workflow. |

---

## 5. Patterns & Architecture

### 5.1 SkillPointer Pattern

| Field | Value |
|-------|-------|
| **Description** | Categorize skills into ~35 pointer files instead of loading 1000+ individually. Saves ~80K tokens at startup. Vault stores raw skills, pointers reference them. Pioneered by `opencode-skills-collection`. |
| **Url** | Implemented in `opencode-skills-collection` (FrancoStino) |
| **Impact** | **9/10** — Our 69+ skills cause compaction loops. SkillPointer would reduce startup from ~5.5K tokens (69 descriptions) to ~255 tokens (35 pointers). |
| **Effort** | **7/10** — Need to: (1) build vault structure, (2) write pointer generator, (3) update our skill-graph to work with pointers, (4) maintain sync between vault and pointers. Significant but high ROI. |

### 5.2 MCP Gateway Pattern

| Field | Value |
|-------|-------|
| **Description** | Single gateway endpoint that brokers access to multiple MCP tools. Instead of 10 MCP servers × 20K tokens each, expose meta-tools (search, planner) that lazily load specific tools. Composio (1000+ integrations) and Arcade.dev (OAuth gateway) are commercial examples. |
| **Url** | `https://composio.dev` / `https://arcade.dev` |
| **Impact** | **5/10** — We don't have 10+ MCP servers. Useful if we add GitHub, Jira, Slack, etc. The concept of "lazy loading via search tool" is worth adopting regardless. |
| **Effort** | **6/10** — For self-hosted, need to build the gateway. Commercial options add cost and dependency. |

### 5.3 Hybrid LSP + Knowledge Graph

| Field | Value |
|-------|-------|
| **Description** | codebase-memory-mcp uses tree-sitter AST + LSP type resolution for deeper code understanding. Go, Python, TS, Rust types resolved via Language Server Protocol then embedded in graph. |
| **Url** | Implemented in codebase-memory-mcp (DeusData) |
| **Impact** | **7/10** — Our PowerShell scripts lack this kind of structural analysis. For a PowerShell-heavy repo, a PS-only graph would help trace function calls across scripts. |
| **Effort** | **5/10** — Comes free with codebase-memory-mcp. PowerShell parser support in tree-sitter may be limited. |

---

## Priority Recommendations

### DO THIS WEEK
1. **[codebase-memory-mcp]** Download binary, run `install`, use it for skill development. Single biggest win. Auto-configures OpenCode.
2. **[PSScriptAnalyzer ruleset]** Write `gentleman-standard.psd1` custom ruleset, add GH Action.

### DO THIS MONTH
3. **[SkillPointer]** Implement vault + pointer pattern for our 69+ skills. Target: ~400 tokens at startup instead of ~5.5K.
4. **[opencode-mem]** Local-first memory plugin. Replace engram's storage layer while keeping our custom logic (dreaming, bias calibration, session miner).

### EVALUATE
5. **[Hindsight]** If engram migration proves too complex, Hindsight is the superior memory backend (SOTA benchmarks, auto-retain, compaction hooks).
6. **[opencode-browser]** For testing web-based setup scripts or GH action verification.
7. **[VoltAgent skills]** Cherry-pick specific skills (code review, testing) instead of full sweep.

### SKIP (redundant or low ROI)
- Memory MCP (engram already does more)
- Filesystem MCP (built-in tools suffice)
- opencode-supermemory (cloud-dep, less control)
- Kronvex (immature, 1 install)
