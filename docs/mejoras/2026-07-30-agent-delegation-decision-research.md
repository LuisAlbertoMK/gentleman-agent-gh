# Agent Delegation & Decision-Making Research

**Fecha**: 2026-07-30
**Tipo**: Investigación externa multi-fuente
**Método**: 4 subagentes paralelos (websearch + webfetch)
**Fuentes**: Anthropic, OpenAI, Microsoft, GitHub repos, Arxiv, benchmarks, blogs

---

## Resumen Ejecutivo

La investigación cubre 4 dimensiones:
1. **Patrones de delegación** — 6 patrones fundamentales con cuándo usar cada uno
2. **Frameworks de decisión** — ReAct, Plan-Execute, ToT, MoA, Semantic Router
3. **Ecosistema de agentes 2026** — Modelos, frameworks, gateways, tendencias
4. **Repositorios open-source** — GitHub, benchmarks, research papers

**Hallazgo clave**: La arquitectura óptima para un orquestador es **Semantic Router (L0) + Plan-Execute (L1) + ReAct (ejecutor default)**, con Cost-Aware Routing para escalar. El 80% del tráfico debe ir a modelos baratos; solo el 20% complejo merece modelos caros.

---

## 1. Patrones de Delegación de Agentes

### 1.1 Supervisor (Orchestrator-Worker)
- **Qué es**: Un agente supervisor recibe la tarea, la divide en sub-tareas, delega a workers especializados, y consolida resultados.
- **Cuándo**: Tareas complejas con sub-tareas de distinto expertise. El plan se construye dinámicamente.
- **Pros**: Desacoplamiento total, workers reemplazables, escalabilidad horizontal.
- **Cons**: Overhead de coordinación (tokens del supervisor), latencia secuencial, riesgo de bottleneck.
- **Fuente**: [Anthropic — Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)

