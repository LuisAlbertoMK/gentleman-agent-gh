# Model Availability — OpenCode GO

> **Last Verified**: 2026-07-05
> **Source**: `opencode models` command output
> **Status**: All models verified as available

---

## Available Models (18 total)

### Free Tier (opencode/*)
| ID | Model | Risk | Notes |
|---|---|---|---|
| `opencode/big-pickle` | Big Pickle | Low | Production, long sessions, stable |
| `opencode/deepseek-v4-flash-free` | DeepSeek V4 Flash | Medium | Trial, may disappear |
| `opencode/mimo-v2.5-free` | MiMo V2.5 | High | Trial, exploration only |
| `opencode/nemotron-3-ultra-free` | Nemotron 3 Ultra | High | Trial, one-off only |
| `opencode/north-mini-code-free` | North Mini Code | Medium | Trial, code tasks |

### Pro Tier (opencode-go/*)
| ID | Model | Cost | Strength | Use For |
|---|---|---|---|---|
| `opencode-go/qwen3.7-max` | Qwen3.7 Max | High | Complex reasoning, vulnerability detection | Security, performance analysis |
| `opencode-go/qwen3.7-plus` | Qwen3.7 Plus | Medium | Content generation, 1M context | SEO, content strategy |
| `opencode-go/qwen3.6-plus` | Qwen3.6 Plus | Medium | General purpose | Fallback for Qwen3.7 |
| `opencode-go/glm-5.2` | GLM-5.2 | High | Logical reasoning, IaC precision | Infrastructure, critical plans |
| `opencode-go/glm-5.1` | GLM-5.1 | Medium | Mathematical precision, data analysis | Data science, statistical analysis |
| `opencode-go/kimi-k2.6` | Kimi K2.6 | Medium | Long context (1M), frontend consistency | Frontend, UI/UX analysis |
| `opencode-go/kimi-k2.7-code` | Kimi K2.7 Code | Medium | Code generation, frontend | Alternative to K2.6 |
| `opencode-go/mimo-v2.5-pro` | MiMo V2.5 Pro | Low | **Best instruction follower** | Documentation, plan implementation |
| `opencode-go/mimo-v2.5` | MiMo V2.5 | Very Low | Speed, quick edits | Fast tasks (trial) |
| `opencode-go/minimax-m2.7` | MiniMax M2.7 | Very Low | Speed, frontend | Fast UI implementation |
| `opencode-go/minimax-m3` | MiniMax M3 | Low | General purpose | Fallback |
| `opencode-go/deepseek-v4-pro` | DeepSeek V4 Pro | Low | Solid balance, standard implementation | Fallback implementer |
| `opencode-go/deepseek-v4-flash` | DeepSeek V4 Flash | Very Low | Speed, scripts, tool calling | Quick edits, scripts |

---

## Model Mapping to Agents

| Agent | Model ID | Tier | Cost |
|---|---|---|---|
| `gentleman-vMK` | (default) | — | Default |
| `gentleman-security` | `opencode-go/qwen3.7-max` | Pro | High |
| `gentleman-seo` | `opencode-go/qwen3.7-plus` | Pro | Medium |
| `gentleman-infra` | `opencode-go/glm-5.2` | Pro | High |
| `gentleman-frontend` | `opencode-go/kimi-k2.6` | Pro | Medium |
| `gentleman-performance` | `opencode-go/qwen3.7-max` | Pro | High |
| `gentleman-datascience` | `opencode-go/glm-5.1` | Pro | Medium |
| `gentleman-docs` | `opencode-go/mimo-v2.5-pro` | Pro | Low |
| `gentleman-implementer` | `opencode-go/mimo-v2.5-pro` | Pro | Low |
| `gentleman-quick` | `opencode/mimo-v2.5-free` | Free | Very Low |
| `gentleman-codex` | `opencode/deepseek-v4-flash-free` | Free | Very Low |
| `gentleman-deep` | `opencode/nemotron-3-ultra-free` | Free | High (trial) |

---

## Fallback Options

If a primary model is unavailable:

| Primary | Fallback 1 | Fallback 2 |
|---|---|---|
| `opencode-go/qwen3.7-max` | `opencode/nemotron-3-ultra-free` | `gentleman-vMK` (direct) |
| `opencode-go/qwen3.7-plus` | `opencode-go/qwen3.6-plus` | `gentleman-vMK` (direct) |
| `opencode-go/glm-5.2` | `opencode/nemotron-3-ultra-free` | `gentleman-vMK` (direct) |
| `opencode-go/glm-5.1` | `opencode-go/deepseek-v4-pro` | `gentleman-codex` |
| `opencode-go/kimi-k2.6` | `opencode-go/kimi-k2.7-code` | `gentleman-quick` |
| `opencode-go/mimo-v2.5-pro` | `opencode-go/deepseek-v4-pro` | `gentleman-vMK` (direct) |
| `opencode/mimo-v2.5-free` | `opencode/deepseek-v4-flash-free` | `gentleman-vMK` (direct) |
| `opencode/deepseek-v4-flash-free` | `opencode/mimo-v2.5-free` | `gentleman-vMK` (direct) |

---

## Models NOT in Guide (but available)

These models are available but not in the original guide:

| Model | Notes |
|---|---|
| `opencode/north-mini-code-free` | Trial, code tasks — not evaluated yet |
| `opencode-go/qwen3.6-plus` | Can be used as fallback for Qwen3.7 Plus |
| `opencode-go/kimi-k2.7-code` | Alternative to K2.6 for code tasks |
| `opencode-go/minimax-m3` | General purpose, not evaluated yet |

---

## Trial vs Production

### Trial Models (may disappear)
- `opencode/deepseek-v4-flash-free`
- `opencode/mimo-v2.5-free`
- `opencode/nemotron-3-ultra-free`
- `opencode/north-mini-code-free`

**Risk**: These models may be removed by OpenCode at any time.
**Mitigation**: Always have fallback chains. Use for non-critical tasks only.

### Production Models (stable)
- `opencode/big-pickle`
- All `opencode-go/*` models

**Risk**: Low. These are paid/stable models.
**Mitigation**: Use for critical tasks. Monitor quota.

---

## How to Verify Availability

```bash
# List all available models
opencode models

# List models for a specific provider
opencode models opencode-go
opencode models opencode
```

---

## Cost Tracking

To track model usage and costs:

```bash
# Show token usage and cost statistics
opencode stats

# Export session data
opencode export [sessionID]
```

For manual tracking, use `docs/mejoras/cost-log.md`.

---

## Last Updated

- **Date**: 2026-07-05
- **Verified by**: gentleman-vMK
- **Method**: `opencode models` command output
- **Next verification**: 2026-08-05 (or when models change)
