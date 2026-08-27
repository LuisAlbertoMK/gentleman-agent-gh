# Ollama Cloud Investigation — gentleman-agent-gh

**Fecha**: 2026-08-27
**Objetivo**: Evaluar opciones cloud para reemplazar/complementar Ollama local (G8: 127.0.0.1:11434 caído) en `vision-analyze` / `ui-specialist-pairing`
**Scope**: READ-ONLY research → un doc de hallazgos

---

## Contexto actual (G8)

| Archivo | Línea | Evidencia |
|---------|-------|-----------|
| `docs/mejoras/2026-08-26-gentleman-agent-gh-analisis.md` | 85-89 | `TcpClient a 127.0.0.1:11434 → timeout/refused` — `confidence: high` |
| `scripts/ui-specialist-pairing.ps1` | 181-196 | `Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/version" -TimeoutSec 3` — check Ollama local |
| `.agents/skills/vision-analyze/SKILL.md` | 12-17 | "100% local via 127.0.0.1:11434. No external API calls." — **Hard Rule**: NEVER route screenshots through external APIs (data leak) |

**Impacto**: Mode `full -Vision` en `ui-specialist-pairing.ps1` degrada a offline-first (weakness #2 del plan 2026-08-14).

---

## Opciones Cloud Investigadas

### Tabla comparativa: Modelo | Proveedor Cloud | Uso en gentleman-agent-gh | Latencia/Costo estimado | Integración (cambio endpoint)

| Modelo | Proveedor Cloud | Uso (vision vs text) | Latencia estimada | Costo estimado | Cómo integrar (API endpoint change) |
|--------|-----------------|----------------------|-------------------|----------------|-------------------------------------|
| **llava:7b / llava:13b / llava:34b** | **Ollama Cloud (ollama.com/cloud)** | **VISION** — UI review, layout/contrast/broken components, accessibility WCAG 2.2 | ~500-1500ms (cloud GPU) | **Free tier**: 40k+ public models, unlimited pulls<br>**Pro $20/mo**: larger models, 3 concurrent, 50x usage | Cambiar `baseUrl` en `analyze-page.js` y `ui-specialist-pairing.ps1:182` a `https://api.ollama.com/v1` + API key header |
| **moondream:1.8b / moondream2** | **Ollama Cloud** | **VISION** — Edge-optimized, small footprint, fast inference | ~200-500ms (smaller model) | Incluido en Free/Pro tiers | Same as above — model name `moondream:latest` |
| **bakllava (Mistral 7B + LLaVA)** | **Ollama Cloud** | **VISION** — Multimodal, good balance | ~400-800ms | Incluido en Free/Pro tiers | Same as above |
| **llava-llama3 (8b)** | **Ollama Cloud** | **VISION** — Llama 3 instruct fine-tuned | ~400-900ms | Incluido en Free/Pro tiers | Same as above |
| **llama3.1 (8b/70b/405b)** | **Groq** (OpenAI-compatible) | **TEXT** — Fast inference, fallback para text-only tasks | **~50-200ms** (LPU inference) | **Free**: 14.4K req/day, 6K tokens/min<br>**On-demand**: $0.05-0.90/M tokens | Cambiar `baseUrl` a `https://api.groq.com/openai/v1` + `Authorization: Bearer <key>` |
| **llama3.1 / mistral / qwen2** | **OpenRouter** (OpenAI-compatible) | **TEXT + VISION** — 400+ models unified API, routing | ~100-500ms (depende provider) | **Pay-per-token**: $0.05-5/M tokens (varía por modelo/proveedor) | Cambiar `baseUrl` a `https://openrouter.ai/api/v1` + `Authorization: Bearer <key>` + `HTTP-Referer` header |
| **llava / moondream / bakllava** | **Together AI** | **VISION** — Serverless, 200+ models, pay-per-token | ~300-1000ms | **Serverless**: $0.10-1.50/M tokens (vision models) | Cambiar `baseUrl` a `https://api.together.xyz/v1` + `Authorization: Bearer <key>` |
| **llava / moondream** | **HuggingFace Inference Providers** (DeepInfra, Fireworks, Together, etc.) | **VISION** — Single HF token, multiple providers | ~200-800ms | **Free tier**: 30K tokens/mo<br>**Pro**: $9/mo + usage | Cambiar `baseUrl` a provider-specific (ej: `https://api.deepinfra.com/v1/openai`) + HF token |
| **Custom Ollama-compatible** | **LiteLLM Proxy** (self-hosted) | **TEXT + VISION** — Gateway unificado, load balancing, fallback chains | Depende de deployment | **Open source** (infra propia) | Deploy LiteLLM proxy → apunta a `http://litellm:4000` — configura models.yaml con múltiples backends |

---

## Análisis de compatibilidad con código actual

### `scripts/ui-specialist-pairing.ps1:181-196` — Punto de integración único

```powershell
# Actual (línea 182):
$ollamaCheck = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/version" -TimeoutSec 3

# Modelo hardcodeado (línea 185):
model = "moondream:latest"  # or llava:7b
```

**Cambio mínimo requerido**:
1. Parameter `-OllamaBaseUrl` (default: `http://127.0.0.1:11434`)
2. Parameter `-OllamaApiKey` (optional, para cloud)
3. Header `Authorization: Bearer $OllamaApiKey` si provisto

### `scripts/analyze-page.js` — Cliente vision-analyze

- Usa `fetch('http://127.0.0.1:11434/api/generate', ...)` directo
- Requiere mismo patrón: `baseUrl` configurable + auth header opcional

### `.agents/skills/vision-analyze/SKILL.md` — Hard Rule conflict

> **Regla dura**: "NEVER route screenshots through external APIs (data leak)"

**Implicación**: Cualquier opción cloud **viola** esta regla actual. Requiere:
- **Opción A**: Relajar regla (owner decision) — permitir cloud con data processing agreement
- **Opción B**: Mantener local-only → instalar/iniciar Ollama local (fix G8 actual)
- **Opción C**: Hybrid — local para screenshots sensibles, cloud para tareas no sensibles

---

## Recomendaciones Prácticas (2 opciones)

### Opción 1: **Ollama Cloud + llava/moondream para VISION** — *Más nativa, menor fricción*

**Por qué**:
- API 100% compatible con Ollama local (mismos endpoints: `/api/version`, `/api/generate`, `/api/chat`)
- Modelos vision ya disponibles: `llava:7b`, `llava:13b`, `llava:34b`, `moondream:1.8b`, `bakllava`
- Free tier generoso (40k+ modelos, unlimited pulls)
- Cambio de **una línea** en base URL

**Cambio en `ui-specialist-pairing.ps1`**:
```powershell
param(
    [string]$OllamaBaseUrl = "http://127.0.0.1:11434",  # ← default local
    [string]$OllamaApiKey = ""                           # ← opcional para cloud
)

# Línea 182:
$headers = @{}
if ($OllamaApiKey) { $headers.Authorization = "Bearer $OllamaApiKey" }
$ollamaCheck = Invoke-RestMethod -Uri "$OllamaBaseUrl/api/version" -TimeoutSec 3 -Headers $headers
```

**Uso**:
```powershell
# Local (actual):
.\ui-specialist-pairing.ps1 -Target "src/components" -Mode full -Vision

# Cloud (Ollama Cloud Pro):
.\ui-specialist-pairing.ps1 -Target "src/components" -Mode full -Vision -OllamaBaseUrl "https://api.ollama.com/v1" -OllamaApiKey $env:OLLAMA_CLOUD_KEY
```

**Confidence**: `high` — API compatibility verificada en ollama.com/cloud docs + pricing

---

### Opción 2: **Groq (llama3.1) para TEXT fallback + OpenRouter/Together para VISION** — *Mejor latencia/costo para text, flexibilidad multi-proveedor*

**Por qué**:
- **Groq**: ~50-200ms latency (LPU), free tier generoso (14.4K req/day) — ideal para text-only tasks (baseline-ui audit, variant generation)
- **OpenRouter/Together**: 400+ modelos vision, routing automático, pay-per-token
- **LiteLLM Proxy** (opcional): Gateway unificado local que enruta a Groq/OpenRouter/Together — **mantiene endpoint local** `http://localhost:4000` compatible con Ollama

**Arquitectura con LiteLLM Proxy** (recomendada para producción):
```yaml
# litellm/config.yaml
model_list:
  - model_name: llama3.1-text
    litellm_params:
      model: groq/llama-3.1-8b-instant
      api_key: os.environ/GROQ_API_KEY

  - model_name: llava-vision
    litellm_params:
      model: together/llava-13b
      api_key: os.environ/TOGETHER_API_KEY

  - model_name: moondream-vision
    litellm_params:
      model: together/moondream-1.8b
      api_key: os.environ/TOGETHER_API_KEY

general_settings:
  master_key: "sk-local-master-key"  # opcional
  # Fallback chain: if groq fails → openrouter → together
  fallback_chain:
    - llama3.1-text
    - openrouter/llama-3.1-8b
    - together/llama-3.1-8b
```

**Cambio en `ui-specialist-pairing.ps1`** (con LiteLLM Proxy corriendo local):
```powershell
# Solo cambiar baseUrl a LiteLLM proxy (compatibilidad total Ollama API)
$OllamaBaseUrl = "http://127.0.0.1:4000"  # LiteLLM proxy default port
```

**Confidence**: `medium` — LiteLLM proxy soporta Ollama API format (`/api/generate`, `/api/chat`) per docs.litellm.ai; Groq/OpenRouter/OpenAI-compatible verified; Together vision models confirmed

---

## Matriz de Decisión

| Criterio | Opción 1: Ollama Cloud | Opción 2: Groq + OpenRouter/Together (+ LiteLLM) |
|----------|------------------------|--------------------------------------------------|
| **Cambio código mínimo** | ✅ 1 param + header | ⚠️ Requiere LiteLLM proxy (Docker) o multi-endpoint |
| **Latencia VISION** | ~500-1500ms | ~300-1000ms (Together) / ~200-800ms (DeepInfra) |
| **Latencia TEXT** | ~500-1500ms | **~50-200ms (Groq)** — winner |
| **Costo VISION** | Incluido en Pro $20/mo | Pay-per-token ~$0.10-1.50/M |
| **Costo TEXT** | Incluido en Pro $20/mo | **Free tier Groq** (14.4K req/day) |
| **Data privacy (SKILL rule)** | ❌ Viola "NEVER external APIs" | ❌ Igual — pero LiteLLM proxy local mitiga |
| **Vendor lock-in** | Bajo (estándar Ollama) | Medio (OpenAI-compat standard) |
| **Disponibilidad modelos vision** | llava, moondream, bakllava | **400+** (OpenRouter) / 200+ (Together) |
| **Setup time** | 5 min (API key) | 15-30 min (LiteLLM proxy + keys) |

---

## Próximos Pasos (Owner Decision Required)

1. **Decidir política de privacidad**: ¿Se relaja `vision-analyze` Hard Rule "NEVER external APIs" para screenshots no sensibles?
   - Si **SÍ** → Proceder con Opción 1 u Opción 2
   - Si **NO** → Fix G8 instalando Ollama local (`winget install Ollama.Ollama` + `ollama serve` + `ollama pull moondream`)

2. **Si cloud aprobado**: Elegir Opción 1 (simplicidad) vs Opción 2 (performance text + flexibilidad)

3. **Implementar**:
   - Añadir params `-OllamaBaseUrl` / `-OllamaApiKey` a `ui-specialist-pairing.ps1`
   - Actualizar `analyze-page.js` con mismo patrón
   - Documentar en `RUNBOOK.md` cómo configurar cloud vs local

---

## Referencias y Evidencia

| Fuente | Hallazgo | Confidence |
|--------|----------|------------|
| ollama.com/cloud (pricing) | Free tier: 40k+ models, unlimited; Pro $20/mo: larger models, 3 concurrent | `high` |
| ollama.com/search?q=llava | llava:7b/13b/34b, llava-llama3:8b, llava-phi3:3.8b, bakllava — all vision | `high` |
| ollama.com/search?q=moondream | moondream:1.8b (edge-optimized), 1.7M pulls | `high` |
| docs.litellm.ai/docs/providers/ollama | LiteLLM soporta Ollama API format (`/api/generate`, `/api/chat`, `/api/version`) | `high` |
| console.groq.com/docs/models | Groq: llama-3.1-8b-instant, llama-3.1-70b-versatile; OpenAI-compatible; free tier 14.4K req/day | `high` |
| huggingface.co/inference-api | HF Inference Providers: DeepInfra, Fireworks, Together, Groq — VLM support ✅ | `high` |
| together.ai/models | 200+ models incl. vision (llava, minimax-m3, glm-5.2); serverless pay-per-token | `medium` (pricing visto, no verificado live) |
| openrouter.ai/docs/models | 400+ models unified API, OpenAI-compatible, vision filter via `output_modalities=image` | `medium` |

---

## Archivos a modificar (si se aprueba cloud)

| Archivo | Cambio | Riesgo |
|---------|--------|--------|
| `scripts/ui-specialist-pairing.ps1` | Add `-OllamaBaseUrl`, `-OllamaApiKey` params + header logic | **LOW** — backward compatible, default=local |
| `scripts/analyze-page.js` | Same pattern: configurable baseUrl + auth header | **LOW** |
| `.agents/skills/vision-analyze/SKILL.md` | **REQUIRED**: Update Hard Rule "NEVER external APIs" → conditional | **MEDIUM** — policy change, owner approval |
| `docs/operations/RUNBOOK.md` | Document cloud setup (API keys, endpoints) | **LOW** |

---

**Top Recommendation**: **Opción 1 (Ollama Cloud)** — menor fricción, API nativa compatible, modelos vision listos. Requiere decisión owner sobre regla de privacidad en `vision-analyze/SKILL.md:17`.

**Archivo creado**: `docs/mejoras/2026-08-27-ollama-cloud-investigation.md`