### 1.2 Router Pattern
- **Qué es**: Clasificador (LLM o reglas) que enruta el input al handler especializado. Dispatch puro, sin recursión.
- **Cuándo**: Inputs con categorías mutuamente excluyentes (FAQ → barato, bug → caro, escalada → humano).
- **Pros**: Simple, bajo overhead (1 call), fácil de auditar, routing por costo.
- **Cons**: No cruza categorías; el router puede clasificar mal; sin feedback loop.
- **Variantes**: LLM-as-router, deterministic router, hybrid router.
- **Fuente**: [BuildingEffectiveAgents.com — Routing](https://buildingeffectiveagents.com/patterns/routing/)

### 1.3 Hierarchical (Tree Delegation)
- **Qué es**: Árbol de N niveles. Raíz → supervisores intermedios → workers. Cada nivel más especializado.
- **Cuándo**: Workflows enterprise con dominios anidados.
- **Pros**: Escala a organizaciones grandes, aislamiento de contexto por nivel.
- **Cons**: Latencia acumulativa, difícil de debuggear, context fragmentation.
- **Fuente**: [Microsoft — AI Agent Orchestration](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns)

### 1.4 Prompt Chaining
- **Qué es**: Secuencia lineal donde cada paso recibe el output del anterior. Sin bifurcación.
- **Cuándo**: Etapas secuenciales claras: outline → draft → revise; parse → validate → transform.
- **Pros**: Más barato, fácil de debuggear, error acotado a un paso.
- **Cons**: Frágil (un paso falla = toda la cadena), latencia suma de pasos, sin paralelismo.
- **Fuente**: [BuildingEffectiveAgents.com — Chaining](https://buildingeffectiveagents.com/patterns/prompt-chaining/)

### 1.5 Parallelization
- **Qué es**: Fan-out a N calls independientes, luego agregación. Dos sabores: sectioning (sub-tareas distintas) y voting (misma tarea, N intentos).
- **Cuándo**: Sub-partes independientes o alta confianza requerida.
- **Pros**: Velocidad (paralelo), robustez (voting).
- **Cons**: Costo N×, agregación puede ser ruidosa.
- **Fuente**: [BuildingEffectiveAgents.com — Parallelization](https://buildingeffectiveagents.com/patterns/parallelization/)

### 1.6 Evaluator-Optimizer
- **Qué es**: Ciclo generador → evaluador → feedback. El generador produce, el evaluador critica, el generador mejora. Loop hasta pasar threshold.
- **Cuándo**: Calidad iterativa necesaria (traducciones, code review, writing).
- **Pros**: Calidad mejora con cada iteración, criterio explícito.
- **Cons**: 2× calls por iteración, puede no converger, latencia variable.
- **Fuente**: [BuildingEffectiveAgents.com — Evaluator-Optimizer](https://buildingeffectiveagents.com/patterns/evaluator-optimizer/)

---

## 2. Cuándo Usar Generalista vs Especialista

| Factor | Generalista | Especialista | Threshold |
|--------|------------|--------------|-----------|
| **Costo por call** | Bajo ($0.14-$1.00/M tok) | Alto ($5-$50/M tok) | ~1000 calls/día: especialista paga dev |
| **Latencia requerida** | Milisegundos | Segundos-minutos | <500ms → generalista |
| **Complejidad** | Simple/factual/repetitivo | Razonamiento/creativo/técnico | >3 pasos de razonamiento → especialista |
| **Tasa de error tolerable** | Alta (aceptable 10-20%) | Baja (exigencia <5%) | <5% error → especialista |
| **Volumen** | Alto (80%+ del tráfico) | Bajo (20% del tráfico) | Pareto: 80/20 |
| **Contexto necesario** | Pequeño (<10K tokens) | Grande (>50K tokens) | >50K → especialista con ventana grande |
| **Herramientas requeridas** | 1-2 tools simples | Múltiples tools complejas | >3 tools → especialista |
| **Especialización de dominio** | Baja | Alta | Código legal/médico/científico → especialista |

**Regla práctica**: Si una tarea se resuelve con 1-2 calls de LLM + 1 tool simple → generalista. Si requiere planificación, múltiples tools, o razonamiento multi-paso → especialista.

---

## 3. Frameworks de Decisión para Orquestadores

| Framework | Tipo | Latencia | Calidad | Costo | Mejor para |
|-----------|------|----------|---------|-------|------------|
| **ReAct** | Ciclo reactivo | Media | Alta | Bajo-Medio | Tool-using, grounding externo |
| **Plan-Execute** | 2-fase secuencial | Alta | Muy Alta | Medio-Alto | Tareas multi-paso complejas |
| **Tree-of-Thoughts** | Búsqueda arbórea | Muy Alta | Máxima (exploratoria) | Alto | Branching necesario |
| **MoA** | Ensemble en capas | Muy Alta | Máxima (agregativa) | Muy Alto | Quality crítica |
| **Semantic Router** | Clasificación vectorial | Muy Baja | N/A (router) | Mínimo | Routing ultra-rápido pre-LLM |
| **Cost-Aware Routing** | Clasificador + fallback | Baja | Alta (con fallback) | Bajo | Escalado económico en producción |

### Arquitectura Recomendada

```
┌──────────────┐
│  Input Query  │
└──────┬───────┘
       ▼
┌──────────────────────────┐
│  L0: Semantic Router      │  ← ~1ms, embedding-based
│  (clasifica rápido/caro)   │
└──────┬───────────────────┘
       │
   ┌───┴────┐
   ▼        ▼
  Barato   Caro
  (80%)    (20%)
  ReAct    Plan-Execute
  simple   con sub-agentes
```

**Lógica**:
- **L0**: Semantic Router clasifica en ~1ms. Query simple/factual → ReAct barato. Query compleja → Plan-Execute caro.
- **L1**: Modelo caro genera plan multi-paso. Cada paso se ejecuta con ReAct, delegando a sub-agentes si la confianza es baja.
- **Cost budget**: Token budget por request. Si se excede, replanificar o escalar.
- **ToT/MoA**: Solo para casos extremos de calidad (research, debugging crítico).

**Ahorro estimado**: 60-70% de costo vs usar modelo caro siempre.

---

## 4. Ecosistema de Agentes 2026

### Modelos Comparados (Julio 2026)

| Modelo | Contexto | Input $/1M tok | Output $/1M tok | Calidad | Best para |
|--------|----------|----------------|-----------------|---------|-----------|
| **Claude Opus 5** | 200K | $5.00 | $25.00 | ★★★★★ | Agentes complejos, coding profundo |
| **Claude Fable 5** | 200K | $10.00 | $50.00 | ★★★★★ | Razonamiento extremo, research |
| **Claude Sonnet 5** | 200K | $2.00-3.00 | $10-15 | ★★★★☆ | Sweet spot calidad/precio |
| **GPT-5.6 Sol** | 128K-1M | $5.00 | $30.00 | ★★★★★ | Tool use, multi-step |
| **GPT-5.6 Terra** | 128K-1M | $2.50 | $15.00 | ★★★★☆ | Producción balanceado |
| **GPT-5.6 Luna** | 128K-1M | $1.00 | $6.00 | ★★★☆☆ | Tareas simples, bajo costo |
| **Gemini 3.1 Pro** | 1M-2M | $2.00 | $12.00 | ★★★★★ | Ventanas largas, multimodal |
| **Gemini 3.5 Flash** | 1M+ | $1.50 | $9.00 | ★★★★☆ | Streaming, baja latencia |
| **DeepSeek V4 Pro** | 128K+ | $0.44 | $0.87 | ★★★★☆ | Costo ultra-bajo, coding |
| **DeepSeek V4 Flash** | 128K+ | $0.14 | $0.28 | ★★★☆☆ | Budget máximo, high-volume |
| **Llama 4** | 128K+ | ~$0.20 | ~$0.60 | ★★★☆☆ | Open-source, self-host |
| **Grok 3** | 128K+ | $3.00 | $12.00 | ★★★★☆ | Reasoning, X integration |

*DeepSeek V4 Flash es ~178× más barato que Claude Fable 5.*

### Frameworks de Agentes

| Framework | Patrón | Multi-agente? | Strengths |
|-----------|--------|---------------|-----------|
| **LangGraph** | Graph state machine | Sí | Control granular, checkpoints, persistencia |
| **CrewAI** | Role-based teams | Sí (nativo) | Curva baja, backstories, productivo en horas |
| **AutoGen** (→MAF) | Conversacional | Sí (GroupChat) | Docker sandbox, speaker selection |
| **OpenAI Agents SDK** | Primitives | Sí (handoffs) | Minimalista, tracing built-in |
| **Claude Agent Toolkit** | Tool-use loops | Limitado | MCP nativo, safety layers |
| **Google ADK** | Modular pipelines | Sí | Gemini + MCP + A2A, 1M+ context |
| **Agno** | Multi-modal | Sí | Memoria, knowledge, 5 niveles |
| **Pydantic AI** | Type-safe | Sí | Logfire observability, outputs estructurados |

### Model Routing / Gateways

| Herramienta | Feature única |
|-------------|---------------|
| **LiteLLM** | 100+ providers, self-hosted proxy, routing + fallbacks + cost tracking (22k★) |
| **Portkey** | Semantic caching, guardrails, 1600+ modelos |
| **OpenRouter** | Auto-fallback entre providers, price-based routing |
| **Helicone** | Observability open-source, logging, caching, rate limiting |
| **LangFuse** | Tracing open-source, prompt management, experiments |

### Tendencias Clave 2026

1. **Protocol Stack consolidado**: MCP es estándar de facto para tool-use. A2A v1.0 (150+ orgs) para agent-to-agent. WebMCP extiende al browser.
2. **Guerra de precios**: DeepSeek Flash $0.14 vs Claude Fable $50 = factor 178×. Routing estratégico obligatorio.
3. **Function calling nativo**: Todos los modelos frontier tienen tool use optimizado. El desafío ya no es "cómo" sino "cuándo y a qué costo".
4. **Multi-agent maduró**: El debate ya no es mono vs multi, sino qué patrón: graph, role-based, conversational, o handoff.
5. **Enterprise adoption**: Snowflake, Dremio, Databricks operan managed MCP servers. Gestión de identidad y permisos para agentes.

---

## 5. Repositorios Open-Source Clave

### Agent Orchestration

| Repo | Stars | Patrón | Lenguaje |
|------|-------|--------|----------|
| [anthropics/claude-code](https://github.com/anthropics/claude-code) | ~115k | Agent tool use nativo | TS |
| [microsoft/autogen](https://github.com/microsoft/autogen) | ~57k | Multi-agent (maintenance → MAF) | Python |
| [crewAIInc/crewAI](https://github.com/crewAIInc/crewAI) | ~55k | Role-based agents | Python |
| [Agentopia/Agno](https://github.com/Agentopia/Agno) | ~41k | Full-stack multi-agent | Python |
| [langchain-ai/langgraph](https://github.com/langchain-ai/langgraph) | ~38k | Graph-based stateful | Python |
| [huggingface/smolagents](https://github.com/huggingface/smolagents) | ~29k | Code-first agents | Python |
| [openai/swarm](https://github.com/openai/swarm) | ~22k | Experimental handoff | Python |

### Decision/Routing

| Repo | Stars | Función |
|------|-------|---------|
| [microsoft/semantic-kernel](https://github.com/microsoft/semantic-kernel) | ~28k | Planner + plugins (→MAF) |
| [Portkey-AI/gateway](https://github.com/Portkey-AI/gateway) | ~13k | AI Gateway, 1600+ LLMs |
| [microsoft/agent-framework](https://github.com/microsoft/agent-framework) | ~13k | Sucesor AutoGen+SK |

### Benchmarks

| Benchmark | Mide | Leaderboard top (Jul 2026) |
|-----------|------|---------------------------|
| [SWE-bench Verified](https://www.swebench.com/) | Issues reales GitHub | Claude Opus 5 — **96%** |
| [GAIA](https://huggingface.co/spaces/gaia-benchmark/leaderboard) | Tareas multi-step reales | Claude Mythos 5 — **52.3%** |
| [BFCL V4](https://gorilla.cs.berkeley.edu/leaderboard.html) | Function calling precision | — |
| [Chatbot Arena](https://lmarena.ai/) | Preferencia humana (ELO) | LMSYS |

### Research Papers

| Paper | Concepto | Año |
|-------|----------|------|
| [ReAct: Synergizing Reasoning and Acting](https://arxiv.org/abs/2210.03629) | Thought→Action→Observation cycle | 2023 |
| [Tree of Thoughts](https://arxiv.org/abs/2305.10601) | Búsqueda arbórea de razonamiento | 2023 |
| [Mixture of Agents](https://arxiv.org/abs/2406.04692) | MoA en capas, SOTA AlpacaEval 2.0 | 2024 |
| [Self-MoA](https://arxiv.org/abs/2502.00674) | Un solo modelo fuerte agrega mejor que mezclar varios | 2025 |

---

## 6. Implicaciones para el Orchestrator

### Cómo decidir mejor HOY

Basado en la investigación, estas son las mejores prácticas aplicables:

1. **Router con 3 vías**:
   - **Rápido** (DeepSeek Flash / GPT Luna): queries factuales, simple, <2 steps
   - **Balanceado** (Sonnet 5 / GPT Terra): código, debugging normal, 2-5 steps
   - **Experto** (Opus 5 / GPT Sol): razonamiento complejo, >5 steps, quality crítica

2. **Thresholds concretos**:
   - Si la tarea requiere **1 tool call** → agente rápido
   - Si requiere **2-3 tool calls** → agente balanceado
   - Si requiere **>3 tool calls o planificación** → agente experto

3. **Cost budget por tarea**:
   - Tareas simples: max $0.01/task (DeepSeek Flash)
   - Tareas moderadas: max $0.10/task (Sonnet 5)
   - Tareas complejas: max $1.00/task (Opus 5)
   - Si se excede el budget → escalar o reportar

4. **Patrón dominante**: Supervisor (Orchestrator-Worker) para tareas multi-paso. Router para dispatch simple. Parallelization para investigación/exploración.

### Fuentes

- https://www.anthropic.com/engineering/building-effective-agents
- https://www.anthropic.com/engineering/multi-agent-research-system
- https://buildingeffectiveagents.com/
- https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns
- https://arxiv.org/abs/2210.03629 (ReAct)
- https://arxiv.org/abs/2305.10601 (ToT)
- https://arxiv.org/abs/2406.04692 (MoA)
- https://arxiv.org/abs/2502.00674 (Self-MoA)
- https://callsphere.ai/blog/ai-agent-framework-comparison-2026
- https://www.developersdigest.tech/blog/frontier-model-api-pricing-june-2026
- https://www.developersdigest.tech/blog/llm-router-comparison-2026
- https://ingestthis.com/posts/2026/2026-07-06-state-of-agentic-ai-standards-2026
- https://github.com/microsoft/autogen
- https://github.com/crewAIInc/crewAI
- https://github.com/langchain-ai/langgraph
- https://github.com/openai/swarm
- https://github.com/Portkey-AI/gateway
