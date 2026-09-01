# R2-3 — Minado de awesome-opencode registry (8,947★, 643 forks)

> **Método**: fetch `awesome-opencode/awesome-opencode` (67 secciones, 182KB) + 4 candidatos fetchados (honcho, claude-memory, conclave, dynamic-workflows). KB `r2-awesome-opencode-github`, `r2-honcho`, `r2-claude-memory`, `r2-conclave`, `r2-dynamic-workflows` (total ~280KB en KB, 5 fuentes). Investigación 2026-09-01.

## Candidatos evaluados

### 1. `plastic-labs/opencode-honcho` — AI-native long-term memory (memory persistence)

- **Qué**: Memoria que sobrevive context wipes, session restarts, fresh chats. Session strategies: `per-directory` (default), `per-repo`, `git-branch`, `per-session`, `chat-instance`, `global`.
- **vs nuestro Engram**: Engram es custom FTS5 + graph + engram-protocol skill (28 checkpoints 847→878). Honcho es más maduro (cloud/self-hosted, estrategias configurables). **Overlap 80%**.
- **Veredicto**: **No adoptar ahora**. Engram ya cubre y tiene 20+ commits de integración. Honcho sería reemplazo, no complemento, con costo de migración. Piloto opcional si Engram limita.

### 2. `kuitos/opencode-claude-memory` — Claude Code-compatible Markdown memory (memory)

- **Qué**: Plugin npm que comparte Markdown memory entre OpenCode y Claude Code (zero config, no migration). `Claude Code writes → OpenCode reads` y viceversa.
- **vs Engram**: Engram es estructurado (graph, search, topic_key); claude-memory es Markdown plano para interoperabilidad entre CLIs.
- **Veredicto**: **Complemento ligero opcional**. Útil si usás ambos CLIs (OpenCode + Claude Code) y querés memoria visible como Markdown. Para solo OpenCode, Engram es superior.

### 3. `Suraj1235/open-dynamic-workflows` — Script-as-orchestrator (multi-agent orchestration) ⭐ TOP CANDIDATE

- **Qué**: Engine MIT que lleva dynamic workflows + ultracode a OpenCode (y Cursor, Codex, Gemini, Kimi, Zed). **Script JS generado como orquestador** (vs LLM turn-by-turn). Features:
  - Parallel agents up to hardware (default 16)
  - Crash-resume via SQLite + WAL
  - Adversarial verification built-in
  - QuickJS-WASM sandbox, bring your own model (Anthropic/OpenAI/Ollama)
  - Local-first, $0 + tokens

- **vs nuestro `delivery-harness`**: Nuestro harness hace `break → delegate (clusters ≤10) → verify → synthesize` con bash. Dynamic-workflows hace lo mismo pero con **script generado, sandbox, y crash-resume** — es la versión productizada de nuestro patrón.
- **Veredicto**: **Evaluar piloto en 1-2 sesiones** si tu harness se queda corto en crash-resume o paralelismo >10. Para tu caso actual (harness funciona, gate 26/26), **no es urgente** — es el único candidato que podría reemplazar una pieza core con beneficio medible.

### 4. `martinzokov/open-conclave` — Multi-agent debates (captain moderated)

- **Qué**: N agentes responden misma query con prompts distintos (lógico, creativo, research), capitán modera hasta consenso. Estilo Grok 4.20.
- **vs delivery-harness**: Nosotros delegamos por **dominio** (security→gentleman-security), no por debate. Conclave es para consenso en preguntas abiertas, no para work-units de código.
- **Veredicto**: **No adoptar** — patrón no encaja con T2+ descomposición por archivos.

## Recomendación

**No adoptar ninguno de forma inmediata** — tu stack actual (`Engram` + `delivery-harness` + `skill-graph` + `context-watchdog LCM DAG`) ya cubre los dos casos de uso (memory + orchestration) y está validado con 20+ commits hoy. **R2-3 se cierra como "evaluado, sin adopción"** con 2 candidatos en backlog para piloto futuro si aparece limitación:
  - Si Engram limita → piloto `honcho` (1 sesión)
  - Si delivery-harness limita (crash sin resume) → piloto `open-dynamic-workflows` (1-2 sesiones)

> **Esfuerzo invertido**: 1 sesión de minado (4 fetches + KB). ROI: evita construir desde cero y evita adoptar por hype.
